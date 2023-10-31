``` 
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
``` 

```
systemctl disable firewalld; systemctl stop firewalld

yum install -y kubeadm-1.15.12-0 kubelet-1.15.12-0 kubectl-1.15.12-0

kubeadm init --apiserver-advertise-address=10.0.2.15 --pod-network-cidr=192.168.0.0/16
kubeadm init --pod-network-cidr=10.244.0.0/16

sudo yum -y install bash-completion
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc

```



### Set Up Pod Network with Fannel using Old Document refer:

Delete all the flannel resources using kubectl:
```
kubectl -n kube-flannel delete daemonset kube-flannel-ds
kubectl -n kube-flannel delete configmap kube-flannel-cfg
kubectl -n kube-flannel delete serviceaccount flannel
kubectl delete clusterrolebinding.rbac.authorization.k8s.io flannel
kubectl delete clusterrole.rbac.authorization.k8s.io flannel
kubectl delete namespace kube-flannel
```

## How to install Flannel old version for 1.15.x - 1.16.x
```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-old-manifests/kube-flannel-legacy.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-old-manifests/kube-flannel-rbac.yml
kubectl apply -f  https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel-old.yaml

kubectl delete -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-old-manifests/kube-flannel-legacy.yml

https://github.com/flannel-io/flannel/blob/master/Documentation/kubernetes.md

kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml

 sudo kubectl apply -f https://github.com/flannel-io/flannel/blob/master/Documentation/kube-flannel-old.yaml
```
### Fixed Issue CoreDNS Pending can't run :
```
  Warning  FailedScheduling        9m12s (x154 over 34m)  default-scheduler    0/1 nodes are available: 1 node(s) had taints that the pod didn't tolerate.
  Warning  FailedCreatePodSandBox  6m31s                  kubelet, kubemaster  Failed create pod sandbox: rpc error: code = Unknown desc = [failed to set up sandbox container "c47b8f94181f6c86509a01e194e51e2e37c9e3bd450cee95f6165b9c898d00e6" network for pod "coredns-5d4dd4b4db-6nbgp": NetworkPlugin cni failed to set up pod "coredns-5d4dd4b4db-6nbgp_kube-system" network: failed to find plugin "flannel" in path [/opt/cni/bin], failed to clean up sandbox container "c47b8f94181f6c86509a01e194e51e2e37c9e3bd450cee95f6165b9c898d00e6" network for pod "coredns-5d4dd4b4db-6nbgp": NetworkPlugin cni failed to teardown pod "coredns-5d4dd4b4db-6nbgp_kube-system" network: failed to find plugin "flannel" in path [/opt/cni/bin]]
  Normal   SandboxChanged          72s (x25 over 6m30s)   kubelet, kubemaster  Pod sandbox changed, it will be killed and re-created.

  
```
### Solution: 
```
https://github.com/containernetworking/plugins/releases/tag/v0.8.6

sudo yum install wget -y
wget https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz
tar -zxvf cni-plugins-linux-amd64-v0.8.6.tgz
sudo cp flannel /opt/cni/bin/

kubectl get pod -A

```

## Deployment Hello demo:
```
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

while :; do curl http://192.168.56.201:30001; echo ''; sleep 1; done
```
 
### How to Upgrade step ####
```
# yum list --showduplicates kubeadm --disableexcludes=kubernetes
# sudo yum install -y kubeadm-1.16.15-0 --disableexcludes=kubernetes
# kubeadm version
# kubectl get node
# sudo kubeadm upgrade plan
# sudo kubeadm upgrade apply v1.16.15
# kubectl get node
# cat /etc/cni/net.d/10-flannel.conflist
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
sudo yum install -y kubelet-1.16.15-0 kubectl-1.16.15-0 --disableexcludes=kubernetes
kubectl drain $MASTER --ignore-daemonsets
kubectl drain kmaster.example.com --ignore-daemonsets
[vagrant@kmaster ~]$ kubelet --version
Kubernetes v1.16.15
[vagrant@kmaster ~]$
[vagrant@kmaster ~]$ sudo systemctl restart kubelet
Warning: kubelet.service changed on disk. Run 'systemctl daemon-reload' to reload units.
[vagrant@kmaster ~]$
[vagrant@kmaster ~]$ sudo systemctl daemon-reload
[vagrant@kmaster ~]$
[vagrant@kmaster ~]$ k get node
NAME                   STATUS                     ROLES    AGE   VERSION
kmaster.example.com    Ready,SchedulingDisabled   master   34m   v1.16.15
kworker1.example.com   Ready                      <none>   32m   v1.15.12
[vagrant@kmaster ~]$
[vagrant@kmaster ~]$ kubectl uncordon kmaster.example.com 
node/kmaster.example.com uncordoned
[vagrant@kmaster ~]$ 
[vagrant@kmaster ~]$ k get node
NAME                   STATUS   ROLES    AGE   VERSION
kmaster.example.com    Ready    master   34m   v1.16.15
kworker1.example.com   Ready    <none>   32m   v1.15.12
[vagrant@kmaster ~]$ 

[root@kubemaster vagrant]# /opt/cni/bin/flannel --version
CNI flannel plugin v0.8.6
[root@kubemaster vagrant]#
```


## Upgrade worker nodes
```
sudo yum install -y kubeadm-1.16.15-0 --disableexcludes=kubernetes
sudo kubeadm upgrade node
kubectl drain  kworker1.example.com --ignore-daemonsets
sudo yum install -y kubelet-1.16.15-0 kubectl-1.16.15-0--disableexcludes=kubernetes
sudo systemctl restart kubelet
kubectl uncordon kworker1.example.com
kubectl get nodes
```
===================== Logs Kubernetes Upgrade step ======
```
[root@kmaster vagrant]# yum install -y kubeadm-1.16.15-0 --disableexcludes=kubernetes
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.thzhost.com
 * extras: mirrors.thzhost.com
 * updates: mirrors.thzhost.com
Resolving Dependencies
--> Running transaction check
---> Package kubeadm.x86_64 0:1.15.12-0 will be updated
---> Package kubeadm.x86_64 0:1.16.15-0 will be an update
--> Finished Dependency Resolution

Dependencies Resolved

===========================================================================================================================================
 Package                         Arch                           Version                           Repository                          Size
===========================================================================================================================================
Updating:
 kubeadm                         x86_64                         1.16.15-0                         kubernetes                         8.8 M

Transaction Summary
===========================================================================================================================================
Upgrade  1 Package

Total download size: 8.8 M
Downloading packages:
No Presto metadata available for kubernetes
c0dee0d6cbf2a2269e4d84f7c6e08849f80959a1c3b1425d26535df7b027d7d8-kubeadm-1.16.15-0.x86_64.rpm                       | 8.8 MB  00:00:04     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : kubeadm-1.16.15-0.x86_64                                                                                                1/2 
  Cleanup    : kubeadm-1.15.12-0.x86_64                                                                                                2/2 
  Verifying  : kubeadm-1.16.15-0.x86_64                                                                                                1/2 
  Verifying  : kubeadm-1.15.12-0.x86_64                                                                                                2/2 

Updated:
  kubeadm.x86_64 0:1.16.15-0                                                                                                               

Complete!
[root@kmaster vagrant]# kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"16", GitVersion:"v1.16.15", GitCommit:"2adc8d7091e89b6e3ca8d048140618ec89b39369", GitTreeState:"clean", BuildDate:"2020-09-02T11:37:34Z", GoVersion:"go1.13.15", Compiler:"gc", Platform:"linux/amd64"}
[root@kmaster vagrant]#

[vagrant@kmaster ~]$ kubectl get node
NAME                   STATUS   ROLES    AGE   VERSION
kmaster.example.com    Ready    master   23m   v1.15.12
kworker1.example.com   Ready    <none>   21m   v1.15.12
[vagrant@kmaster ~]$ kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"16", GitVersion:"v1.16.15", GitCommit:"2adc8d7091e89b6e3ca8d048140618ec89b39369", GitTreeState:"clean", BuildDate:"2020-09-02T11:37:34Z", GoVersion:"go1.13.15", Compiler:"gc", Platform:"linux/amd64"}
[vagrant@kmaster ~]$ sudo kubeadm upgrade plan
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[preflight] Running pre-flight checks.
[upgrade] Making sure the cluster is healthy:
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: v1.15.12
[upgrade/versions] kubeadm version: v1.16.15
I1026 07:15:34.683530   12550 version.go:251] remote version is much newer: v1.28.3; falling back to: stable-1.16
[upgrade/versions] Latest stable version: v1.16.15
[upgrade/versions] Latest version in the v1.15 series: v1.15.12

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   CURRENT        AVAILABLE
Kubelet     2 x v1.15.12   v1.16.15

Upgrade to the latest stable version:

COMPONENT            CURRENT    AVAILABLE
API Server           v1.15.12   v1.16.15
Controller Manager   v1.15.12   v1.16.15
Scheduler            v1.15.12   v1.16.15
Kube Proxy           v1.15.12   v1.16.15
CoreDNS              1.3.1      1.6.2
Etcd                 3.3.10     3.3.15-0

You can now apply the upgrade by executing the following command:

        kubeadm upgrade apply v1.16.15

_____________________________________________________________________

[vagrant@kmaster ~]$ 

[vagrant@kmaster ~]$ sudo kubeadm upgrade apply v1.16.15
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[preflight] Running pre-flight checks.
[upgrade] Making sure the cluster is healthy:
[upgrade/version] You have chosen to change the cluster version to "v1.16.15"
[upgrade/versions] Cluster version: v1.15.12
[upgrade/versions] kubeadm version: v1.16.15
[upgrade/confirm] Are you sure you want to proceed with the upgrade? [y/N]: y
[upgrade/prepull] Will prepull images for components [kube-apiserver kube-controller-manager kube-scheduler etcd]
[upgrade/prepull] Prepulling image for component etcd.
[upgrade/prepull] Prepulling image for component kube-apiserver.
[upgrade/prepull] Prepulling image for component kube-controller-manager.
[upgrade/prepull] Prepulling image for component kube-scheduler.
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-kube-apiserver
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-kube-controller-manager
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-etcd
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-etcd
[upgrade/prepull] Prepulled image for component kube-controller-manager.
[upgrade/prepull] Prepulled image for component kube-scheduler.
[upgrade/prepull] Prepulled image for component kube-apiserver.
[upgrade/prepull] Prepulled image for component etcd.
[upgrade/prepull] Successfully prepulled the images for all the control plane components
[upgrade/apply] Upgrading your Static Pod-hosted control plane to version "v1.16.15"...
Static pod: kube-apiserver-kmaster.example.com hash: 49aa273c129c8e09a654a9d8c6dd7108
Static pod: kube-controller-manager-kmaster.example.com hash: 62e6b0830ba7c30db160fb40851cccd0
Static pod: kube-scheduler-kmaster.example.com hash: 37bbbfb82a966a388adac318f32b758f
[upgrade/etcd] Upgrading to TLS for etcd
Static pod: etcd-kmaster.example.com hash: 72bfcb89206bda152b3b5cabc52e44d4
[upgrade/staticpods] Preparing for "etcd" upgrade
[upgrade/staticpods] Renewing etcd-server certificate
[upgrade/staticpods] Renewing etcd-peer certificate
[upgrade/staticpods] Renewing etcd-healthcheck-client certificate
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/etcd.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2023-10-26-07-16-46/etcd.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: etcd-kmaster.example.com hash: 72bfcb89206bda152b3b5cabc52e44d4
Static pod: etcd-kmaster.example.com hash: 72bfcb89206bda152b3b5cabc52e44d4
Static pod: etcd-kmaster.example.com hash: 98cf79993472f805a4819812a5388c50
[apiclient] Found 1 Pods for label selector component=etcd
[upgrade/staticpods] Component "etcd" upgraded successfully!
[upgrade/etcd] Waiting for etcd to become available
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests263345675"
[upgrade/staticpods] Preparing for "kube-apiserver" upgrade
[upgrade/staticpods] Renewing apiserver certificate
[upgrade/staticpods] Renewing apiserver-kubelet-client certificate
[upgrade/staticpods] Renewing front-proxy-client certificate
[upgrade/staticpods] Renewing apiserver-etcd-client certificate
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2023-10-26-07-16-46/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-apiserver-kmaster.example.com hash: 49aa273c129c8e09a654a9d8c6dd7108
Static pod: kube-apiserver-kmaster.example.com hash: 49aa273c129c8e09a654a9d8c6dd7108
Static pod: kube-apiserver-kmaster.example.com hash: 83d09b1a32f5ef0f69a1d0e58a2792da
[apiclient] Found 1 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-controller-manager" upgrade
[upgrade/staticpods] Renewing controller-manager.conf certificate
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2023-10-26-07-16-46/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-controller-manager-kmaster.example.com hash: 62e6b0830ba7c30db160fb40851cccd0
Static pod: kube-controller-manager-kmaster.example.com hash: 0f81268495dab6ed796eae5347711e04
[apiclient] Found 1 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-scheduler" upgrade
[upgrade/staticpods] Renewing scheduler.conf certificate
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2023-10-26-07-16-46/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-scheduler-kmaster.example.com hash: 37bbbfb82a966a388adac318f32b758f
Static pod: kube-scheduler-kmaster.example.com hash: 463b02139da48f3e55ac8f355ab95be1
[apiclient] Found 1 Pods for label selector component=kube-scheduler
[upgrade/staticpods] Component "kube-scheduler" upgraded successfully!
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.16" in namespace kube-system with the configuration for the kubelets in the cluster
[kubelet-start] Downloading configuration for the kubelet from the "kubelet-config-1.16" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.16.15". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
[vagrant@kmaster ~]$ kubectl get node
NAME                   STATUS   ROLES    AGE   VERSION
kmaster.example.com    Ready    master   29m   v1.15.12
kworker1.example.com   Ready    <none>   26m   v1.15.12
[vagrant@kmaster ~]$ 

```

