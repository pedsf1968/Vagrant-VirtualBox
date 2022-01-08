################################################################################
# FILE NAME   : common-install.sh
# FILE TYPE   : BASH
# VERSION     : 211224
# ARGS        
# --verbose                : Verbose installation
# --logprefix LOG_PREFIX   : Specify prefix of log message
# --logfolder LOG_FOLDER   : Specify the directory of installation log file
# --logfile LOG_FILE       : Specify the installation log file name
#
# --ntpip NTP_IP           : Specify the NTP server IP
# --timezone TIME_ZONE     : Specify the time zone
#
# --hostname VM_HOSTNAME   : Specify a hostname for the VM
# --ip VM_IP               : Specify an IP for the VM
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@gmail.com
#
# DESCRIPTION : Common installation
################################################################################

###################################################################### CONSTANTS
LOG_PREFIX="Common"
LOG_FOLDER=/home/vagrant/logs
LOG_FILE=common.log

VM_HOSTNAME="Server"
VM_IP="127.0.0.1"

NTP_IP="10.1.33.10"
NETWORK_TIMEZONE="Europe/Paris"

###################################################################### VARIABLES
verbose=''
logPrefix=$LOG_PREFIX
logFolder=$LOG_FOLDER
logFile=$LOG_FILE

ntpIP=$NTP_IP
networkTimezone=$NETWORK_TIMEZONE

vmHostname=$VM_HOSTNAME
vmIP=$VM_IP


while [[ $# > 0 ]]; do
   case $1 in
   --verbose)
      verbose="True";;
   --logprefix)
      shift
      logPrefix=$1;;
   --logfolder)
      shift
      logFolder=$1;;
   --logfile)
      shift
      logFile=$1;;
   --ntpip)
      shift
      ntpIP=$1;;
   --timezone)
      shift
      networkTimezone=$1;;
   --hostname)
      shift
      vmHostname=$1;;
   --ip)
      shift
      vmIP=$1;;
   esac
   shift
done


###################################################################### FUNCTIONS
show_parameters(){
   echo "${logPrefix} - Parameters"
   echo "VERBOSE : ${verbose}"
   echo "Log folder : ${logFolder}"
   echo "Log file : ${logFile}"
   echo "NTP IP : ${ntpIP}"
   echo "Network time zone : ${networkTimezone}"
   echo "Hostname : ${vmHostname}"
   echo "IP : ${vmIP}"
}

linux_update(){   
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix} - Update"; fi
   sudo apt-get update >> ${logFolder}/${logFile}
   sudo apt-get upgrade -y >> ${logFolder}/${logFile}
}

common_install(){
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix} - Common install"; fi
   sudo apt-get install -y -qq net-tools telnet sshpass nfs-common >> ${logFolder}/${logFile}
   sudo apt-get install -y -qq vim tree python3-pip >> ${logFolder}/${logFile}
   sudo loadkeys fr
}

ssh_setting(){
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix} - SSH setting"; fi 
   sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
   sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
}

ntp_setting(){
   if [[ -n "${verbose}" ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix} - NTP setting"; fi
   sed -i "s/#FallbackNTP=ntp.ubuntu.com/FallbackNTP=${ntpIP}/g" /etc/systemd/timesyncd.conf
   sudo timedatectl set-timezone ${networkTimezone}
   sudo timedatectl set-ntp true
}

common_configure(){
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix} - Configuration setting"; fi 
   # set right name and IP in /etc/hosts file
   sudo sed -i /${vmHostname}/d /etc/hosts
   sudo sed -i s/^ubuntu*/${vmHostname}/g /etc/hosts
   sudo echo -e "${vmIP}\t${vmHostname}\t${vmHostname}" >> /etc/hosts
}

services_restart() {
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix} - Services restart"; fi 
   sudo systemctl daemon-reload >> ${logFolder}/${logFile}
   sudo systemctl restart sshd >> ${logFolder}/${logFile}
   sudo systemctl restart systemd-timesyncd >> ${logFolder}/${logFile}
}

########################################################################### MAIN
main() {
   mkdir -p ${logFolder}
   touch ${logFolder}/${logFile}
   
   show_parameters >> ${logFolder}/${logFile} 
   if [[ -n $verbose ]]; then
      show_parameters
   fi
   
   
   linux_update
   common_install
   ssh_setting
   if [[ -n "${ntpIP}" ]]; then ntp_setting; fi
   common_configure
   services_restart
}

main