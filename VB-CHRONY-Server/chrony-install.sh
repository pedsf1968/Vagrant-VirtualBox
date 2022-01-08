################################################################################
# FILE NAME   : chrony-install.sh
# FILE TYPE   : BASH
# VERSION     : 220102
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
VM_IP="10.1.33.10"
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
show_parameters(){
   echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix} - Parameters"
   echo "VERBOSE : ${verbose}"
   echo "Log directory : ${logDirectory}"
   echo "Log file : ${logFile}"
   echo "Network range : ${networkIpRange}"
   echo "Network time zone : ${networkTimezone}"
}

chrony_install(){
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix} - Install"; fi 
   sudo apt install -y chrony >> ${logDirectory}/${logFile}
}

chrony_configure(){
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix} - Configuration setting"; fi 
   sudo bash -c "echo 'allow '$networkIpRange >> /etc/chrony/chrony.conf"
   sudo timedatectl set-timezone ${networkTimezone}
}

chrony_service_start() {
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix} - Services restart"; fi 
   sudo systemctl daemon-reload >> ${logDirectory}/${logFile}
   sudo timedatectl set-ntp false >> ${logDirectory}/${logFile}
   sudo systemctl enable chrony >> ${logDirectory}/${logFile} 
   sudo systemctl start chrony >> ${logDirectory}/${logFile} 
}

########################################################################### MAIN
main() {
   mkdir -p ${logDirectory}
   touch ${logDirectory}/${logFile}
   
   show_parameters >> ${logDirectory}/${logFile} 
   if [[ -n $verbose ]]; then
      show_parameters
   fi
   
   chrony_install
   chrony_configure
   chrony_service_start
}

main