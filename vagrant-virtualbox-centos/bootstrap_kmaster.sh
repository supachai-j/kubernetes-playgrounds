#!/bin/bash

# Initialize Kubernetes
echo "[TASK 1] Initialize Kubernetes Cluster"
kubeadm init --apiserver-advertise-address=192.168.56.200 --pod-network-cidr=10.244.0.0/16 >> /root/kubeinit.log 2>/dev/null

# Copy Kube admin config
echo "[TASK 2] Copy kube admin config to Vagrant user .kube directory"
mkdir /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
echo "source <(kubectl completion bash)" >>  /home/vagrant/.bashrc
echo "alias k='kubectl'" >> /home/vagrant/.bashrc

# # Deploy flannel network
 echo "[TASK 3] Deploy flannel network"
# su - vagrant -c "kubectl create -f /vagrant/kube-flannel.yml"
su - vagrant -c "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-old-manifests/kube-flannel-legacy.yml" >/dev/null 2>&1
su - vagrant -c "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-old-manifests/kube-flannel-rbac.yml" >/dev/null 2>&1
su - vagrant -c "kubectl apply -f  https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel-old.yaml " >/dev/null 2>&1

## Install Flannel package
sudo yum install wget -y  >/dev/null 2>&1
wget https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz >/dev/null 2>&1
tar -zxvf cni-plugins-linux-amd64-v0.8.6.tgz >/dev/null 2>&1
sudo cp flannel /opt/cni/bin/ >/dev/null 2>&1

# Generate Cluster join command
echo "[TASK 4] Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh