################################################################################
# FILE NAME   : elasticsearch-install.sh
# FILE TYPE   : BASH
# VERSION     : 211223
# ARGS        
# --verbose                      : Verbose installation
# --logprefix LOG_PREFIX         : Specify prefix of log message
# --logdirectory LOG_DIRECTORY   : Specify the directory of installation log file
# --logfile LOG_FILE             : Specify the installation log file name
#
# --ip ELASTICSEARCH_IP          : Specify the IP for Elasticsearch (127.0.0.1)
# --port ELASTICSEARCH_PORT      : Specify the port for Elasticsearch (9200)
# --key ELASTICSEARCH_KEY        : Elasticsearch GPG repository key
# --src ELASTICSEARCH_SRC        : Elasticsearch repository url
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@gmail.com
#
# DESCRIPTION : Elasticsearch installation
################################################################################

###################################################################### CONSTANTS
MESSAGE_PREFIX="ELK"
LOG_DIRECTORY=/home/vagrant/logs
LOG_FILE=elasticsearch.log

ELASTICSEARCH_IP="127.0.0.1"
ELASTICSEARCH_PORT=9200
ELASTICSEARCH_KEY="https://artifacts.elastic.co/GPG-KEY-elasticsearch"
ELASTICSEARCH_SRC="https://artifacts.elastic.co/packages/7.x/apt"

###################################################################### VARIABLES
verbose=''
logPrefix=$LOG_PREFIX
logDirectory=$LOG_DIRECTORY
logFile=$LOG_FILE

elasticsearchIP=$ELASTICSEARCH_IP
elasticsearchPort=$ELASTICSEARCH_PORT
elasticKey=$ELASTICSEARCH_KEY
elasticSrc=$ELASTICSEARCH_SRC

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
      elasticsearchIP=$1;;
   --port)
      shift
      elasticsearchPort=$1;;
   --key)
      shift
      elasticKey=$1;;
   --src)
      shift
      elasticSrc=$1;;
   esac
   shift
done


###################################################################### FUNCTIONS
show_parameters(){
   echo "${logPrefix} - Parameters"
   echo "VERBOSE : ${verbose}"
   echo "Log directory : ${logDirectory}"
   echo "Log file : ${logFile}"
   echo "Elasticsearch IP : ${elasticsearchIP}"
   echo "Elasticsearch port : ${elasticsearchPort}"
   echo "Elasticsearch key : ${elasticKey}"
   echo "Elasticsearch package sources : ${elasticSrc}"
}

elasticsearch_prepare(){
   if [[ -n $verbose ]]; then echo "${logPrefix} - Prepare"; fi 
   wget -qO - ${elasticKey} | sudo apt-key add -
   echo "deb ${elasticSrc} stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
   sudo apt-get update >> ${logDirectory}/${logFile}   
}

elasticsearch_install(){
   if [[ -n $verbose ]]; then echo "${logPrefix} - Install"; fi 
   sudo apt-get install elasticsearch >> ${logDirectory}/${logFile}
}

elasticsearch_configure(){
   if [[ -n $verbose ]]; then echo "${logPrefix} - Configure"; fi 
   sudo echo "
network.host: ${elasticsearchIP}
http.port: ${elasticsearchPort}
discovery.seed_hosts: [\"${elasticsearchIP}\", \"[::1]\"]
   " >> /etc/elasticsearch/elasticsearch.yml
}

elasticsearch_service_start() {
   if [[ -n $verbose ]]; then echo "${logPrefix} - Services restart"; fi 
   sudo systemctl daemon-reload >> ${logDirectory}/${logFile}
   sudo systemctl enable elasticsearch.service >> ${logDirectory}/${logFile} 
   sudo systemctl start elasticsearch.service >> ${logDirectory}/${logFile} 
}

########################################################################### MAIN
main() {
   show_parameters >> ${logDirectory}/${logFile} 
   if [[ -n $verbose ]]; then
      show_parameters
   fi
   
   mkdir -p ${logDirectory}
   touch ${logDirectory}/${logFile}
      
   elasticsearch_prepare
   elasticsearch_install
   elasticsearch_configure
   elasticsearch_service_start
}

main