#!/bin/bash

################################################################################
# FILE NAME   : deploy-install.sh
# FILE TYPE   : BASH
# VERSION     : 210620-0943
# ARGS        : y : for installing NGINX 
#
# AUTHOR      : PEDSF
# EMAIL       : pedsf.fullstack@gmail.com
#
# DESCRIPTION : K8s and ingress controller installation if required
################################################################################

###################################################################### VARIABLES
if [[ "$1" == "y" ]]; then
   INGRESS="NGINX"
fi

IP_HAPROXY=$(dig +short k8s-haproxy)
IP_KMASTER=$(dig +short k8s-master)
IP_KWORKER=$(dig +short k8s-worker)


###################################################################### FUNCTIONS

prepare_kubespray(){
   echo "DEPLOY - Git clone Kubespray"
   git clone https://github.com/kubernetes-sigs/kubespray.git
   chown -R vagrant /home/vagrant/kubespray
   
   echo "DEPLOY - Install Kubespray requirements"
   pip3 install --quiet -r kubespray/requirements.txt
   
   echo -e 'export PATH="$PATH:/$HOME/.local/bin"' >> $HOME/.bashrc

   echo "DEPLOY - ANSIBLE : Copy sample inventory"
   cp -rfp kubespray/inventory/sample kubespray/inventory/mykub
   
   echo "DEPLOY - ANSIBLE : Change inventory"
   cat /etc/hosts | grep k8s-master | awk '{print $2" ansible_host="$1" ip="$1" etcd_member_name=etcd"NR}' >kubespray/inventory/mykub/inventory.ini
   cat /etc/hosts | grep k8s-worker | awk '{print $2" ansible_host="$1" ip="$1}' >>kubespray/inventory/mykub/inventory.ini
   
   echo "[kube-master]">>kubespray/inventory/mykub/inventory.ini
   cat /etc/hosts | grep k8s-master | awk '{print $2}'>>kubespray/inventory/mykub/inventory.ini
   
   echo "[etcd]">>kubespray/inventory/mykub/inventory.ini
   cat /etc/hosts | grep k8s-master | awk '{print $2}'>>kubespray/inventory/mykub/inventory.ini
   
   echo "[kube-worker]">>kubespray/inventory/mykub/inventory.ini
   cat /etc/hosts | grep k8s-worker | awk '{print $2}'>>kubespray/inventory/mykub/inventory.ini
   
   echo "[calico-rr]">>kubespray/inventory/mykub/inventory.ini
   echo "[k8s-cluster:children]">>kubespray/inventory/mykub/inventory.ini
   echo "kube-master">>kubespray/inventory/mykub/inventory.ini
   echo "kube-worker">>kubespray/inventory/mykub/inventory.ini
   echo "calico-rr">>kubespray/inventory/mykub/inventory.ini

   if [[ "$INGRESS" == "NGINX" ]]; then
      echo
      echo "DEPLOY - ANSIBLE : active ingress controller nginx"  
      sed -i s/"ingress_nginx_enabled: false"/"ingress_nginx_enabled: true"/g kubespray/inventory/mykub/group_vars/k8s_cluster/addons.yml
      sed -i s/"# ingress_nginx_host_network: false"/"ingress_nginx_host_network: true"/g kubespray/inventory/mykub/group_vars/k8s_cluster/addons.yml
      sed -i s/"# ingress_nginx_nodeselector:"/"ingress_nginx_nodeselector: true"/g kubespray/inventory/mykub/group_vars/k8s_cluster/addons.yml
      sed -i s/"#   kubernetes.io\/os: \"linux\""/"kubernetes.io\/os: \"linux\""/g kubespray/inventory/mykub/group_vars/k8s_cluster/addons.yml
      sed -i s/"# ingress_nginx_namespace: \"ingress-nginx\""/"ingress_nginx_namespace: \"ingress-nginx\""/g kubespray/inventory/mykub/group_vars/k8s_cluster/addons.yml
      sed -i s/"# ingress_nginx_insecure_port: 80"/"ingress_nginx_insecure_port: 80"/g kubespray/inventory/mykub/group_vars/k8s_cluster/addons.yml
      sed -i s/"# ingress_nginx_secure_port: 443"/"ingress_nginx_insecure_port: 443"/g kubespray/inventory/mykub/group_vars/k8s_cluster/addons.yml
   fi

   echo
   echo "DEPLOY - ANSIBLE : active external load balancer"
   sed -i s/"## apiserver_loadbalancer_domain_name: \"elb.some.domain\""/"apiserver_loadbalancer_domain_name: \"autoelb.kub\""/g kubespray/inventory/mykub/group_vars/all/all.yml  
   sed -i s/"# loadbalancer_apiserver:"/"loadbalancer_apiserver:"/g kubespray/inventory/mykub/group_vars/all/all.yml  
   sed -i s/"#   address: 1.2.3.4"/"   address: ${IP_HAPROXY}"/g kubespray/inventory/mykub/group_vars/all/all.yml  
   sed -i s/"#   port: 1234"/"   port: 6443"/g kubespray/inventory/mykub/group_vars/all/all.yml  
}

create_ssh_for_kubespray() {
   echo
   echo "DEPLOY - SSH : generate key and push public key to others nodes"
   sudo -u vagrant bash -c "ssh-keygen -b 2048 -t rsa -f .ssh/id_rsa -q -N ''"
   for srv in $(cat /etc/hosts | grep -v haproxy | grep k8s | awk '{print $2}'); do
      cat /home/vagrant/.ssh/id_rsa.pub | sshpass -p 'vagrant' ssh -o StrictHostKeyChecking=no vagrant@$srv -T 'tee -a >> /home/vagrant/.ssh/authorized_keys'
   done
}

run_kubespray() {
   echo
   echo "DEPLOY - ANSIBLE : Run kubespray"
   sudo su - vagrant bash -c "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i kubespray/inventory/mykub/inventory.ini -b -u vagrant kubespray/cluster.yml"
}

install_kubectl() {
   echo
   echo "DEPLOY - KUBECTL : install"
   apt-get update && sudo apt-get install -y apt-transport-https > /dev/null 2>&1
   curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
   echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
   apt-get update > /dev/null 2>&1
   apt-get install -qq -y kubectl > /dev/null 2>&1
   mkdir -p /home/vagrant/.kube
   sudo chown -R vagrant /home/vagrant/.kube

   echo
   echo "DEPLOY - KUBECTL : copy cert on each master"
   for srv in $(cat /etc/hosts | grep k8s-master | awk '{print $2}'); do
      ssh -o StrictHostKeyChecking=no -i /home/vagrant/.ssh/id_rsa vagrant@$srv "sudo cat /etc/kubernetes/admin.conf" >> /home/vagrant/.kube/config
   done
}


########################################################################### MAIN
main() {
   prepare_kubespray
   create_ssh_for_kubespray
   run_kubespray
   install_kubectl
}

main