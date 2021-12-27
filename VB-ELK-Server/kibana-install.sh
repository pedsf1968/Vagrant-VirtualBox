################################################################################
# FILE NAME   : elk-install.sh
# FILE TYPE   : BASH
# VERSION     : 211223
# ARGS        
# --verbose                : Verbose installation
# --hostname VM_HOSTNAME   : Specify a hostname for the VM
# --ip VM_IP               : Specify an IP for the VM
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@gmail.com
#
# DESCRIPTION : ELK server installation
################################################################################

###################################################################### CONSTANTS
MESSAGE_PREFIX="ELK"
LOG_DIRECTORY=/home/vagrant/logs
LOG_FILE=$LOG_DIRECTORY/elk.log
VM_HOSTNAME="ELK-server"
VM_IP="10.1.33.11"

ELASTICSEARCH_KEY="https://artifacts.elastic.co/GPG-KEY-elasticsearch"
ELASTICSEARCH_SRC="https://artifacts.elastic.co/packages/7.x/apt stable main"
ELASTICSEARCH_PKG="elasticsearch-7.16.2-amd64.deb"
ELASTICSEARCH_PKG_HASH="${ELASTICSEARCH_PKG}.sha512"
ELASTICSEARCH_PKG_URL="https://artifacts.elastic.co/downloads/elasticsearch"

###################################################################### VARIABLES
verbose=''
vmHostname=$VM_HOSTNAME
vmIP=$VM_IP
elastickey=$ELASTICSEARCH_KEY
elasticsrc=$ELASTICSEARCH_SRC
elasticpkg=$ELASTICSEARCH_PKG
elastihash=$ELASTICSEARCH_PKG_HASH
elasticurl=$ELASTICSEARCH_PKG_URL

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
   --elastickey)
      shift
      elastickey=$1;;
   --elasticsrc)
      shift
      elasticsrc=$1;;
   --elasticpkg)
      shift
      elasticpkg=$1
      elastichash=$1".sha";;
   --elasticurl)
      shift
      elasticurl=$1;;
   esac
   shift
done


###################################################################### FUNCTIONS
linux_update(){   
   if [[ -n $verbose ]]; then echo "${MESSAGE_PREFIX} - Update"; fi
   sudo apt-get update >> ${LOG_FILE}
   sudo apt-get upgrade -y >> ${LOG_FILE}
}

common_install(){
   if [[ -n $verbose ]]; then echo "${MESSAGE_PREFIX} - Common install"; fi
   sudo apt-get install -y -qq net-tools telnet sshpass nfs-common >> ${LOG_FILE}
   sudo apt-get install -y -qq vim tree python3-pip >> ${LOG_FILE}
   sudo loadkeys fr
}

ssh_setting(){
   if [[ -n $verbose ]]; then echo "${MESSAGE_PREFIX} - SSH setting"; fi 
   sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
   sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
}

elasticsearch_prepare(){
   if [[ -n $verbose ]]; then echo "${MESSAGE_PREFIX} - Prepare"; fi 
   wget -qO - ${elastickey} | sudo apt-key add -
   echo "deb ${elasticurl}/${elasticsrc}" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
   sudo apt-get install elasticsearch
   wget ${elasticurl}/${elasticpkg}
   wget ${elasticurl}/${elastichash}
   shasum -a 512 -c ${elastihash} 
   sudo dpkg -i ${elasticpkg}
}

elasticsearch_install(){
   if [[ -n $verbose ]]; then echo "${MESSAGE_PREFIX} - Install"; fi 
   sudo dpkg -i ${ELASTICSEARCH_PKG}
}

common_configure(){
   if [[ -n $verbose ]]; then echo "${MESSAGE_PREFIX} - Configuration setting"; fi 
   # set right name and IP in /etc/hosts file
   sudo sed -i /${vmHostname}/d /etc/hosts
   sudo sed -i s/^ubuntu*/${vmHostname}/g /etc/hosts
   sudo bash -c "echo ${vmIP}\t${vmHostname}\t${vmHostname} >> /etc/hosts"
}

services_restart() {
   if [[ -n $verbose ]]; then echo "${MESSAGE_PREFIX} - Services restart"; fi 
   sudo systemctl daemon-reload >> ${LOG_FILE}
   sudo systemctl restart sshd >> ${LOG_FILE}
  
   sudo systemctl enable elasticsearch.service >> ${LOG_FILE} 
   sudo systemctl start elasticsearch.service >> ${LOG_FILE} 
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
   fi

   mkdir -p ${logDirectory}
   touch ${logDirectory}/${logFile}
   
   linux_update
   common_install
   ssh_setting
   # elasticsearch_prepare
   # elasticsearch_install
   # common_configure
   services_restart
}

main