#!/bin/bash

## Install Flannel package
sudo yum install wget -y  >/dev/null 2>&1
wget https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz >/dev/null 2>&1
tar -zxvf cni-plugins-linux-amd64-v0.8.6.tgz >/dev/null 2>&1
sudo cp flannel /opt/cni/bin/ >/dev/null 2>&1

# Join worker nodes to the Kubernetes cluster
echo "[TASK 1] Join node to Kubernetes Cluster"
yum install -q -y sshpass >/dev/null 2>&1
sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster.example.com:/joincluster.sh /joincluster.sh 2>/dev/null
bash /joincluster.sh >/dev/null 2>&1

