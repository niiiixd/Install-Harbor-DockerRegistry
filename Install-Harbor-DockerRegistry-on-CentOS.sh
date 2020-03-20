#!/bin/bash

######### Installing Docker on CentOS base on (https://docs.docker.com/install/linux/docker-ce/centos/) #########

# Uninstall old versions of Docker
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

# Install required packages
sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

# Use the following command to set up the stable repository
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# Install the latest version of Docker Engine - Community and containerd:
sudo yum install docker-ce docker-ce-cli containerd.io

# Add your user to the docker group with the command:
sudo usermod -aG docker $USER

# Start and Enable Docker 
sudo systemctl start docker
sudo systemctl enable docker

######### Next, we need to install the docker-compose command #########
######### As this cannot be installed via the standard repositories, it is taken care of with the following commands: #########
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Apply executable permissions to the binary:
sudo chmod +x /usr/local/bin/docker-compose

# Optionally You can also create a symbolic link to /usr/bin
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

######### The next dependency to install is NGINX #########
sudo yum install -y epel-release
sudo yum update -y
sudo install -y nginx 

# Start and enable NGINX with the commands:
sudo systemctl start nginx
sudo systemctl enable nginx

######### Download and Install Harbor #########
### Check harbor Download page
cd $HOME 
wget https://github.com/goharbor/harbor/releases/download/v1.10.1/harbor-online-installer-v1.10.1.tgz

# Unpack the downloaded Harbor file with the command:
tar xvzf harbor-online-installer-v1.10.1.tgz
cd harbor

######### Creating SSL Keys with Let's Encrypt #########

sudo yum install certbot python2-certbot-nginx


# Set Domain 

    clear
    echo "Please enter your domain:"
    read domain
    str=`echo $domain | grep '^\([a-zA-Z0-9_\-]\{1,\}\.\)\{1,\}[a-zA-Z]\{2,5\}'`
    while [ ! -n "${str}" ]
    do
        echo "Invalid domain."
        echo "Please try again:"
        read -p domain
        str=`echo $domain | grep '^\([a-zA-Z0-9_\-]\{1,\}\.\)\{1,\}[a-zA-Z]\{2,5\}'`
    done
    echo "domain = ${domain}"

# Get certification

    clear
    if [ -f /etc/letsencrypt/live/$domain/fullchain.pem ];then
        echo "cert already got, skip."
    else 
        certbot certonly --cert-name $domain -d $domain --standalone --agree-tos --register-unsafely-without-email
        if [ ! -f /etc/letsencrypt/live/$domain/fullchain.pem ];then
            echo "Failed to get cert."
            exit 1
        fi
    fi

# Setup letsencrypt certificates renewing
cron_line="30 2 * * 1 certbot renew >> /var/log/letsencrypt-renew.log"
(crontab -u root -l; echo "$cron_line" ) | crontab -u root -

# Rename SSL certificates
cp /etc/letsencrypt/live/$domain/privkey.pem /etc/letsencrypt/live/$domain/$domain.key
cat /etc/letsencrypt/live/$domain/cert.pem /etc/letsencrypt/live/$domain/chain.pem > /etc/letsencrypt/live/$domain/$domain.crt

sudo mkdir -p /etc/docker/certs.d/$domain

sudo cp /etc/letsencrypt/live/$domain/*.crt /etc/letsencrypt/live/$domain/*.key /etc/docker/certs.d/$domain

# Chnage Config file
sed -i 's/^hostname: reg.mydomain.com$/hostname: $domain/' $HOME/harbor/harbor.yml
sed -i 's/^certificate: /your/certificate/path$/certificate:: /etc/docker/certs.d/$domain/$domain.crt' $HOME/harbor/harbor.yml
sed -i 's/^private_key: /your/private/key/path$/private_key: /etc/docker/certs.d/$domain/$domain.key' $HOME/harbor/harbor.yml

# Installing harbor

cd $HOME/harbor
sudo ./install.sh --with-clair
