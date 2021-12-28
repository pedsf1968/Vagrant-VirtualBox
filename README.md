# vagrant
Sample of Vagrantfile repository. Folder's names are prefixed depend on environment :
- VB : for Virtual Box
- HV : for Hyper-V

# VB - VirtualBox VM provider
## VB-Debian9.12.0
Vagrantfile for Debian 9.12.0 VM

## VB-kmaster
Vagrantfile for Kubernetes Master on Debian stretch

## VB-kworker
Vagrantfile for Kubernetes Worker on Debian stretch

## VB-kubernetes
Vagrantfile for Kubernetes Master and Worker on ubuntu/focal64 with :
- HaProxy 1
- Masters 2 nodes
- Workers 2 nodes
- Deploy VM with kubespray and wordpress

## VB-CHRONY-Server
Vagrantfile for configuring NTP server on Ubuntu with Chrony. Launch bash chrony-install.sh with 
network IP range and verbose.

### Parameters
- --help, -h               : Show Vagrantfile options
- --verbose, -v            : Verbose installation
- --name=VM_NAME           : Specify a name for the VM
- --hostname=VM_HOSTNAME   : Specify a hostname for the VM
- --ip=VM_IP               : Specify an IP for the VM
- --cpus=VM_CPUS           : Specify the VM core number
- --memory=VM_MEMORY       : Specify the VM memory amount in ko
- --range=NETWORK_IP_RANGE : Specify the NTP server network range
- --timezone TIME_ZONE     : Specify the time zone

### Examples
vagrant --verbose --ip="192.168.0.10" --range="192.168.0.0/24" up

### Default configuration is:
- VM_NAME = "Vagrant-Chrony-server"
- VM_HOSTNAME = "NTP-server"
- VM_IP = "10.1.33.11"
- VM_CPUS = "1"
- VM_MEMORY = "1024"
- VM_GUI = false
- NETWORK_IP_RANGE = "10.1.33.0/24"
- NETWORK_TIMEZONE = "Europe/Paris"

### Depend on
- chrony-install.sh

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

## VB-LDAP-Server
Vagrantfile for configuring Open LDAP server on Ubuntu with default options.
You can add parameters to vagrant up to change default options.

### Parameters
- --help, -h                       : Show Vagrantfile options
- --verbose, -v                    : Verbose installation
- --managmentIP=MANAGMENT_IP       : Specify the managment IP
- --ntpIP=NTP_IP                   : Specify the NTP server IP
- --timezone=TIME_ZONE             : Specify the time zone
- --name=VM_NAME                   : Specify a name for the VM
- --ip=VM_IP                       : Specify an IP for the VM
- --cpus=VM_CPUS                   : Specify the VM core number
- --memory=VM_MEMORY               : Specify the VM memory amount in ko
- --domain=LDAP_DOMAIN             : Specify the domain company
- --organization=LDAP_ORGANIZATION : Specify the organisation company
- --adminPwd=ADMIN_PWD             : Set LDAP admin password

### Examples
vagrant --verbose up
vagrant --managmentIP="192.168.0.24" --ntpIP="192.168.0.21" up

### Default configuration is:
- MANAGMENT_IP = ".*"
- NTP_IP = "10.1.33.11"
- VM_NAME = 'Vagrant-Ldap-server'
- VM_HOSTNAME = "LDAP-server"
- VM_IP = "10.1.33.12"
- VM_CPUS = "1"
- VM_MEMORY = "1024"
- VM_GUI = false
- LDAP_DOMAIN = "mycompany.com"
- LDAP_ORGANIZATION = "mycompany"
- LDAP_ADMIN_PWD = "ldapAdmin"

### Depend on
- ldap-install.sh

## VB-NAGIOS-Server
Vagrantfile for configuring Nagios server on Ubuntu with default options.
You can add parameters to vagrant up to change default options.

User nagios has several aliases in Linux session.
- nTestCfg : Test nagios configuration
- nRestart : Restart Nagios after configuration changes
- nStatus : Display Nagios service status

### Parameters
- --help, -h                    : Show Vagrantfile options
- --verbose, -v                 : Verbose installation
- --managementIP=MANAGEMNT_IP   : Specify the managment IP
- --ntpIP=NTP_IP                : Specify the NTP server IP
- --timezone=TIME_ZONE          : Specify the time zone
- --name=VM_NAME                : Specify a name for the VM
- --hostname=VM_HOSTNAME        : Specify a hostname for the VM
- --ip=VM_IP                    : Specify an IP for the VM
- --cpus=VM_CPUS                : Specify the VM core number
- --memory=VM_MEMORY            : Specify the VM memory amount in ko
- --archive=ARCHIVE_URL         : Specify the Nagios URL link archive
- --plugins=PLUGINS_ARCHIVE_URL : Specify the Nagios plugins URL link archive
- --directory=NAGIOS_DIRECTORY  : Specify the directory where to install Nagios configuration
- --askPwd                      : Ask for Nagios admin password
- --adminPwd=ADMIN_PWD          : Specify Nagios admin password

### Examples
vagrant --verbose up
vagrant --askPwd --ip="192.168.0.11"

### Default configuration is:
- MANAGMENT_IP = ".*"
- NTP_IP = "10.1.33.11"
- VM_NAME = 'Vagrant-Nagios-server'
- VM_HOSTNAME = "NAGIOS-server"
- VM_IP = "10.1.33.13"
- VM_CPUS = "1"
- VM_MEMORY = "1024"
- VM_GUI = false
- NAGIOS_ARCHIVE_URL="https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.6.tar.gz"
- NAGIOS_PLUGINS_ARCHIVE_URL="https://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz"
- NAGIOS_DIRECTORY="/usr/local/nagios/my_conf"
- NAGIOS_ADMIN_PWD="nagios"

### Depend on
- nagios-install.sh : Installation script for Nagios
- nagios_conf : Directory of Nagios samples
-- command.cfg : Sample of Nagios commands configurations
-- localhost.cfg : Sample of Nagios services for localhost
-- nagios.cfg : Sample of Nagios services for Nagios server