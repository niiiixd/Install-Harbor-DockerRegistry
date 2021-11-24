# Install Harbor Docker Registry
Harbor is an open source container image registry that secures images with role-based access control, scans images for vulnerabilities, and signs images as trusted. As a CNCF Incubating project, Harbor delivers compliance, performance, and interoperability to help you consistently and securely manage images across cloud native compute platforms like Kubernetes and Docker. 
The key features of Harbor include:

    Security and vulnerability analysis
    Content signing and validation
    Extensible API and web UI
    Image replication
    Role-based access control
    Multitenant
    
## What You’ll Need

Here’s what you’ll need for a successful Harbor installation:

    A running instance of CentOS Server 7.
    A user account with sudo privileges.
    
### Docker and Docker Compose

Before we actually install Harbor, there are a number of dependencies to take care of. Let’s get everything ready.

The first tool to install is Docker itself. Open a terminal window and issue the command:

Installing Docker on CentOS base on [Docker.com](https://docs.docker.com/install/linux/docker-ce/centos/)

#### Uninstall old versions of Docker
```
  sudo yum remove docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-engine
```
#### Install Docker Engine - Community using the repository

You can install Docker Engine - Community in different ways, depending on your needs:
```
sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

```
Use the following command to set up the stable repository.
```
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```
Install the latest version of Docker Engine - Community and containerd
```
sudo yum install docker-ce docker-ce-cli containerd.io
```
Add your user to the docker group with the command
```
sudo usermod -aG docker $USER
```
Start and Enable Docker 
```
sudo systemctl start docker
sudo systemctl enable docker
```


Once Docker is installed, you need to add your user to the docker group with the command:

```
sudo usermod -aG docker $USER
```

Next, we need to install the docker-compose command. As this cannot be installed via the standard repositories, it is taken care of with the following commands:
On Linux, you can download the Docker Compose binary from the Compose repository release page on [GitHub](https://github.com/docker/compose/releases).

Run this command to download the current stable release of Docker Compose:
```
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```
Apply executable permissions to the binary:

```
sudo chmod +x /usr/local/bin/docker-compose
```
If the command docker-compose fails after installation, check your path. You can also create a symbolic link to /usr/bin or any other directory in your path.
```
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```
### NGINX

The next dependency to install is NGINX.
```
sudo yum install -y epel-release
sudo yum update -y
sudo install -y nginx 
```
Start and enable NGINX with the commands:
```
sudo systemctl start nginx
sudo systemctl enable nginx
```
### Download and Install Harbor
NOTE: Make sure to visit the [Harbor release page](https://github.com/goharbor/harbor/releases) to check for the latest version.
 
```
cd $HOME 
wget https://github.com/goharbor/harbor/releases/download/v1.10.1/harbor-online-installer-v1.10.1.tgz
```
Unpack the downloaded Harbor file with the command:
```
tar xvzf harbor-online-installer-v1.10.1.tgz
```
The above command will create a new directory, named harbor. Change into that directory with the command:
```
cd harbor
```
### Creating SSL Keys with Let's Encrypt
Harbor cannot function properly without SSL. Because of this, you need to add SSL keys.
Run this command to install certbot
```
sudo yum install certbot python2-certbot-nginx
```
Export a variable for domain:
```
export domain=domain.com
```
Generate the certificates with the command:
```
certbot certonly --cert-name $domain -d $domain --standalone --agree-tos --register-unsafely-without-email
```
Rename SSL certificates with following command:
```
cp /etc/letsencrypt/live/$domain/privkey.pem /etc/letsencrypt/live/$domain/$domain.key
cat /etc/letsencrypt/live/$domain/cert.pem /etc/letsencrypt/live/$domain/chain.pem > /etc/letsencrypt/live/$domain/$domain.crt
```
With the key generation complete, we need to copy the newly-generated certificates into the proper directory. First, create the directory with the command:
```
sudo mkdir -p /etc/docker/certs.d/$domain
```
Now copy the keys with the command:
```
sudo cp /etc/letsencrypt/live/$domain/*.crt /etc/letsencrypt/live/$domain/*.key /etc/docker/certs.d/$domain
```

### Configuring the Harbor Installer
Before running the installation command, a few edits must be made to the harbor.yml file. Open that file for editing with the command:
```
vim harbor.yml
```
The following options must be edited:

    hostname — set this to either the domain of your hosting server.
    harbor_admin_password — set this to a strong, unique password.
    password (in the database configuration section) — change this to a strong, unique password.

Because we are using SSL, it is also necessary to uncomment (remove the leading # characters) the following lines:
    https:
    port: 443
    certificate: /etc/ssl/certs/ca.crt
    private_key: /etc/ssl/certs/ca.key
    
Make sure to edit the paths of the keys to reflect:

```
    certificate: /etc/docker/certs.d/$domain/$domain.crt
    private_key: /etc/docker/certs.d/$domain/$domain.key
```
Save and close that file.

### Installing Harbor
It’s time to install Harbor. We’ll be installing the service with Clair support (for the scanning of vulnerabilities). To do this, issue the command:

```
cd $HOME/harbor
sudo ./install.sh --with-clair
```
The installation takes a bit of time, so be patient until the harbor services are started and you are returned your bash prompt.

The installation should complete without errors. When it does, open a browser and point it to https://domain.com/harbor (Where domain of your Harbor server). You will be prompted for the admin user credentials (username is admin and password is the password you set in the harbor.yml file).

## Authors

* **Sadegh Khademi** - *SRE/Cloud Engineer* - Sadegh Khademi [website](https://sadeghkhademi.com) - Twitter [@niiiixd](https://twitter.com/niiiixd) - Email Address [Email](mailto:khademi.sadegh@gmail.com?subject=[GitHub]%20Install%20Harbor%20DockerRegistry)

## License

This project is licensed under the GPL-v3 License - see the [LICENSE](LICENSE) file for details
