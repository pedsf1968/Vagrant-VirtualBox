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