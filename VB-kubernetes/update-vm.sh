#!/bin/bash

################################################################################
# FILE NAME   : update-vm.sh
# FILE TYPE   : BASH
# VERSION     : 210627-0939
# ARGS        : NO
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@hotmail.com
#
# DESCRIPTION : Update and upgrade linux
################################################################################

###################################################################### VARIABLES

###################################################################### FUNCTIONS
update(){
   echo "VM - Linux update and upgrade"
   sudo apt-get update  > /dev/null 2>&1
   sudo apt-get upgrade -y  > /dev/null 2>&1
}

########################################################################### MAIN
main() {
   update
}

main