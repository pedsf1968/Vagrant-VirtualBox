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