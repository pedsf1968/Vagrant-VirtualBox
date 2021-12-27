#!/bin/bash

################################################################################
# FILE NAME   : nfs-install.sh
# FILE TYPE   : BASH
# VERSION     : 210627-0939
# ARGS        : NO
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@hotmail.com
#
# DESCRIPTION : NFS installation
################################################################################

###################################################################### VARIABLES
IP_RANGE=$(dig +short k8s-haproxy | sed s/".[0-9]*$"/.0/g)


###################################################################### FUNCTIONS
nfs_prepare_directories(){
   echo
   echo "NFS - prepare"
   sudo mkdir -p /srv/wordpress/{db,files}
   sudo chmod 777 -R /srv/wordpress/
}

nfs_package_install(){
   echo
   echo "NFS - install"
   sudo apt install -y nfs-kernel-server > /dev/null 2>&1
}

nfs_exports_configuration(){
   echo
   echo "NFS - exports setting"
   sudo bash -c "echo '/srv/wordpress/db '$IP_RANGE'/24(rw,sync,no_root_squash,no_subtree_check)' >> /etc/exports"
   sudo bash -c "echo '/srv/wordpress/files '$IP_RANGE'/24(rw,sync,no_root_squash,no_subtree_check)' >> /etc/exports"
}

nfs_restart() {
   echo
   echo "NFS - service restart"
   sudo systemctl restart nfs-server rpcbind
   sudo exportfs -a
}

########################################################################### MAIN
main() {
   nfs_prepare_directories
   nfs_package_install
   #nfs_exports_configuration
   #nfs_restart
}

main