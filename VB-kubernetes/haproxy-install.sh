#!/bin/bash

################################################################################
# FILE NAME   : haproxy-install.sh
# FILE TYPE   : BASH
# VERSION     : 210627-0939
# ARGS        : NO
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@hotmail.com
#
# DESCRIPTION : Haproxy installation
################################################################################

###################################################################### VARIABLES

###################################################################### FUNCTIONS
haproxy_package_install(){
   echo "HAPROXY - Common Linux packages install"
   sudo apt-get install -y -qq git vim tree net-tools telnet python3-pip sshpass nfs-common > /dev/null 2>&1
}

haproxy_install(){
   echo "HAPROXY - HaProxy install"
   sudo apt-get install -y haproxy > /dev/null 2>&1
}

haproxy_setting(){
   echo "HAPROXY - Create configuration file"
   echo "
   global
      log     127.0.0.1 local2
	  	chroot      /var/lib/haproxy
      pidfile     /var/run/haproxy.pid
      maxconn 4000
      user haproxy
      group haproxy
	   daemon
      stats socket /var/lib/haproxy/stats
   defaults
      mode http
		log global
      option httplog
      option dontlognull
      option http-server-close
      option forwardfor except 127.0.0.0/8
      option redispatch
      retries 3
      timeout http-request		10s
      timeout queue        	1m
		timeout connect      	10s
      timeout client       	1m
      timeout server  			1m
		timeout http-keep-alive	10s
		maxconn 3000
   listen stats
      bind *:9000
      stats enable
      stats uri /stats
      stats refresh 2s
      stats auth pedsf:password			
   listen kubernetes-apiserver-https
      bind *:6443
      mode tcp
      option log-health-checks
      timeout client 3h
      timeout server 3h
      balance roundrobin
   "> /etc/haproxy/haproxy.cfg

   echo "HAPROXY - Add masters to configuration file"
   for srv in $(cat /etc/hosts | grep k8s-master | awk '{print $2}'); do 
      echo "    server "$srv" "$srv":6443 check check-ssl verify none inter 10000">>/etc/haproxy/haproxy.cfg
   done

   echo "
   listen kubernetes-ingress
      bind *:80
      mode tcp
      option log-health-checks
   ">> /etc/haproxy/haproxy.cfg
   
   echo "HAPROXY - Add workers to configuration file"
   for srv in $(cat /etc/hosts | grep k8s-worker | awk '{print $2}'); do 
      echo "    server "$srv" "$srv":80 check">>/etc/haproxy/haproxy.cfg
   done   
}

haproxy_ssh_setting(){
   echo "HAPROXY - SSH setting"
   sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
   sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
}

haproxy_others_setting(){
   echo "HAPROXY - Others settings"
   sudo echo "autocmd filetype yaml setlocal ai ts=2 sw=2 et" > /home/vagrant/.vimrc
}

haproxy_reload(){
   echo "HAPROXY - Services restart"
   sudo systemctl restart sshd
   sudo systemctl reload haproxy
}

########################################################################### MAIN
main() {
   haproxy_package_install
   haproxy_install
   haproxy_setting
   haproxy_ssh_setting
   haproxy_others_setting
   haproxy_reload
}

main