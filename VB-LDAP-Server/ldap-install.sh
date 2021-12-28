################################################################################
# FILE NAME   : ldap-install.sh
# FILE TYPE   : BASH
# VERSION     : 211227
# ARGS        
# --verbose                    : Verbose installation
# --logprefix LOG_PREFIX       : Specify prefix of log message
# --logdirectory LOG_DIRECTORY : Specify the directory of installation log file
# --logfile LOG_FILE           : Specify the installation log file name
#
# --hostname VM_HOSTNAME       : Specify a hostname for the VM
# --ip VM_IP                   : Specify an IP for the VM
# --managementip MANAGEMENT_IP : Specify the management IP
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
LOG_PREFIX="LDAP"
LOG_DIRECTORY="/home/vagrant/logs"
LOG_FILE="ldap.log"

VM_HOSTNAME="LDAP-server"
VM_IP="10.1.33.12"
LDAP_DOMAIN="mycompany.com"
LDAP_ORGANIZATION="mycompany"
LDAP_ADMIN_PWD="ldapAdmin"

MANAGEMENT_IP='.*'

###################################################################### VARIABLES
verbose=''
logPrefix=$LOG_PREFIX
logDirectory=$LOG_DIRECTORY
logFile=$LOG_FILE

ntpIP=$NTP_IP
networkTimezone=$NETWORK_TIMEZONE

vmHostname=$VM_HOSTNAME
vmIP=$VM_IP

managementIP=${MANAGEMENT_IP}
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
   --logprefix)
      shift
      logPrefix=$1;;
   --logdirectory)
      shift
      logDirectory=$1;;
   --logfile)
      shift
      logFile=$1;;
   --hostname)
      shift
      vmHostname=$1;;
   --ip)
      shift
      vmIP=$1;;
   --managementip)
      shift
      managementIP=$1;;
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
show_parameters(){
   echo "${logPrefix} - Parameters"
   echo "VERBOSE : ${verbose}"
   echo "Log directory : ${logDirectory}"
   echo "Log file : ${logFile}"
   echo "NTP IP : ${ntpIP}"
   echo "Network time zone : ${networkTimezone}"
   echo "Hostname : ${vmHostname}"
   echo "IP : ${vmIP}"
   echo "Management IP : ${managementIP}"
   echo "Organization : ${ldapOrganization}"
   echo "Admin password : ${ldapAdminPassword}"

}

ldap_install(){
   if [[ -n "${verbose}" ]]; then echo "${logPrefix} - Install"; fi
   
debconf-set-selections <<EOF
slapd slapd/password1 password ${ldapAdminPassword}
slapd slapd/password2 password ${ldapAdminPassword}
slapd slapd/domain string ${ldapDomain}
slapd shared/organization string ${ldapOrganization}
EOF
   apt-get install -y --no-install-recommends slapd ldap-utils >> ${logDirectory}/${logFile}
}

ldap_configure(){
   if [[ -n "${verbose}" ]]; then echo "${logPrefix} - Configuration setting"; fi
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
   if [[ -n "${verbose}" ]]; then echo "${logPrefix} - Restart service"; fi
   sudo systemctl daemon-reload >> ${logDirectory}/${logFile}
}

########################################################################### MAIN
main() {
   show_parameters >> ${logDirectory}/${logFile} 
   if [[ -n $verbose ]]; then
      show_parameters
   fi
   
   mkdir -p ${logDirectory}
   touch ${logDirectory}/${logFile}

   ldap_install
   ldap_configure
   services_restart
}

main