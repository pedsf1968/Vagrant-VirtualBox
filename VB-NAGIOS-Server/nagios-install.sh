################################################################################
# FILE NAME   : nagios-install.sh
# FILE TYPE   : BASH
# VERSION     : 210717
# ARGS        
# --verbose                     : Verbose installation
# --managementIP MANAGEMENT_IP  : Specify the management IP
# --ntpIP NTP_IP                : Specify the NTP server IP
# --timezone TIME_ZONE          : Specify the time zone
# --hostname VM_HOSTNAME        : Specify a hostname for the VM
# --ip VM_IP                    : Specify an IP for the VM
# --archive ARCHIVE_URL         : Specify the Nagios archive to install
# --plugins PLUGINS_ARCHIVE_URL : Specify the Nagios plugins URL link archive
# --directory NAGIOS_DIRECTORY  : Specify the directory where to install Nagios configuration
# --adminPwd ADMIN_PWD          : Set Nagios admin password
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@gmail.com
#
# DESCRIPTION : NAGIOS server installation
################################################################################

###################################################################### CONSTANTS
MESSAGE_PREFIX="NAGIOS"
LOG_DIRECTORY=/home/vagrant/logs
LOG_FILE=$LOG_DIRECTORY/nagios.log
MANAGMENT_IP=".*"
NTP_IP="10.1.33.11"
NETWORK_TIMEZONE="Europe/Paris"
VM_HOSTNAME="NAGIOS-server"
VM_IP="10.1.33.13"
NAGIOS_ARCHIVE_URL="https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.6.tar.gz"
NAGIOS_PLUGINS_ARCHIVE_URL="https://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz"
NAGIOS_DIRECTORY="/usr/local/nagios/my_conf"
NAGIOS_DEPLOYMENT_DIRECTORY="/tmp"
NAGIOS_ADMIN_PWD="nagios"

###################################################################### VARIABLES
verbose=""
managementIP=${MANAGMENT_IP}
ntpIP=${NTP_IP}
networkTimezone=${NETWORK_TIMEZONE}
vmHostname = ${VM_HOSTNAME}
vmIP = ${VM_IP}
nagiosArchiveUrl=${NAGIOS_ARCHIVE_URL}
nagiosPluginsArchiveUrl=${NAGIOS_PLUGINS_ARCHIVE_URL}
nagiosDirectory=${NAGIOS_DIRECTORY}
nagiosAdminPassword=${NAGIOS_ADMIN_PWD}

while [[ $# > 0 ]]; do
   case $1 in
   --verbose) 
      verbose="True";;
   --managementIP)
      shift
      managementIP=$1;;
   --ntpIP)
      shift
      ntpIP=$1;;
   --timezone)
      shift
      networkTimezone=$1;;
   --ip)
      shift
      vmIP=$1;;
   --hostname)
      shift
      vmHostname=$1;;
   --archive)
      shift
      nagiosArchiveUrl=$1;;
   --plugins)
      shift
      nagiosPluginsArchiveUrl=$1;;
   --directory)
      shift
      nagiosDirectory=$1;;
   --adminPwd)
      shift
      nagiosAdminPassword=$1
   esac
   shift
done

###################################################################### FUNCTIONS
linux_update(){
   if [[ -n ${verbose} ]]; then echo "${MESSAGE_PREFIX} - Linux update"; fi
   sudo apt-get update >> ${LOG_FILE}
   sudo apt-get upgrade -y >> ${LOG_FILE}
}

common_install(){
   if [[ -n ${verbose} ]]; then echo "${MESSAGE_PREFIX} - Common packages install"; fi
   sudo apt-get install -y -qq vim net-tools telnet python3-pip sshpass nfs-common >> ${LOG_FILE}
}

ssh_setting(){
   if [[ -n ${verbose} ]]; then echo "${MESSAGE_PREFIX} - SSH setting"; fi
   sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
   sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
}

