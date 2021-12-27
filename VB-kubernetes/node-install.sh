#!/bin/bash

################################################################################
# FILE NAME   : node-install.sh
# FILE TYPE   : BASH
# VERSION     : 210627-0939
# ARGS        : NO
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@hotmail.com
#
# DESCRIPTION : Node installation
################################################################################

###################################################################### VARIABLES

###################################################################### FUNCTIONS
node_package_install(){
   echo "NODE - Common Linux packages install"
   sudo apt-get install -y -qq git vim tree net-tools telnet python3-pip sshpass nfs-common > /dev/null 2>&1
}

node_docker_install(){
   echo "NODE - Docker install"
   curl -fsSL https://get.docker.com -o get-docker.sh > /dev/null 2>&1
   sudo sh get-docker.sh > /dev/null 2>&1
}

node_docker_setting(){
   echo "NODE - setting"
   sudo usermod -aG docker vagrant
   sudo service docker start
}

node_ssh_setting(){
   echo "NODE - SSH setting"
   sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
   sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
}

node_others_setting(){
   echo "NODE - Others settings"
   sudo echo "autocmd filetype yaml setlocal ai ts=2 sw=2 et" > /home/vagrant/.vimrc
}

node_reload() {
   echo "NODE - restart sshd"
   sudo systemctl restart sshd
}


########################################################################### MAIN
main() {
   node_package_install
   node_docker_install
   node_docker_setting
   node_ssh_setting
   node_others_setting
   node_reload
}

main