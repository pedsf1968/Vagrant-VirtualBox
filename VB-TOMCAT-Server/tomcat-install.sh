################################################################################
# FILE NAME   : tomcat-install.sh
# FILE TYPE   : BASH
# VERSION     : 210723
# ARGS        
# --verbose                    : Verbose installation
# --managmentIP MANAGMENT_IP   : Specify the managment IP
# --ntpIP NTP_IP               : Specify the NTP server IP
# --timezone TIME_ZONE         : Specify the time zone
# --hostname VM_HOSTNAME       : Specify a hostname for the VM
# --ip VM_IP                   : Specify an IP for the VM
# --archive ARCHIVE_URL        : Specify the Tomcat archive to install
# --directory TOMCAT_DIRECTORY : Specify the directory where to install Tomcat
# --adminPwd ADMIN_PWD         : Set Tomcat admin password
# --managerPwd MANAGER_PWD     : Set Tomcat manager password
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@gmail.com
#
# DESCRIPTION : TOMCAT server installation
################################################################################

###################################################################### CONSTANTS
MESSAGE_PREFIX="TOMCAT"
LOG_DIRECTORY=/home/vagrant/logs
LOG_FILE=$LOG_DIRECTORY/tomcat.log
MANAGMENT_IP='.*'
NTP_IP="10.1.33.11"
NETWORK_TIMEZONE="Europe/Paris"
VM_HOSTNAME="TOMCAT-server"
VM_IP="10.1.33.21"
TOMCAT_ARCHIVE_LINK="https://downloads.apache.org/tomcat/tomcat-9/v9.0.50/bin/apache-tomcat-9.0.50.tar.gz"
TOMCAT_DIRECTORY='/etc/tomcat'
TOMCAT_DEPLOYMENT_DIRECTORY="/tmp"
TOMCAT_ADMIN_PWD='Admin'
TOMCAT_MANAGER_PWD='Manager'

###################################################################### VARIABLES
managmentIP=${MANAGMENT_IP}
ntpIP=${NTP_IP}
networkTimezone=${NETWORK_TIMEZONE}
vmHostname = ${VM_HOSTNAME}
vmIP = ${VM_IP}
tomcatArchiveLink=${TOMCAT_ARCHIVE_LINK}
tomcatDirectory=${TOMCAT_DIRECTORY}
tomcatAdminPassword=${TOMCAT_ADMIN_PWD}
tomcatManagerPassword=${TOMCAT_MANAGER_PWD}


while [[ $# > 0 ]]; do
   case $1 in
   --verbose) 
      verbose="True";;
   --managmentIP)
      shift
      managmentIP=$1;;
   --ntpIP)
      shift
      ntpIP=$1;;
   --timezone)
      shift
      $networkTimezone=$1;;
   --ip)
      shift
      vmIP=$1;;
   --hostname)
      shift
      vmHostname=$1;;
   --archive)
      shift
      tomcatArchiveLink=$1;;
   --directory)
      shift
      tomcatDirectory=$1;;
   --adminPwd)
      shift
      tomcatAdminPassword=$1;;
   --managerPwd)
      shift
      tomcatManagerPassword=$1;;
   esac
   shift
done

###################################################################### FUNCTIONS
linux_update(){
   if [[ -n "${verbose}" ]]; then echo "${MESSAGE_PREFIX} - Linux update"; fi
   sudo apt-get update >> ${LOG_FILE}
   sudo apt-get upgrade -y >> ${LOG_FILE}
}

common_install(){
   if [[ -n "${verbose}" ]]; then echo "${MESSAGE_PREFIX} - Common packages install"; fi
   sudo apt-get install -y -qq vim net-tools telnet python3-pip sshpass nfs-common >> ${LOG_FILE}
}

ssh_setting(){
   if [[ -n "${verbose}" ]]; then echo "${MESSAGE_PREFIX} - SSH setting"; fi
   sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
   sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
}

ntp_setting(){
   if [[ -n "${verbose}" ]]; then echo "${MESSAGE_PREFIX} - NTP setting"; fi
   sudo sed -i "s/#FallbackNTP=ntp.ubuntu.com/FallbackNTP=${ntpIP}/g" /etc/systemd/timesyncd.conf
   sudo timedatectl set-timezone ${networkTimezone}
   sudo timedatectl set-ntp true
}