ntp_setting(){
   if [[ -n ${verbose} ]]; then echo "${MESSAGE_PREFIX} - NTP setting"; fi
   sudo sed -i "s/#FallbackNTP=ntp.ubuntu.com/FallbackNTP=${ntpIP}/g" /etc/systemd/timesyncd.conf
   sudo timedatectl set-timezone ${networkTimezone}
   sudo timedatectl set-ntp true
}

nagios_package_install(){
   if [[ -n ${verbose} ]]; then echo "${MESSAGE_PREFIX} - Apache install"; fi
   sudo apt-get install -y -qq apache2 >> ${LOG_FILE}
   if [[ -n ${verbose} ]]; then echo "${MESSAGE_PREFIX} - PHP install"; fi
   sudo apt-get install -y -qq php php-gd php-imap php-curl php-dev libmcrypt-dev php-pear  >> ${LOG_FILE}
   sudo pecl channel-update pecl.php.net >> ${LOG_FILE}
   sudo pecl install mcrypt-1.0.3 <<<''
   sudo bash -c "echo 'extension=mcrypt.so' >> /etc/php/7.4/cli/php.ini"

   if [[ -n ${verbose} ]]; then echo "${MESSAGE_PREFIX} - Perl libs install"; fi
   sudo apt-get install -y -qq libxml-libxml-perl libnet-snmp-perl libperl-dev libnumber-format-perl libconfig-inifiles-perl libdatetime-perl libnet-dns-perl >> ${LOG_FILE}
   if [[ -n ${verbose} ]]; then echo "${MESSAGE_PREFIX} - Graphic libs install"; fi
   sudo apt-get install -y -qq libpng-dev libjpeg-dev libgd-dev >> ${LOG_FILE}
   if [[ -n ${verbose} ]]; then echo "${MESSAGE_PREFIX} - Compilation tools libs install"; fi
   sudo apt-get install -y -qq gcc make autoconf libc6 unzip libssl-dev >> ${LOG_FILE}
}

nagios_user_configure(){
   if [[ -n ${verbose} ]]; then echo "${MESSAGE_PREFIX} - User configuration setting"; fi
   sudo useradd -m -p $(openssl passwd ${nagiosAdminPassword}) nagios
   sudo groupadd nagcmd
   sudo usermod --shell /bin/bash nagios
   sudo usermod -a -G nagcmd nagios
   sudo usermod -a -G nagcmd www-data

   # Allow nagios user to restart nagios process
   echo "
nagios ALL=NOPASSWD:/bin/systemctl restart nagios
nagios ALL=NOPASSWD:/bin/systemctl status nagios
   " | sudo tee -a /etc/sudoers

   # Add aliases for nagios user
   echo "
# Aliases for Nagios
alias nTestCfg='/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg'
alias nRestart='sudo systemctl restart nagios'
alias nStatus='sudo systemctl status nagios'
   " | sudo tee -a  /home/nagios/.bashrc
}

nagios_install(){
   if [[ -n ${verbose} ]]; then echo "${MESSAGE_PREFIX} - Install"; fi
   sudo mkdir -p ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios
   wget ${nagiosArchiveUrl} -P ${NAGIOS_DEPLOYMENT_DIRECTORY} >> ${LOG_FILE}
   sudo tar -xzf ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios-*tar.gz -C ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios --strip-components=1 >> ${LOG_FILE}
   sudo rm ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios-*tar.gz

   cd ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios
   sudo ./configure --with-httpd-conf=/etc/apache2/sites-enabled --with-command-group=nagcmd >> ${LOG_FILE} 
   sudo make all >> ${LOG_FILE}
   sudo make install >> ${LOG_FILE}
   sudo make install-daemoninit >> ${LOG_FILE}
   sudo make install-commandmode >> ${LOG_FILE}
   sudo make install-config >> ${LOG_FILE}
   sudo make install-webconf >> ${LOG_FILE}
}

