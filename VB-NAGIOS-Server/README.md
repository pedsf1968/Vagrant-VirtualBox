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