## VB-TOMCAT-Server
Vagrantfile for configuring Tomcat server on Ubuntu with default options.
You can add parameters to vagrant up to change default options.

### Parameters
- --help, -h                    : Show Vagrantfile options
- --verbose, -v                 : Verbose installation
- --managmentIP=MANAGMENT_IP    : Specify the managment IP
- --ntpIP=NTP_IP                : Specify the NTP server IP
- --name=VM_NAME                : Specify a name for the VM
- --ip=VM_IP                    : Specify an IP for the VM
- --archive=TOMCAT_ARCHIVE_LINK : Specify the tomcat URL link archive
- --directory=TOMCAT_DIRECTORY  : Specify the installation directory of Tomcat
- --askPwd                      : Ask for Tomcat manager and admin password
- --managerPwd=MANAGER_PWD      : Set Tomcat manager password
- --adminPwd=ADMIN_PWD          : Set Tomcat admin password

### Examples
vagrant --verbose up
vagrant --managmentIP="192.168.0.24" --ntpIP="192.168.0.21" --askPwd -v --ip="192.168.0.25" up

### Default configuration is:
- MANAGMENT_IP = ".*"
- NTP_IP = "10.1.33.11"
- VM_NAME = 'Vagrant-Tomcat-server'
- VM_IP = "10.1.33.12"
- VM_MEMORY = "1024"
- VM_CPUS = "1"
- VM_GUI = false
- TOMCAT_ARCHIVE_LINK="https://downloads.apache.org/tomcat/tomcat-9/v9.0.50/bin/apache-tomcat-9.0.50.tar.gz"
- TOMCAT_DIRECTORY="/etc/tomcat"
- TOMCAT_MANAGER_PWD="Manager"
- TOMCAT_ADMIN_PWD="Admin"

### Depend on
- tomcat-install.sh