nagios_plugins_install(){
   if [[ -n ${verbose} ]]; then echo "${MESSAGE_PREFIX} - Plugins install"; fi
   sudo mkdir -p ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios-plugins
   wget ${nagiosPluginsArchiveUrl} -P /${NAGIOS_DEPLOYMENT_DIRECTORY} >> ${LOG_FILE}
   sudo tar -xzf ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios-plugins-*tar.gz -C ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios-plugins --strip-components=1 >> ${LOG_FILE}
   sudo rm ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios-plugins-*tar.gz >> ${LOG_FILE}
   
   cd ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios-plugins
   sudo ./configure --with-nagios-user=nagios --with-nagios-group=nagcmd  --with-openssl=/usr/bin/openssl >> ${LOG_FILE}

   sudo make >> ${LOG_FILE}
   sudo make install >> ${LOG_FILE}
}

nagios_configure(){
   if [[ -n ${verbose} ]]; then echo "${MESSAGE_PREFIX} - Configure"; fi
   # Enable Apache modules
   sudo a2enmod rewrite >> ${LOG_FILE}
   sudo a2enmod cgi >> ${LOG_FILE}

   # Set ip in /etc/hosts
   echo "${vmIP} ${vmHostname}" | sudo tee -a /etc/hosts

   # Move Nagios configuration files to configuration directory
   sudo mkdir ${nagiosDirectory}
   sudo cp ${NAGIOS_DEPLOYMENT_DIRECTORY}/*.cfg ${nagiosDirectory}
   # Modify password in nagios sample
   sudo sed -i s/nagiosadmin:nagios/nagiosadmin:${nagiosAdminPassword}/g ${nagiosDirectory}/nagios.cfg

   # Add new configuration directory to Nagios configuration
   echo "
# New configuration directory
cfg_dir=${nagiosDirectory}
   " | sudo tee -a /usr/local/nagios/etc/nagios.cfg

   # Set Nagios admin user to web interface
   sudo htpasswd -cb /usr/local/nagios/etc/htpasswd.users nagiosadmin ${nagiosAdminPassword}
   sudo chown -R nagios:nagcmd /usr/local/nagios

   # set right name and IP in /etc/hosts file
   sed -i /${vmHostname}/d /etc/hosts
   sed -i s/$(cat /etc/hosts | grep ubuntu | cut -f2)/${vmHostname}/g /etc/hosts
   sudo bash -c "echo ${vmIP}\t${vmHostname}\t${vmHostname} >> /etc/hosts"
}

services_restart() {
   if [[ -n ${verbose} ]]; then echo "${MESSAGE_PREFIX} - Restart services"; fi
   sudo systemctl daemon-reload >> ${LOG_FILE}
   sudo systemctl restart sshd >> ${LOG_FILE}
   sudo systemctl restart systemd-timesyncd >> ${LOG_FILE}
   sudo systemctl restart apache2 >> ${LOG_FILE}
   sudo systemctl start nagios >> ${LOG_FILE} 
}


########################################################################### MAIN
main(){
   if [[ -n ${verbose} ]]; then 
      echo "${MESSAGE_PREFIX} - Parameters"
      echo "Log directory : ${LOG_DIRECTORY}"
      echo "Log file : ${LOG_FILE}"
      echo "ManagementIP : ${MANAGEMENT_IP}"
      echo "NTP IP : ${NTP_IP}"
      echo "Network time zone : ${networkTimezone}"
      echo "Hostname : ${vmHostname}"
      echo "IP : ${vmIP}"
      echo "Archive URL : ${nagiosArchiveUrl}" 
      echo "Plugins archive URL : ${nagiosPluginsArchiveUrl}" 
      echo "Directory : ${nagiosDirectory}"
      echo "Admin password : ${nagiosAdminPassword}"
   fi

   mkdir -p $LOG_DIRECTORY
   touch $LOG_FILE

   linux_update
   common_install
   ssh_setting
   if [[ -n "${ntpIP}" ]]; then ntp_setting; fi
   nagios_package_install
   nagios_user_configure
   nagios_install
   nagios_plugins_install
   nagios_configure
   services_restart
}

main