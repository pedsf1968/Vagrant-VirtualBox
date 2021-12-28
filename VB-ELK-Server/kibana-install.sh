################################################################################
# FILE NAME   : kibana-install.sh
# FILE TYPE   : BASH
# VERSION     : 211227
# ARGS        
# --verbose                      : Verbose installation
# --logprefix LOG_PREFIX         : Specify prefix of log message
# --logdirectory LOG_DIRECTORY   : Specify the directory of installation log file
# --logfile LOG_FILE             : Specify the installation log file name
#
# --ip KIBANA_IP                 : Specify the IP for Elasticsearch (127.0.0.1)
# --port KIBANA_PORT             : Specify the port for Elasticsearch (9200)
# --key KIBANA_KEY               : Elasticsearch GPG repository key
# --src KIBANA_SRC               : Elasticsearch repository url
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@gmail.com
#
# DESCRIPTION : ELK server installation
################################################################################

###################################################################### CONSTANTS
MESSAGE_PREFIX="ELK"
LOG_DIRECTORY=/home/vagrant/logs
LOG_FILE=kibana.log

ELASTICSEARCH_USERNAME="kibana"
ELASTICSEARCH_PASSWORD="kibana"

KIBANA_IP="127.0.0.1"
KIBANA_PORT=5601
KIBANA_KEY="https://artifacts.elastic.co/GPG-KEY-elasticsearch"
KIBANA_SRC="https://artifacts.elastic.co/packages/7.x/apt"

###################################################################### VARIABLES
verbose=''
logPrefix=$LOG_PREFIX
logDirectory=$LOG_DIRECTORY
logFile=$LOG_FILE

kibanaIP=$KIBANA_IP
kibanaPort=$KIBANA_PORT
kibanaKey=$KIBANA_KEY
kibanaSrc=$KIBANA_SRC

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
   --ip)
      shift
      kibanaIP=$1;;
   --port)
      shift
      kibanaPort=$1;;
   --key)
      shift
      kibanaKey=$1;;
   --src)
      shift
      kibanaSrc=$1;;
   esac
   shift
done


###################################################################### FUNCTIONS
show_parameters(){
   echo "${logPrefix} - Parameters"
   echo "VERBOSE : ${verbose}"
   echo "Log directory : ${logDirectory}"
   echo "Log file : ${logFile}"
   echo "Kibana IP : ${kibanaIP}"
   echo "Kibana port : ${kibanaPort}"
   echo "Kibana key : ${kibanaKey}"
   echo "Kibana package sources : ${kibanaSrc}"
}

kibana_prepare(){
   if [[ -n $verbose ]]; then echo "${logPrefix} - Prepare"; fi 
   wget -qO - ${kibanaKey} | sudo apt-key add -
   echo "deb ${kibanaSrc} stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
   sudo apt-get update >> ${logDirectory}/${logFile}   
}

kibana_install(){
   if [[ -n $verbose ]]; then echo "${logPrefix} - Install"; fi 
   sudo apt-get install kibana >> ${logDirectory}/${logFile}
}

kibana_configure(){
   if [[ -n $verbose ]]; then echo "${logPrefix} - Configure"; fi 
   sudo echo "
server.host: \"${kibanaIP}\"
server.port: ${kibanaPort}
elasticsearch.hosts: [\"http://${kibanaIP}:9200\"]
elasticsearch.username: \"${ELASTICSEARCH_USERNAME}\"
elasticsearch.password: \"${ELASTICSEARCH_PASSWORD}\"
   " >> /etc/kibana/kibana.yml   
}

kibana_service_start() {
   if [[ -n $verbose ]]; then echo "${logPrefix} - Services restart"; fi 
   sudo systemctl daemon-reload >> ${logDirectory}/${logFile}
   sudo systemctl enable kibana.service >> ${logDirectory}/${logFile} 
   sudo systemctl start kibana.service >> ${logDirectory}/${logFile} 
}

########################################################################### MAIN
main() {
   show_parameters >> ${logDirectory}/${logFile} 
   if [[ -n $verbose ]]; then
      show_parameters
   fi
   
   mkdir -p ${logDirectory}
   touch ${logDirectory}/${logFile}
   
   kibana_prepare
   kibana_install
   kibana_configure
   kibana_service_start
}

main