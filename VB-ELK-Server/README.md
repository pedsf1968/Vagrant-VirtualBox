## VB-ELK-Server
Vagrantfile for configuring ELK server with Elasticsearch and Kibana on Ubuntu with default options.
You can add parameters to vagrant up to change default options.

### Parameters
- --help, -h                       : Show Vagrantfile options
- --verbose, -v                    : Verbose installation
- --ntpip=NTP_IP              : Specify the NTP server IP (10.1.33.10)
- --timezone=NETWORK_TIMEZONE : Specify the time zone (Europe/Paris)
- --name=VM_NAME              : Specify a name for the VM (Vagrant-ELK-server)
- --hostname=VM_HOSTNAME      : Specify a hostname for the VM (ELK-server)
- --ip=VM_IP                  : Specify an IP for the VM (10.1.33.15)
- --cpus=VM_CPUS              : Specify the VM core number (4)
- --memory=VM_MEMORY          : Specify the VM memory amount in ko (4096)
- --user=USERNAME             : Specify the superuser name for Elasticsearch (administrator)
- --password=PASSWORD         : Specify the superuser password for Elasticsearch (elastic)

### Examples
vagrant --verbose up
vagrant --ip="192.168.0.15" --ntpIP="192.168.0.10" up

### Default configuration is:
LOG_FOLDER="/home/vagrant/logs"
LOG_PREFIX="ELK"

VM_NAME = "Vagrant-ELK-server"
VM_HOSTNAME = "ELK-server"
VM_IP = "10.1.33.15"
VM_CPUS = "4"
VM_MEMORY = "4096"
VM_GUI = false

ELASTICSEARCH_IP="10.1.33.15"
ELASTICSEARCH_PORT=9200
ELASTICSEARCH_SHARDING_PORT=9300
ELASTICSEARCH_KEY="https://artifacts.elastic.co/GPG-KEY-elasticsearch"
ELASTICSEARCH_SRC="https://artifacts.elastic.co/packages/7.x/apt stable main"
ELASTICSEARCH_USERNAME="administrator"
ELASTICSEARCH_PASSWORD="elastic"


KIBANA_IP="10.1.33.15"
KIBANA_PORT=5601
KIBANA_KEY="https://artifacts.elastic.co/GPG-KEY-elasticsearch"
KIBANA_SRC="https://artifacts.elastic.co/packages/7.x/apt stable main"

### Depend on
- common-install.sh
- elasticsearch-install.sh
- kibana-install.sh

## elasticsearch-install.sh
Bash script for Elasticsearch installation

### Parameters
- --verbose                   : Verbose installation
- --logprefix LOG_PREFIX      : Specify prefix of log message (ELK)
- --logfolder LOG_FOLDER      : Specify the directory of installation log file (/home/vagrant/logs)
- --logfile LOG_FILE          : Specify the installation log file name (elasticsearch.log)
- --ip ELASTICSEARCH_IP       : Specify the IP for Elasticsearch (127.0.0.1)
- --port ELASTICSEARCH_PORT   : Specify the port for Elasticsearch (9200)
- --key ELASTICSEARCH_KEY     : Elasticsearch GPG repository key 
- --src ELASTICSEARCH_SRC     : Elasticsearch repository url
- --user=USERNAME             : Specify the superuser name for Elasticsearch (administrator)
- --password=PASSWORD         : Specify the superuser password for Elasticsearch (elastic)

### Default configuration is:
MESSAGE_PREFIX="ELK"
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


## kibana-install.sh
Bash script for Kibana installation

### Parameters
- --verbose              : Verbose installation
- --logprefix LOG_PREFIX : Specify prefix of log message (ELK)
- --logfolder LOG_FOLDER : Specify the directory of installation log file (/home/vagrant/logs)
- --logfile LOG_FILE     : Specify the installation log file name (kibana.log)
- --ip KIBANA_IP         : Specify the IP for Kibana (127.0.0.1)
- --port KIBANA_PORT     : Specify the port for Kibana (5601)
- --key KIBANA_KEY       : Elasticsearch GPG repository key 
- --src KIBANA_SRC       : Elasticsearch repository url
- --elasticsearchip ELASTICSEARCH_IP       : Specify the IP for Elasticsearch (127.0.0.1)
- --elasticsearchport ELASTICSEARCH_PORT   : Specify the port for Elasticsearch (9200)


### Default configuration is:
LOG_PREFIX="ELK"
LOG_FOLDER=/home/vagrant/logs
LOG_FILE=kibana.log

ELASTICSEARCH_IP="127.0.0.1"
ELASTICSEARCH_PORT=9200
ELASTICSEARCH_USERNAME="kibana"
ELASTICSEARCH_PASSWORD="kibana"
ELASTICSEARCH_FOLDER="/etc/elasticsearch"
ELASTICSEARCH_CERTS=/etc/elasticsearch/certs"
ELASTICSEARCH_BIN="/usr/share/elasticsearch/bin"

KIBANA_IP="127.0.0.1"
KIBANA_PORT=5601
KIBANA_KEY="https://artifacts.elastic.co/GPG-KEY-elasticsearch"
KIBANA_SRC="https://artifacts.elastic.co/packages/7.x/apt"
KIBANA_FOLDER="/etc/kibana"
KIBANA_CERTS=$KIBANA_FOLDER/certs
KIBANA_BIN="/usr/share/kibana/bin"
KIBANA_USER=kibana_system