## Upgrade worker nodes
```
sudo yum install -y kubeadm-1.16.15-0 --disableexcludes=kubernetes
sudo kubeadm upgrade node
kubectl drain  kworker1.example.com --ignore-daemonsets
sudo yum install -y kubelet-1.16.15-0 kubectl-1.16.15-0--disableexcludes=kubernetes
sudo systemctl restart kubelet
kubectl uncordon kworker1.example.com
kubectl get nodes
```

## How to master node using pod running 
```
[vagrant@kmaster ~]$ kubectl taint node kmaster.example.com node-role.kubernetes.io/master:NoSchedule-
node/kmaster.example.com untainted
[vagrant@kmaster ~]$ k get pod 
NAME                    READY   STATUS              RESTARTS   AGE
nginx-8d4c546f5-4z58m   0/1     ContainerCreating   0          77s
[vagrant@kmaster ~]
[vagrant@kmaster ~]$ k get pod -o wide
NAME                    READY   STATUS    RESTARTS   AGE     IP            NODE                  NOMINATED NODE   READINESS GATES
nginx-8d4c546f5-4z58m   1/1     Running   0          2m45s   10.244.0.12   kmaster.example.com   <none>           <none>
[vagrant@kmaster ~]$

    ~ ❯ while :; do curl http://192.168.56.200:30001; echo ''; sleep 1; done                                 ✘ INT   14:41:35
Hello world!
Hello world!
Hello world!
Hello world!
Hello world!
Hello world!
^C%
    ~ ❯ while :; do curl http://192.168.56.201:30001; echo ''; sleep 1; done                           ✘ INT   6s   14:41:42
curl: (7) Failed to connect to 192.168.56.201 port 30001 after 8 ms: Couldn't connect to server

curl: (7) Failed to connect to 192.168.56.201 port 30001 after 8 ms: Couldn't connect to server


===================== Logs upgrade Worker Nodes =================
[vagrant@kworker1 ~]$ sudo yum install -y kubeadm-1.16.15-0 --disableexcludes=kubernetes
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.thzhost.com
 * extras: mirrors.thzhost.com
 * updates: mirrors.thzhost.com
Resolving Dependencies
--> Running transaction check
---> Package kubeadm.x86_64 0:1.15.12-0 will be updated
---> Package kubeadm.x86_64 0:1.16.15-0 will be an update
--> Finished Dependency Resolution

Dependencies Resolved

===========================================================================================================================================
 Package                         Arch                           Version                           Repository                          Size
===========================================================================================================================================
Updating:
 kubeadm                         x86_64                         1.16.15-0                         kubernetes                         8.8 M

Transaction Summary
===========================================================================================================================================
Upgrade  1 Package

Total download size: 8.8 M
Downloading packages:
No Presto metadata available for kubernetes
c0dee0d6cbf2a2269e4d84f7c6e08849f80959a1c3b1425d26535df7b027d7d8-kubeadm-1.16.15-0.x86_64.rpm                       | 8.8 MB  00:00:05     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : kubeadm-1.16.15-0.x86_64                                                                                                1/2 
  Cleanup    : kubeadm-1.15.12-0.x86_64                                                                                                2/2 
  Verifying  : kubeadm-1.16.15-0.x86_64                                                                                                1/2 
  Verifying  : kubeadm-1.15.12-0.x86_64                                                                                                2/2 

Updated:
  kubeadm.x86_64 0:1.16.15-0                                                                                                               

Complete!
[vagrant@kworker1 ~]$ sudo kubeadm upgrade node
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[upgrade] Skipping phase. Not a control plane node[kubelet-start] Downloading configuration for the kubelet from the "kubelet-config-1.16" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[upgrade] The configuration for this node was successfully updated!
[upgrade] Now you should go ahead and upgrade the kubelet package using your package manager.
[vagrant@kworker1 ~]$ 
[vagrant@kworker1 ~]$ sudo yum install -y kubelet-1.16.15-0 kubectl-1.16.15-0--disableexcludes=kubernetes
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.thzhost.com
 * extras: mirrors.thzhost.com
 * updates: mirrors.thzhost.com
No package kubectl-1.16.15-0--disableexcludes=kubernetes available.
Resolving Dependencies
--> Running transaction check
---> Package kubelet.x86_64 0:1.15.12-0 will be updated
---> Package kubelet.x86_64 0:1.16.15-0 will be an update
--> Finished Dependency Resolution

Dependencies Resolved

===========================================================================================================================================
 Package                         Arch                           Version                           Repository                          Size
===========================================================================================================================================
Updating:
 kubelet                         x86_64                         1.16.15-0                         kubernetes                          20 M

Transaction Summary
===========================================================================================================================================
Upgrade  1 Package

Total download size: 20 M
Downloading packages:
No Presto metadata available for kubernetes
3696890bc43ba8aa59f4158b8f3fb23d6f99883d03867f99929c380dd40f99e1-kubelet-1.16.15-0.x86_64.rpm                       |  20 MB  00:00:07     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : kubelet-1.16.15-0.x86_64                                                                                                1/2 
  Cleanup    : kubelet-1.15.12-0.x86_64                                                                                                2/2 
  Verifying  : kubelet-1.16.15-0.x86_64                                                                                                1/2 
  Verifying  : kubelet-1.15.12-0.x86_64                                                                                                2/2 

Updated:
  kubelet.x86_64 0:1.16.15-0                                                                                                               

Complete!
[vagrant@kworker1 ~]$ sudo systemctl restart kubelet
Warning: kubelet.service changed on disk. Run 'systemctl daemon-reload' to reload units.
[vagrant@kworker1 ~]$ sudo systemctl daemon-reload
[vagrant@kworker1 ~]$

[vagrant@kmaster ~]$ k get node -o wide
NAME                   STATUS                     ROLES    AGE   VERSION    INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION           CONTAINER-RUNTIME
kmaster.example.com    Ready                      master   55m   v1.16.15   192.168.56.200   <none>        CentOS Linux 7 (Core)   3.10.0-1127.el7.x86_64   docker://18.9.7
kworker1.example.com   Ready,SchedulingDisabled   <none>   52m   v1.16.15   192.168.56.201   <none>        CentOS Linux 7 (Core)   3.10.0-1127.el7.x86_64   docker://18.9.7
[vagrant@kmaster ~]$

[vagrant@kmaster ~]$ kubectl uncordon kworker1.example.com
node/kworker1.example.com uncordoned
[vagrant@kmaster ~]$ kubectl get nodes
NAME                   STATUS   ROLES    AGE   VERSION
kmaster.example.com    Ready    master   55m   v1.16.15
kworker1.example.com   Ready    <none>   53m   v1.16.15
[vagrant@kmaster ~]$ 
[vagrant@kmaster ~]$ kubectl get nodes -o wide
NAME                   STATUS   ROLES    AGE   VERSION    INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION           CONTAINER-RUNTIME
kmaster.example.com    Ready    master   55m   v1.16.15   192.168.56.200   <none>        CentOS Linux 7 (Core)   3.10.0-1127.el7.x86_64   docker://18.9.7
kworker1.example.com   Ready    <none>   53m   v1.16.15   192.168.56.201   <none>        CentOS Linux 7 (Core)   3.10.0-1127.el7.x86_64   docker://18.9.7
[vagrant@kmaster ~]$


[vagrant@kmaster ~]$ k get pod -o wide
NAME                    READY   STATUS    RESTARTS   AGE     IP            NODE                  NOMINATED NODE   READINESS GATES
nginx-8d4c546f5-4z58m   1/1     Running   0          9m22s   10.244.0.12   kmaster.example.com   <none>           <none>
[vagrant@kmaster ~]$ kubectl edit deployments.apps nginx 
deployment.apps/nginx edited
[vagrant@kmaster ~]$ k get pod -o wide
NAME                    READY   STATUS              RESTARTS   AGE     IP            NODE                   NOMINATED NODE   READINESS GATES
nginx-8d4c546f5-4z58m   1/1     Running             0          9m44s   10.244.0.12   kmaster.example.com    <none>           <none>
nginx-8d4c546f5-zs5cg   0/1     ContainerCreating   0          2s      <none>        kworker1.example.com   <none>           <none>
[vagrant@kmaster ~]$ k get pod -o wide
NAME                    READY   STATUS    RESTARTS   AGE     IP            NODE                   NOMINATED NODE   READINESS GATES
nginx-8d4c546f5-4z58m   1/1     Running   0          9m53s   10.244.0.12   kmaster.example.com    <none>           <none>
nginx-8d4c546f5-zs5cg   1/1     Running   0          11s     10.244.1.5    kworker1.example.com   <none>           <none>
[vagrant@kmaster ~]$ 
```

