################################################################################
# FILE NAME   : chrony-install.sh
# FILE TYPE   : BASH
# VERSION     : 211227
# ARGS        
# --verbose                      : Verbose installation
# --logprefix LOG_PREFIX         : Specify prefix of log message
# --logdirectory LOG_DIRECTORY   : Specify the directory of installation log file
# --logfile LOG_FILE             : Specify the installation log file name
#
# --timezone TIME_ZONE     : Specify the time zone
# --range NETWORK_IP_RANGE : Network range IP for NTP network
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@gmail.com
#
# DESCRIPTION : NTP CHRONY server installation
################################################################################

###################################################################### CONSTANTS
LOG_PREFIX="CHRONY"
LOG_DIRECTORY=/home/vagrant/logs
LOG_FILE=chrony.log

NETWORK_TIMEZONE="Europe/Paris"
VM_HOSTNAME="NTP-server"
VM_IP="10.1.33.11"
NETWORK_IP_RANGE='10.1.33.00/24'

###################################################################### VARIABLES
verbose=''
logPrefix=$LOG_PREFIX
logDirectory=$LOG_DIRECTORY
logFile=$LOG_FILE

networkTimezone=$NETWORK_TIMEZONE
networkIpRange=$NETWORK_IP_RANGE

while [[ $# > 0 ]]; do
   case $1 in
   --verbose)
      verbose="True";;
   --logprefix)
      shift
      logPrefix=$1;;
   --logdirectory)
      shift
      logDirectory=$1;;
   --logfile)
      shift
      logFile=$1;;
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
chrony-install(){
   if [[ -n $verbose ]]; then echo "${logPrefix} - Install"; fi 
   sudo apt install -y chrony >> ${logDirectory}/${logFile}
}

chrony-configure(){
   if [[ -n $verbose ]]; then echo "${logPrefix} - Configuration setting"; fi 
   sudo bash -c "echo 'allow '$networkIpRange >> /etc/chrony/chrony.conf"
   sudo timedatectl set-timezone ${networkTimezone}
}

services_restart() {
   if [[ -n $verbose ]]; then echo "${logPrefix} - Services restart"; fi 
   sudo systemctl daemon-reload >> ${logDirectory}/${logFile}
   sudo timedatectl set-ntp false >> ${logDirectory}/${logFile}
   sudo systemctl enable chrony >> ${logDirectory}/${logFile} 
   sudo systemctl start chrony >> ${logDirectory}/${logFile} 
}

########################################################################### MAIN
main() {
   if [[ -n $verbose ]]; then
      echo "${logPrefix} - Parameters"
      echo "VERBOSE : ${verbose}"
      echo "Log directory : ${logDirectory}"
      echo "Log file : ${logFile}"
      echo "Network range : ${networkIpRange}"
      echo "Network time zone : ${networkTimezone}"
   fi

   mkdir -p ${logDirectory}
   touch ${logDirectory}/${logFile}
   
   chrony-install
   chrony-configure
   services_restart
}

main