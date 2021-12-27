################################################################################
# FILE NAME   : chrony-install.sh
# FILE TYPE   : BASH
# VERSION     : 210719
# ARGS        
# --verbose                : Verbose installation
# --hostname VM_HOSTNAME   : Specify a hostname for the VM
# --ip VM_IP               : Specify an IP for the VM
# --timezone TIME_ZONE     : Specify the time zone
# --range NETWORK_IP_RANGE : Network range IP for NTP network
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@gmail.com
#
# DESCRIPTION : NTP CHRONY server installation
################################################################################

###################################################################### CONSTANTS
MESSAGE_PREFIX="CHRONY"
LOG_DIRECTORY=/home/vagrant/logs
LOG_FILE=$LOG_DIRECTORY/chrony.log
NETWORK_TIMEZONE="Europe/Paris"
VM_HOSTNAME="NTP-server"
VM_IP="10.1.33.11"
NETWORK_IP_RANGE='10.1.33.00/24'

###################################################################### VARIABLES
verbose=''
networkTimezone=$NETWORK_TIMEZONE
vmHostname=$VM_HOSTNAME
vmIP=$VM_IP
networkIpRange=$NETWORK_IP_RANGE

while [[ $# > 0 ]]; do
   case $1 in
   --verbose)
      verbose="True";;
   --hostname)
      shift
      vmHostname=$1;;
   --ip)
      shift
      vmIP=$1;;
   --timezone)
      shift
      networkTimezone=$1;;
   --range)
      shift
      networkIpRange=$1;;
   esac
   shift
done

###################################################################### FUNCTIONS
linux-update(){   
   if [[ -n $verbose ]]; then echo "${MESSAGE_PREFIX} - Update"; fi
   sudo apt-get update >> ${LOG_FILE}
   sudo apt-get upgrade -y >> ${LOG_FILE}
}

common_install(){
   if [[ -n $verbose ]]; then echo "${MESSAGE_PREFIX} - Common install"; fi
   sudo apt-get install -y -qq vim net-tools telnet python3-pip sshpass nfs-common >> ${LOG_FILE}
}

ssh_setting(){
   if [[ -n $verbose ]]; then echo "${MESSAGE_PREFIX} - SSH setting"; fi 
   sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
   sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
}

chrony-install(){
   if [[ -n $verbose ]]; then echo "${MESSAGE_PREFIX} - Install"; fi 
   sudo apt install -y chrony >> ${LOG_FILE}
}

chrony-configure(){
   if [[ -n $verbose ]]; then echo "${MESSAGE_PREFIX} - Configuration setting"; fi 
   sudo bash -c "echo 'allow '$NETWORK_IP_RANGE >> /etc/chrony/chrony.conf"
   sudo timedatectl set-timezone ${networkTimezone}

   # set right name and IP in /etc/hosts file
   sudo sed -i /${vmHostname}/d /etc/hosts
   sudo sed -i s/^ubuntu*/${vmHostname}/g /etc/hosts
   sudo bash -c "echo ${vmIP}\t${vmHostname}\t${vmHostname} >> /etc/hosts"
}

services_restart() {
   if [[ -n $verbose ]]; then echo "${MESSAGE_PREFIX} - Services restart"; fi 
   sudo systemctl daemon-reload >> ${LOG_FILE}
   sudo systemctl restart sshd >> ${LOG_FILE}
   sudo timedatectl set-ntp false >> ${LOG_FILE}
   sudo systemctl enable chrony >> ${LOG_FILE} 
   sudo systemctl start chrony >> ${LOG_FILE} 
}

########################################################################### MAIN
main() {
   if [[ -n $verbose ]]; then
      echo "${MESSAGE_PREFIX} - Parameters"
      echo "VERBOSE : ${verbose}"
      echo "Log directory : ${LOG_DIRECTORY}"
      echo "Log file : ${LOG_FILE}"
      echo "Hostname : ${vmHostname}"
      echo "IP : ${vmIP}"
      echo "Network range : ${networkIpRange}"
      echo "Network time zone : ${networkTimezone}"
   fi

   mkdir -p $LOG_DIRECTORY
   touch $LOG_FILE
   
   linux-update
   common_install
   ssh_setting
   chrony-install
   chrony-configure
   services_restart
}

main