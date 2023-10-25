
    2  systemctl disable firewalld; systemctl stop firewalld
    3  swapoff -a; sed -i '/swap/d' /etc/fstab
    4  setenforce 0
    5  sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
    6  cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

    7  sysctl --system
    8  yum install -y yum-utils device-mapper-persistent-data lvm2
    9  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
   10  yum install -y docker-ce-18.09.7
   11  systemctl enable --now docker
   12  docker ps
   13  docker version
   14  cat >>/etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

   15  yum install -y kubeadm-1.15.12-0 kubelet-1.15.12-0 kubectl-1.15.12-0
   16  systemctl enable --now kubelet
   17  ip add
   18  ip route
   19  kubeadm init --apiserver-advertise-address=10.0.2.15 --pod-network-cidr=192.168.0.0/16
   20  k get pod
   21  sudo yum -y install bash-completion
   22  source <(kubectl completion bash)
   23  echo "source <(kubectl completion bash)" >> ~/.bashrc
   24  sudo systemctl enable docker.service
   25  sudo systemctl enable kubelet.service
   26    mkdir -p $HOME/.kube
   27    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   28    sudo chown $(id -u):$(id -g) $HOME/.kube/config
   29  kubectl get node
====================================================================================
systemctl disable firewalld; systemctl stop firewalld

yum install -y kubeadm-1.15.12-0 kubelet-1.15.12-0 kubectl-1.15.12-0

kubeadm init --apiserver-advertise-address=10.0.2.15 --pod-network-cidr=192.168.0.0/16
kubeadm init --pod-network-cidr=10.244.0.0/16

sudo yum -y install bash-completion
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
====================================================================================
## Set Up Pod Network with Fannel using Old Document refer:
https://github.com/flannel-io/flannel/blob/master/Documentation/kubernetes.md

sudo kubectl apply -f https://github.com/flannel-io/flannel/blob/master/Documentation/kube-flannel-old.yaml

## Fixed Issue CoreDNS Pending can't run :
```
  Warning  FailedScheduling        9m12s (x154 over 34m)  default-scheduler    0/1 nodes are available: 1 node(s) had taints that the pod didn't tolerate.
  Warning  FailedCreatePodSandBox  6m31s                  kubelet, kubemaster  Failed create pod sandbox: rpc error: code = Unknown desc = [failed to set up sandbox container "c47b8f94181f6c86509a01e194e51e2e37c9e3bd450cee95f6165b9c898d00e6" network for pod "coredns-5d4dd4b4db-6nbgp": NetworkPlugin cni failed to set up pod "coredns-5d4dd4b4db-6nbgp_kube-system" network: failed to find plugin "flannel" in path [/opt/cni/bin], failed to clean up sandbox container "c47b8f94181f6c86509a01e194e51e2e37c9e3bd450cee95f6165b9c898d00e6" network for pod "coredns-5d4dd4b4db-6nbgp": NetworkPlugin cni failed to teardown pod "coredns-5d4dd4b4db-6nbgp_kube-system" network: failed to find plugin "flannel" in path [/opt/cni/bin]]
  Normal   SandboxChanged          72s (x25 over 6m30s)   kubelet, kubemaster  Pod sandbox changed, it will be killed and re-created.
```
## Solution: 
```
https://github.com/containernetworking/plugins/releases/tag/v0.8.6

wget https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz
tar -zxvf cni-plugins-linux-amd64-v0.8.6.tgz
cp flannel /opt/cni/bin/
```
====================================================================================

kubectl create -f https://gist.githubusercontent.com/sdenel/1bd2c8b5975393ababbcff9b57784e82/raw/f1b885349ba17cb2a81ca3899acc86c6ad150eb1/nginx-hello-world-deployment.yaml

[root@kubemaster ~]# k get pod 
NAME                    READY   STATUS    RESTARTS   AGE
nginx-8d4c546f5-55bq9   1/1     Running   0          39s
[root@kubemaster ~]# k get svc
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP        56m
nginx        NodePort    10.96.95.169   <none>        80:30001/TCP   43s
[root@kubemaster ~]# 

curl 192.168.56.2:30001
Hello world!

#### How to upgrade step ####
yum list --showduplicates kubeadm --disableexcludes=kubernetes
yum install -y kubeadm-1.16.15-0 --disableexcludes=kubernetes
kubeadm version
kubectl get node
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.16.15
kubectl get node
cat /etc/cni/net.d/10-flannel.conflist
{
  "name": "cbr0",
  "cniVersion": "0.3.1",
  "plugins": [
    {
      "type": "flannel",
      "delegate": {
        "hairpinMode": true,
        "isDefaultGateway": true
      }
    },
    {
      "type": "portmap",
      "capabilities": {
        "portMappings": true
      }
    }
  ]
}
sudo kubeadm upgrade apply
sudo kubeadm upgrade node
kubectl get node
yum install -y kubelet-1.16.15-0 kubectl-1.16.15-0 --disableexcludes=kubernetes
kubectl drain $MASTER --ignore-daemonsets
kubelet version
sudo systemctl restart kubelet
systemctl daemon-reload


[root@kubemaster vagrant]# /opt/cni/bin/flannel --version
CNI flannel plugin v0.8.6
[root@kubemaster vagrant]#
