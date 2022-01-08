################################################################################
# FILE NAME   : nagios-install.sh
# FILE TYPE   : BASH
# VERSION     : 220102
# ARGS        
# --verbose                     : Verbose installation
# --managementIP MANAGEMENT_IP  : Specify the management IP
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
LOG_PREFIX="NAGIOS"
LOG_FOLDER=/home/vagrant/logs
LOG_FILE=nagios.log

MANAGMENT_IP=".*"
VM_HOSTNAME="NAGIOS-server"
VM_IP="10.1.33.13"

NAGIOS_ARCHIVE_URL="https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.6.tar.gz"
NAGIOS_PLUGINS_ARCHIVE_URL="https://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz"
NAGIOS_DIRECTORY="/usr/local/nagios/my_conf"
NAGIOS_DEPLOYMENT_DIRECTORY="/tmp"
NAGIOS_ADMIN_PWD="nagios"

###################################################################### VARIABLES
verbose=''
logPrefix=$LOG_PREFIX
logFolder=$LOG_FOLDER
logFile=$LOG_FILE

managementIP=${MANAGMENT_IP}

nagiosArchiveUrl=${NAGIOS_ARCHIVE_URL}
nagiosPluginsArchiveUrl=${NAGIOS_PLUGINS_ARCHIVE_URL}
nagiosDirectory=${NAGIOS_DIRECTORY}
nagiosAdminPassword=${NAGIOS_ADMIN_PWD}

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
   --managementip)
      shift
      managementIP=$1;;
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
show_parameters(){
   echo "$(date +'%Y/%m/%d-%R:%S') : ${logPrefix} - Parameters"
      echo "Log directory : ${logFolder}"
      echo "Log file : ${logFile}"
      echo "ManagementIP : ${managementIP}"
      echo "Archive URL : ${nagiosArchiveUrl}" 
      echo "Plugins archive URL : ${nagiosPluginsArchiveUrl}" 
      echo "Directory : ${nagiosDirectory}"
      echo "Admin password : ${nagiosAdminPassword}"
}

nagios_package_install(){
   if [[ -n ${verbose} ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${LOG_PREFIX} - Apache install"; fi
   sudo apt-get install -y -qq apache2 >> ${logFolder}/${logFile}
   if [[ -n ${verbose} ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${LOG_PREFIX} - PHP install"; fi
   sudo apt-get install -y -qq php php-gd php-imap php-curl php-dev libmcrypt-dev php-pear  >> ${LOG_FILE}
   sudo pecl channel-update pecl.php.net >> ${logFolder}/${logFile}
   sudo pecl install mcrypt-1.0.3 <<<''
   sudo bash -c "echo 'extension=mcrypt.so' >> /etc/php/7.4/cli/php.ini"

   if [[ -n ${verbose} ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${LOG_PREFIX} - Perl libs install"; fi
   sudo apt-get install -y -qq libxml-libxml-perl libnet-snmp-perl libperl-dev libnumber-format-perl libconfig-inifiles-perl libdatetime-perl libnet-dns-perl >> ${LOG_FILE}
   if [[ -n ${verbose} ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${logFolder}/${logFile} - Graphic libs install"; fi
   sudo apt-get install -y -qq libpng-dev libjpeg-dev libgd-dev >> ${logFolder}/${logFile}
   if [[ -n ${verbose} ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${LOG_PREFIX} - Compilation tools libs install"; fi
   sudo apt-get install -y -qq gcc make autoconf libc6 unzip libssl-dev >> ${logFolder}/${logFile}
}

nagios_user_configure(){
   if [[ -n ${verbose} ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${LOG_PREFIX} - User configuration setting"; fi
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
   if [[ -n ${verbose} ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${LOG_PREFIX} - Install"; fi
   sudo mkdir -p ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios
   wget ${nagiosArchiveUrl} -P ${NAGIOS_DEPLOYMENT_DIRECTORY} >> ${logFolder}/${logFile}
   sudo tar -xzf ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios-*tar.gz -C ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios --strip-components=1 >> ${LOG_FILE}
   sudo rm ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios-*tar.gz

   cd ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios
   sudo ./configure --with-httpd-conf=/etc/apache2/sites-enabled --with-command-group=nagcmd >> ${LOG_FILE} 
   sudo make all >> ${logFolder}/${logFile}
   sudo make install >> ${logFolder}/${logFile}
   sudo make install-daemoninit >> ${logFolder}/${logFile}
   sudo make install-commandmode >> ${logFolder}/${logFile}
   sudo make install-config >> ${logFolder}/${logFile}
   sudo make install-webconf >> ${logFolder}/${logFile}
}

nagios_plugins_install(){
   if [[ -n ${verbose} ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${LOG_PREFIX} - Plugins install"; fi
   sudo mkdir -p ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios-plugins
   wget ${nagiosPluginsArchiveUrl} -P /${NAGIOS_DEPLOYMENT_DIRECTORY} >> ${logFolder}/${logFile}
   sudo tar -xzf ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios-plugins-*tar.gz -C ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios-plugins --strip-components=1 >> ${LOG_FILE}
   sudo rm ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios-plugins-*tar.gz >> ${logFolder}/${logFile}
   
   cd ${NAGIOS_DEPLOYMENT_DIRECTORY}/nagios-plugins
   sudo ./configure --with-nagios-user=nagios --with-nagios-group=nagcmd  --with-openssl=/usr/bin/openssl >> ${LOG_FILE}

   sudo make >> ${logFolder}/${logFile}
   sudo make install >> ${logFolder}/${logFile}
}

nagios_configure(){
   if [[ -n ${verbose} ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${LOG_PREFIX} - Configure"; fi
   # Enable Apache modules
   sudo a2enmod rewrite >> ${logFolder}/${logFile}
   sudo a2enmod cgi >> ${logFolder}/${logFile}
   
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
}

services_restart() {
   if [[ -n ${verbose} ]]; then echo "$(date +'%Y/%m/%d-%R:%S') : ${LOG_PREFIX} - Restart services"; fi
   sudo systemctl daemon-reload >> ${logFolder}/${logFile}
   sudo systemctl restart sshd >> ${logFolder}/${logFile}
   sudo systemctl restart systemd-timesyncd >> ${logFolder}/${logFile}
   sudo systemctl restart apache2 >> ${logFolder}/${logFile}
   sudo systemctl start nagios >> ${logFolder}/${logFile} 
}


########################################################################### MAIN
main(){
   mkdir -p $logFolder
   touch $logFolder/$logFile

   show_parameters >> ${logFolder}/${logFile} 
   if [[ -n $verbose ]]; then
      show_parameters
   fi
   
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