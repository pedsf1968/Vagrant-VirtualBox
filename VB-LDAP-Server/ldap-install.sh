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
MESSAGE_PREFIX="LDAP"
LOG_DIRECTORY=/home/vagrant/logs
LOG_FILE=$LOG_DIRECTORY/ldap.log
MANAGMENT_IP='.*'
NTP_IP="10.1.33.11"
NETWORK_TIMEZONE="Europe/Paris"
VM_HOSTNAME="LDAP-server"
VM_IP="10.1.33.12"
LDAP_DOMAIN="mycompany.com"
LDAP_ORGANIZATION="mycompany"
LDAP_ADMIN_PWD="ldapAdmin"

###################################################################### VARIABLES
managmentIP=${MANAGMENT_IP}
ntpIP=${NTP_IP}
networkTimezone=${NETWORK_TIMEZONE}
vmHostname=${VM_HOSTNAME}
vmIP=${VM_IP}
ldapDomain=${LDAP_DOMAIN}
ldapOrganization=${LDAP_ORGANIZATION}
ldapAdminPassword=${LDAP_ADMIN_PWD}

DIT_domain_dn="dc=$(echo ${ldapDomain} | sed 's/\./,dc=/g')"
DIT_admin_dn="cn=admin,${DIT_domain_dn}"

echo "FQDN : "$(hostname --fqdn)


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
   --domain)
      shift
      ldapDomain=$1;;
    --organization)
      shift
      ldapOrganization=$1;;
    --adminPwd)
      shift
      ldapAdminPassword=$1;;
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
   sed -i "s/#FallbackNTP=ntp.ubuntu.com/FallbackNTP=${ntpIP}/g" /etc/systemd/timesyncd.conf
   sudo timedatectl set-timezone ${networkTimezone}
   sudo timedatectl set-ntp true
}

ldap_install(){
   if [[ -n "${verbose}" ]]; then echo "${MESSAGE_PREFIX} - Install"; fi

   
debconf-set-selections <<EOF
slapd slapd/password1 password ${ldapAdminPassword}
slapd slapd/password2 password ${ldapAdminPassword}
slapd slapd/domain string ${ldapDomain}
slapd shared/organization string ${ldapOrganization}
EOF
   apt-get install -y --no-install-recommends slapd ldap-utils
   
}

ldap_configure(){
   if [[ -n "${verbose}" ]]; then echo "${MESSAGE_PREFIX} - Configuration setting"; fi
 # set right name and IP in /etc/hosts file
   sed -i /${vmHostname}/d /etc/hosts
   sed -i s/$(cat /etc/hosts | grep ubuntu | cut -f2)/${vmHostname}/g /etc/hosts
   sudo bash -c "echo $vmIP $vmHostname $vmHostname >> /etc/hosts"

   ldapadd -D ${DIT_admin_dn} -w ${ldapAdminPassword} <<EOF
dn: ou=Users,${DIT_domain_dn}
objectClass: organizationalUnit
ou: Users
description: Company employes
EOF
}

services_restart() {
   if [[ -n "${verbose}" ]]; then echo "${MESSAGE_PREFIX} - Restart service"; fi
   sudo systemctl daemon-reload
   sudo systemctl restart sshd
   sudo systemctl restart systemd-timesyncd 
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
      echo "Domain : ${ldapDomain}"
      echo "Organization : ${ldapOrganization}"
      echo "Admin password : ${ldapAdminPassword}"
   fi

   mkdir -p $LOG_DIRECTORY
   touch $LOG_FILE

   linux_update
   common_install
   ssh_setting
   ldap_install
   if [[ -n "${ntpIP}" ]]; then ntp_setting; fi
   ldap_configure
   services_restart
}

main