################################################################################
# FILE NAME   : common-install.sh
# FILE TYPE   : BASH
# VERSION     : 211224
# ARGS        
# --verbose                      : Verbose installation
# --hostname VM_HOSTNAME         : Specify a hostname for the VM
# --ip VM_IP                     : Specify an IP for the VM
#
# --logprefix LOG_PREFIX         : Specify prefix of log message
# --logdirectory LOG_DIRECTORY   : Specify the directory of installation log file
# --logfile LOG_FILE             : Specify the installation log file name
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@gmail.com
#
# DESCRIPTION : Common installation
################################################################################

###################################################################### CONSTANTS
LOG_PREFIX="ELK"
LOG_DIRECTORY="/home/vagrant/logs"
LOG_FILE="common.log"
VM_HOSTNAME="ELK-server"
VM_IP="10.1.33.11"


###################################################################### VARIABLES
logPrefix=$LOG_PREFIX
logDirectory=$LOG_DIRECTORY
logFile=$LOG_FILE
verbose=''
vmHostname=$VM_HOSTNAME
vmIP=$VM_IP


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
linux_update(){   
   if [[ -n $verbose ]]; then echo "${logPrefix} - Update"; fi
   sudo apt-get update >> ${logDirectory}/${logFile}
   sudo apt-get upgrade -y >> ${logDirectory}/${logFile}
}

common_install(){
   if [[ -n $verbose ]]; then echo "${logPrefix} - Common install"; fi
   sudo apt-get install -y -qq net-tools telnet sshpass nfs-common >> ${logDirectory}/${logFile}
   sudo apt-get install -y -qq vim tree python3-pip >> ${logDirectory}/${logFile}
   sudo loadkeys fr
}

ssh_setting(){
   if [[ -n $verbose ]]; then echo "${logPrefix} - SSH setting"; fi 
   sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
   sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
}

common_configure(){
   if [[ -n $verbose ]]; then echo "${logPrefix} - Configuration setting"; fi 
   # set right name and IP in /etc/hosts file
   sudo sed -i /${vmHostname}/d /etc/hosts
   sudo sed -i s/^ubuntu*/${vmHostname}/g /etc/hosts
   sudo bash -c "echo ${vmIP}\t${vmHostname}\t${vmHostname} >> /etc/hosts"
}

services_restart() {
   if [[ -n $verbose ]]; then echo "${logPrefix} - Services restart"; fi 
   sudo systemctl daemon-reload >> ${logDirectory}/${logFile}
   sudo systemctl restart sshd >> ${logDirectory}/${logFile}
}

########################################################################### MAIN
main() {
   if [[ -n $verbose ]]; then
      echo "${logPrefix} - Parameters"
      echo "VERBOSE : ${verbose}"
      echo "Log directory : ${logDirectory}"
      echo "Log file : ${logFile}"
      echo "Hostname : ${vmHostname}"
      echo "IP : ${vmIP}"
   fi

   mkdir -p ${logDirectory}
   touch ${logDirectory}/${logFile}
   
   linux_update
   common_install
   ssh_setting
   common_configure
   services_restart
}

main