################################################################################
# FILE NAME   : elasticsearch-install.sh
# FILE TYPE   : BASH
# VERSION     : 211223
# ARGS        
# --verbose                   : Verbose installation
# --logprefix LOG_PREFIX      : Specify prefix of log message (ELK)
# --logfolder LOG_FOLDER      : Specify the directory of installation log file (/home/vagrant/logs)
# --logfile LOG_FILE          : Specify the installation log file name (elasticsearch.log)
#
# --ip ELASTICSEARCH_IP       : Specify the IP for Elasticsearch (127.0.0.1)
# --port ELASTICSEARCH_PORT   : Specify the port for Elasticsearch (9200)
# --key ELASTICSEARCH_KEY     : Elasticsearch GPG repository key
# --src ELASTICSEARCH_SRC     : Elasticsearch repository url
#
# --user=USERNAME             : Specify the superuser name for Elasticsearch (administrator)
# --password=PASSWORD         : Specify the superuser password for Elasticsearch (elastic)
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@gmail.com
#
# DESCRIPTION : Elasticsearch installation
################################################################################

###################################################################### CONSTANTS
LOG_PREFIX="ELK"
LOG_FOLDER=/home/vagrant/logs
LOG_FILE=elasticsearch.log

ELASTICSEARCH_CLUSTER_NAME="ELK-demo"
ELASTICSEARCH_IP="127.0.0.1"
ELASTICSEARCH_PORT=9200
ELASTICSEARCH_KEY="https://artifacts.elastic.co/GPG-KEY-elasticsearch"
ELASTICSEARCH_SRC="https://artifacts.elastic.co/packages/7.x/apt"
ELASTICSEARCH_FOLDER="/etc/elasticsearch"
ELASTICSEARCH_CERTS=$ELASTICSEARCH_FOLDER/certs
ELASTICSEARCH_BIN="/usr/share/elasticsearch/bin"
ELASTICSEARCH_USERNAME="administrator"
ELASTICSEARCH_PASSWORD="elastic"


###################################################################### VARIABLES
verbose=''
logPrefix=$LOG_PREFIX
logFolder=$LOG_FOLDER
logFile=$LOG_FILE

elasticsearchIP=$ELASTICSEARCH_IP
elasticsearchPort=$ELASTICSEARCH_PORT
elasticKey=$ELASTICSEARCH_KEY
elasticSrc=$ELASTICSEARCH_SRC
elasticsearchUsername=$ELASTICSEARCH_USERNAME
elasticsearchPassword=$ELASTICSEARCH_PASSWORD

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
   --user)
      shift
      elasticsearchUsername=$1;;
   --password)
      shift
      elasticsearchPassword=$1;;
   esac
   shift
done


###################################################################### FUNCTIONS
show_parameters(){
   echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix} - Parameters"
   echo "VERBOSE : ${verbose}"
   echo "Log folder : ${logFolder}"
   echo "Log file : ${logFile}"
   echo "Elasticsearch IP : ${elasticsearchIP}"
   echo "Elasticsearch port : ${elasticsearchPort}"
   echo "Elasticsearch key : ${elasticKey}"
   echo "Elasticsearch package sources : ${elasticSrc}"
}

elasticsearch_prepare(){
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - Prepare"; fi
   wget -qO - ${elasticKey} | sudo apt-key add -
   echo "deb ${elasticSrc} stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
   sudo apt-get update >> ${logFolder}/${logFile}   
}

elasticsearch_install(){
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - Install"; fi 
   sudo apt-get install elasticsearch >> ${logFolder}/${logFile}
}

elasticsearch_configure(){
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - Configure"; fi 
   sudo echo "
cluster.name: ${ELASTICSEARCH_CLUSTER_NAME}
network.host: ${elasticsearchIP}
http.port: ${elasticsearchPort}
discovery.type: single-node
discovery.seed_hosts: [\"${elasticsearchIP}\"]
   " >> /etc/elasticsearch/elasticsearch.yml

   sudo echo "
-Xms512m
-Xmx512m
   " >> /etc/elasticsearch/jvm.options
}

elasticsearch_service_start() {
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - Services restart"; fi 
   sudo systemctl daemon-reload >> ${logFolder}/${logFile}
   sudo systemctl enable elasticsearch.service >> ${logFolder}/${logFile} 
   sudo systemctl start elasticsearch.service >> ${logFolder}/${logFile} 
}

elasticsearch_configure_transport_tls_ssl() {
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - Transport TLS/SSL configuration"; fi
   # Generate certificates
   sudo mkdir -p $ELASTICSEARCH_CERTS
   sudo ${ELASTICSEARCH_BIN}/elasticsearch-certutil ca --pass "" --out elastic-stack-ca.p12
   sudo ${ELASTICSEARCH_BIN}/elasticsearch-certutil cert --ca-pass "" --ca elastic-stack-ca.p12 --pass "" --out $ELASTICSEARCH_CERTS/elastic-certificates.p12
   
   sudo chmod 660 $ELASTICSEARCH_CERTS/*
   sudo chown :elasticsearch $ELASTICSEARCH_CERTS/*

   # Modify transport ssl configuration
   sudo echo "
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: ${ELASTICSEARCH_CERTS}/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: ${ELASTICSEARCH_CERTS}/elastic-certificates.p12
   " >> /etc/elasticsearch/elasticsearch.yml

   # restart service to take account of elasticsearch.yml modifications
   sudo systemctl restart elasticsearch.service >> ${logFolder}/${logFile}
}

elasticsearch_generate_passwords() {
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - Generate Passwords"; fi
   # Auto generate Users buid elasticsearch passwords and write in log file
   sudo echo "y" | ${ELASTICSEARCH_BIN}/elasticsearch-setup-passwords auto >> ${logFolder}/${logFile}
}

elasticsearch_configure_http_tls_ssl() {
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - HTTP TLS/SSL configuration"; fi

   # Modify http ssl configuration
   sudo echo "
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: ${ELASTICSEARCH_CERTS}/elastic-certificates.p12
xpack.security.http.ssl.truststore.path: ${ELASTICSEARCH_CERTS}/elastic-certificates.p12
xpack.security.http.ssl.client_authentication: optional
   " >> /etc/elasticsearch/elasticsearch.yml

   sudo systemctl restart elasticsearch.service >> ${logFolder}/${logFile}   
}

elasticsearch_create_superuser() {
   if [[ -n $verbose ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix}   - Create superuser"; fi
   sudo ${ELASTICSEARCH_BIN}/elasticsearch-users useradd ${elasticsearchUsername} -p ${elasticsearchPassword} -r superuser
}

########################################################################### MAIN
main() {
   mkdir -p ${logFolder}
   touch ${logFolder}/${logFile}
   
   show_parameters >> ${logFolder}/${logFile} 
   if [[ -n $verbose ]]; then
      show_parameters
   fi
         
   elasticsearch_prepare
   elasticsearch_install
   elasticsearch_configure
   elasticsearch_service_start
   elasticsearch_configure_transport_tls_ssl
   elasticsearch_generate_passwords
   elasticsearch_configure_http_tls_ssl
   elasticsearch_create_superuser
}

main