tomcat_install(){
   if [[ -n "${verbose}" ]]; then echo "${MESSAGE_PREFIX} - Install"; fi
   sudo apt install -y default-jdk > /dev/null >> ${LOG_FILE}
   sudo useradd -m -d ${tomcatDirectory} -U -s /bin/false tomcat >> ${LOG_FILE}
   wget ${tomcatArchiveLink} -P ${TOMCAT_DEPLOYMENT_DIRECTORY} >> ${LOG_FILE}
   sudo tar -xzf ${TOMCAT_DEPLOYMENT_DIRECTORY}/apache-tomcat-*tar.gz -C ${tomcatDirectory} --strip-components=1 >> ${LOG_FILE}
   sudo rm ${TOMCAT_DEPLOYMENT_DIRECTORY}/apache-tomcat-*tar.gz
}

tomcat_configure(){
   if [[ -n "${verbose}" ]]; then echo "${MESSAGE_PREFIX} - Configuration setting"; fi

   sudo bash -c echo "
   [Unit]
   Description=Tomcat 10 server
   After=network.target

   [Service]
   Type=forking

   User=tomcat
   Group=tomcat

   Environment=\"JAVA_HOME=/usr/lib/jvm/default-java\"
   Environment=\"JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true\"
   Environment=\"CATALINA_BASE=${tomcatDirectory}\"
   Environment=\"CATALINA_HOME=${tomcatDirectory}\"
   Environment=\"CATALINA_PID=${tomcatDirectory}/temp/tomcat.pid\"
   Environment=\"CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC\"

   ExecStart=${tomcatDirectory}/bin/startup.sh
   ExecStop=${tomcatDirectory}/bin/shutdown.sh

   [Install]
   WantedBy=multi-user.target"
 > /etc/systemd/system/tomcat.service


   # Change Tomcat manager and admin password
   sudo sed -i s/"<\/tomcat-users>"//g ${tomcatDirectory}/conf/tomcat-users.xml
   sudo echo "
<role rolename=\"manager-gui\"/>
<role rolename=\"admin-gui\"/>
<user username=\"manager\" password=\"${tomcatManagerPassword}\" roles=\"manager-gui\"/>
<user username=\"admin\" password=\"${tomcatAdminPassword}\" roles=\"manager-gui,admin-gui\"/>
</tomcat-users>" >> ${tomcatDirectory}/conf/tomcat-users.xml

   # Change access authorisation for managment IP for /manager and /host-manager
   PATTERN='allow=\"127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1\"'
   REPLACEMENT='allow=\"'${managmentIP}'\"'
   sudo sed -i "s/${PATTERN}/${REPLACEMENT}/g" ${tomcatDirectory}/webapps/manager/META-INF/context.xml
   sudo sed -i "s/${PATTERN}/${REPLACEMENT}/g" ${tomcatDirectory}/webapps/host-manager/META-INF/context.xml

   # Set tomcat owner of Tomcat directory
   sudo chown -R tomcat:tomcat ${tomcatDirectory} 
   sudo chmod -R u+x ${tomcatDirectory}/bin 

   # Remove ROOT, examples, docs directories
   #sudo rm -R ${tomcatDirectory}/webapps/ROOT
   #sudo rm -R ${tomcatDirectory}/webapps/examples
   sudo rm -R ${tomcatDirectory}/webapps/docs

   # set right name and IP in /etc/hosts file
   sudo sed -i /${vmHostname}/d /etc/hosts
   sudo bash -c "echo $vmIP $vmHostname $vmHostname >> /etc/hosts"
}

services_restart() {
   if [[ -n "${verbose}" ]]; then echo "${MESSAGE_PREFIX} - Restart service"; fi
   sudo systemctl daemon-reload
   sudo systemctl restart sshd
   sudo systemctl restart systemd-timesyncd 
   sudo systemctl enable tomcat
   sudo systemctl start tomcat
}

########################################################################### MAIN
main() {
    if [[ -n ${verbose} ]]; then 
      echo "${MESSAGE_PREFIX} - Parameters"
      echo "Log directory : ${LOG_DIRECTORY}"
      echo "Log file : ${LOG_FILE}"
      echo "ManagementIP : ${MANAGEMENT_IP}"
      echo "NTP IP : ${NTP_IP}"
      echo "Network time zone : ${networkTimezone}"
      echo "Hostname : ${vmHostname}"
      echo "IP : ${vmIP}"
      echo "Archive URL : ${tomcatArchiveLink}" 
      echo "Directory : ${tomcatDirectory}"
      echo "Admin password : ${tomcatAdminPassword}"
      echo "Manager password : ${tomcatManagerPassword}"
   fi

   mkdir -p $LOG_DIRECTORY
   touch $LOG_FILE

   linux_update
   common_install
   tomcat_install
   ssh_setting
   if [[ -n "${ntpIP}" ]]; then ntp_setting; fi
   tomcat_configure
   services_restart
}

main