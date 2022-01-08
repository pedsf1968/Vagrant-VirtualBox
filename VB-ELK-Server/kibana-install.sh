################################################################################
# FILE NAME   : kibana-install.sh
# FILE TYPE   : BASH
# VERSION     : 220102
# ARGS        
# --verbose                              : Verbose installation
# --logprefix LOG_PREFIX                 : Specify prefix of log message (ELK)
# --logfolder LOG_FOLDER                 : Specify the directory of installation log file (/home/vagrant/logs)
# --logfile LOG_FILE                     : Specify the installation log file name (kibana.log)
#
# --ip KIBANA_IP                         : Specify the IP for Elasticsearch (127.0.0.1)
# --port KIBANA_PORT                     : Specify the port for Elasticsearch (5601)
# --key KIBANA_KEY                       : Elasticsearch GPG repository key
# --src KIBANA_SRC                       : Elasticsearch repository url
# --elasticsearchip ELASTICSEARCH_IP     : Specify the IP for Elasticsearch (127.0.0.1)
# --elasticsearchport ELASTICSEARCH_PORT : Specify the port for Elasticsearch (9200)

#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@gmail.com
#
# DESCRIPTION : ELK server installation
################################################################################

###################################################################### CONSTANTS
LOG_PREFIX="ELK"
LOG_FOLDER=/home/vagrant/logs
LOG_FILE=kibana.log

ELASTICSEARCH_IP="127.0.0.1"
ELASTICSEARCH_PORT=9200
ELASTICSEARCH_USERNAME="kibana"
ELASTICSEARCH_PASSWORD="kibana"
ELASTICSEARCH_FOLDER="/etc/elasticsearch"
ELASTICSEARCH_CERTS=$ELASTICSEARCH_FOLDER/certs
ELASTICSEARCH_BIN="/usr/share/elasticsearch/bin"

KIBANA_IP="127.0.0.1"
KIBANA_PORT=5601
KIBANA_KEY="https://artifacts.elastic.co/GPG-KEY-elasticsearch"
KIBANA_SRC="https://artifacts.elastic.co/packages/7.x/apt"
KIBANA_FOLDER="/etc/kibana"
KIBANA_CERTS=$KIBANA_FOLDER/certs
KIBANA_BIN="/usr/share/kibana/bin"
KIBANA_USER=kibana_system

###################################################################### VARIABLES
verbose=''
logPrefix=$LOG_PREFIX
logFolder=$LOG_FOLDER
logFile=$LOG_FILE

elasticsearchIP=$ELASTICSEARCH_IP
elasticsearchPort=$ELASTICSEARCH_PORT

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
   --logfolder)
      shift
      logFolder=$1;;
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
   --elasticsearchip)
      shift
      elasticsearchIP=$1;;
   --elasticsearchport)
      shift
      elasticsearchPort=$1;;
   esac
   shift
done


###################################################################### FUNCTIONS
show_parameters(){
   echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - Parameters"
   echo "VERBOSE : ${verbose}"
   echo "Log folder : ${logFolder}"
   echo "Log file : ${logFile}"
   echo "Kibana IP : ${kibanaIP}"
   echo "Kibana port : ${kibanaPort}"
   echo "Kibana key : ${kibanaKey}"
   echo "Kibana package sources : ${kibanaSrc}"
   echo "Elasticsearch IP : ${elasticsearchIP}"
   echo "Elasticsearch port : ${elasticsearchPort}"
}

kibana_prepare(){
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - Prepare"; fi
   wget -qO - ${kibanaKey} | sudo apt-key add -
   echo "deb ${kibanaSrc} stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
   sudo apt-get update >> ${logFolder}/${logFile}   
}

kibana_install(){
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - Install"; fi 
   sudo apt-get install kibana >> ${logFolder}/${logFile}
}

kibana_configure(){
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - Configure"; fi 
   sudo echo "
server.host: "${kibanaIP}"
server.port: "${kibanaPort}"
elasticsearch.hosts: ["https://${elasticsearchIP}:${elasticsearchPort}"]
i18n.locale: "fr"

server.ssl.enabled: true
server.ssl.certificate: /etc/kibana/certs/kibana-client.crt.pem
server.ssl.key: /etc/kibana/certs/kibana-client.key.pem
elasticsearch.ssl.verificationMode: none
" >> /etc/kibana/kibana.yml   
}

kibana_configure_certs() {
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - HTTP TLS/SSL configuration"; fi

   sudo mkdir -p $KIBANA_CERTS
   sudo openssl pkcs12 -in $ELASTICSEARCH_CERTS/elastic-certificates.p12 -clcerts -nokeys -password pass:"" -out $KIBANA_CERTS/kibana-client.crt.pem
   sudo openssl pkcs12 -in $ELASTICSEARCH_CERTS/elastic-certificates.p12 -nocerts -nodes -password pass:"" -out $KIBANA_CERTS/kibana-client.key.pem

   sudo chmod 660 $KIBANA_CERTS/*
   sudo chown :kibana $KIBANA_CERTS/*
}

kibana_configure_user() {
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - User configuration"; fi
   kibanaUser=$KIBANA_USER
   kibanaPassword=$(cat /home/vagrant/logs/elasticsearch.log | grep "PASSWORD ${kibanaUser}" | cut -d' ' -f4)
   sudo cd ${KIBANA_FOLDER}
   sudo ${KIBANA_BIN}/kibana-keystore create
   sudo echo ${kibanaUser} | ${KIBANA_BIN}/kibana-keystore add --stdin elasticsearch.username
   sudo echo ${kibanaPassword} | ${KIBANA_BIN}/kibana-keystore add --stdin  elasticsearch.password
}

kibana_service_start() {
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - Services restart"; fi 
   sudo systemctl daemon-reload >> ${logFolder}/${logFile}
   sudo systemctl enable kibana.service >> ${logFolder}/${logFile} 
   sudo systemctl start kibana.service >> ${logFolder}/${logFile} 
}

########################################################################### MAIN
main() {
   mkdir -p ${logFolder}
   touch ${logFolder}/${logFile}
   
   show_parameters >> ${logFolder}/${logFile} 
   if [[ -n $verbose ]]; then
      show_parameters
   fi
      
   kibana_prepare
   kibana_install
   kibana_configure
   kibana_configure_certs
   kibana_configure_user
   kibana_service_start
}

main