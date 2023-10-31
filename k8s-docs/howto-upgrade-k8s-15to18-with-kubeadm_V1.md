# How To Upgrade Kubernetes 1.15.x to 1.18.x on CentOS7

This page explains how to upgrade a Kubernetes cluster created with kubeadm from version 1.15.x to version 1.16.x, and from version 1.16.x to 1.18.y

### The Upgrade Workflow at high level is the following:

- Upgrade the primary control plane node.
- Upgrade additional control plane nodes.
- Upgrade worker nodes.

### Mock POC Kubenetes Setup Labs
- Master Node x 1 node.
- Worker Node x 1 node.
- OS CentOS 7 64bits (Kernel: 3.10.0-1127.el7.x86_64)
- Kubenetes v1.15.12
- Docker version => 18.09.7
- CNI flannel plugin v0.8.6 (flannel:v0.11.0-amd64)


### The Setup

The kubernetes cluster is running with 1- Master and 1 Worker node with the v1.15.0 our traget is get this cluster to v1.18.2 version. The enviroment is running on ubuntu platform, for centos family only the repository will chnage the concept will remain the same.
```
[vagrant@kmaster ~]$ kubectl get nodes
NAME                   STATUS   ROLES    AGE   VERSION
kmaster.example.com    Ready    master   61m   v1.15.12
kworker1.example.com   Ready    <none>   57m   v1.15.12
[vagrant@kmaster ~]$ 
```
```
[vagrant@kmaster ~]$  kubectl version
Client Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.12", GitCommit:"e2a822d9f3c2fdb5c9bfbe64313cf9f657f0a725", GitTreeState:"clean", BuildDate:"2020-05-06T05:17:59Z", GoVersion:"go1.12.17", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.12", GitCommit:"e2a822d9f3c2fdb5c9bfbe64313cf9f657f0a725", GitTreeState:"clean", BuildDate:"2020-05-06T05:09:48Z", GoVersion:"go1.12.17", Compiler:"gc", Platform:"linux/amd64"}
[vagrant@kmaster ~]$ 
[vagrant@kmaster ~]$ kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.12", GitCommit:"e2a822d9f3c2fdb5c9bfbe64313cf9f657f0a725", GitTreeState:"clean", BuildDate:"2020-05-06T05:15:30Z", GoVersion:"go1.12.17", Compiler:"gc", Platform:"linux/amd64"}
[vagrant@kmaster ~]$ 
```
```
[vagrant@kworker1 ~]$ kubectl version
Client Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.12", GitCommit:"e2a822d9f3c2fdb5c9bfbe64313cf9f657f0a725", GitTreeState:"clean", BuildDate:"2020-05-06T05:17:59Z", GoVersion:"go1.12.17", Compiler:"gc", Platform:"linux/amd64"}
The connection to the server localhost:8080 was refused - did you specify the right host or port?
[vagrant@kworker1 ~]$ 
[vagrant@kworker1 ~]$ kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.12", GitCommit:"e2a822d9f3c2fdb5c9bfbe64313cf9f657f0a725", GitTreeState:"clean", BuildDate:"2020-05-06T05:15:30Z", GoVersion:"go1.12.17", Compiler:"gc", Platform:"linux/amd64"}
[vagrant@kworker1 ~]$ 
```

### 1. Error message "[ERROR CoreDNSUnsupportedPlugins]: there are unsupported plugins in the CoreDNS Corefile"
```
$ kubeadm upgrade plan
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[preflight] Running pre-flight checks.
[preflight] Some fatal errors occurred:
	[ERROR CoreDNSUnsupportedPlugins]: there are unsupported plugins in the CoreDNS Corefile
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
To see the stack trace of this error execute with --v=5 or higher
$
$ kubectl -n kube-system get cm coredns -oyaml
apiVersion: v1
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           upstream
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        proxy . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
kind: ConfigMap
metadata:
  creationTimestamp: "2019-02-24T17:26:14Z"
  name: coredns
  namespace: kube-system
  resourceVersion: "210"
  selfLink: /api/v1/namespaces/kube-system/configmaps/coredns
  uid: 491a7893-3859-11e9-916c-005056af9870
$
```
#### How to Fixed Issue CoreDNS Unsupport Plugins:
Change configuration ``proxy . /etc/resolv.conf`` to ``forward . /etc/resolv.conf`` 
```
$ kubectl -n kube-system edit cm coredns
apiVersion: v1
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           upstream
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
```

### 2. Error message from CoreDNS Pending can't run :
```
$ kubectl describe -n kube-system pod coredns-5d4dd4b4db-6nbgp 
.....
  Warning  FailedScheduling        9m12s (x154 over 34m)  default-scheduler    0/1 nodes are available: 1 node(s) had taints that the pod didn't tolerate.
  Warning  FailedCreatePodSandBox  6m31s                  kubelet, kubemaster  Failed create pod sandbox: rpc error: code = Unknown desc = [failed to set up sandbox container "c47b8f94181f6c86509a01e194e51e2e37c9e3bd450cee95f6165b9c898d00e6" network for pod "coredns-5d4dd4b4db-6nbgp": NetworkPlugin cni failed to set up pod "coredns-5d4dd4b4db-6nbgp_kube-system" network: failed to find plugin "flannel" in path [/opt/cni/bin], failed to clean up sandbox container "c47b8f94181f6c86509a01e194e51e2e37c9e3bd450cee95f6165b9c898d00e6" network for pod "coredns-5d4dd4b4db-6nbgp": NetworkPlugin cni failed to teardown pod "coredns-5d4dd4b4db-6nbgp_kube-system" network: failed to find plugin "flannel" in path [/opt/cni/bin]]
  Normal   SandboxChanged          72s (x25 over 6m30s)   kubelet, kubemaster  Pod sandbox changed, it will be killed and re-created.
......
```
#### How to Fixed Issue CoreDNS Pending can't run : 
```
#https://github.com/containernetworking/plugins/releases/tag/v0.8.6

$ sudo yum install wget -y
$ wget https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz
$ cd ~
$ tar -zxvf cni-plugins-linux-amd64-v0.8.6.tgz
$ sudo cp flannel /opt/cni/bin/
$ /opt/cni/bin/flannel --version
CNI flannel plugin v0.8.6
$
$ kubectl get pod -A
$
```

## Upgrade v1.15.x-v.1.16.x
### Master Node - upgrade kubeadm
```
[vagrant@kmaster ~]$ yum list --showduplicates kubeadm --disableexcludes=kubernetes
# find the latest 1.16 version in the list
# it should look like 1.16.x-0, where x is the latest patch
kubeadm.x86_64  1.16.15-0      kubernetes 
[vagrant@kmaster ~]$
[vagrant@kmaster ~]$ sudo yum install -y kubeadm-1.16.15-0 --disableexcludes=kubernetes
[vagrant@kmaster ~]$
[vagrant@kmaster ~]$ kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"16", GitVersion:"v1.16.15", GitCommit:"2adc8d7091e89b6e3ca8d048140618ec89b39369", GitTreeState:"clean", BuildDate:"2020-09-02T11:37:34Z", GoVersion:"go1.13.15", Compiler:"gc", Platform:"linux/amd64"}
[vagrant@kmaster ~]$
[vagrant@kmaster ~]$ 
[vagrant@kmaster ~]$ sudo kubeadm upgrade plan
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[preflight] Running pre-flight checks.
[upgrade] Making sure the cluster is healthy:
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: v1.15.12
[upgrade/versions] kubeadm version: v1.16.15
I1030 05:13:40.668964   14251 version.go:251] remote version is much newer: v1.28.3; falling back to: stable-1.16
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
[vagrant@kmaster ~]$ kubeadm upgrade apply v1.16.15
couldn't create a Kubernetes client from file "/etc/kubernetes/admin.conf": failed to load admin kubeconfig: open /etc/kubernetes/admin.conf: permission denied
To see the stack trace of this error execute with --v=5 or higher
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
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-etcd
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-kube-apiserver
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-kube-controller-manager
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-etcd
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[upgrade/prepull] Prepulled image for component kube-controller-manager.
[upgrade/prepull] Prepulled image for component kube-apiserver.
[upgrade/prepull] Prepulled image for component etcd.
[upgrade/prepull] Prepulled image for component kube-scheduler.
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
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/etcd.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2023-10-30-14-48-18/etcd.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: etcd-kmaster.example.com hash: 72bfcb89206bda152b3b5cabc52e44d4
Static pod: etcd-kmaster.example.com hash: 72bfcb89206bda152b3b5cabc52e44d4
Static pod: etcd-kmaster.example.com hash: 98cf79993472f805a4819812a5388c50
[apiclient] Found 1 Pods for label selector component=etcd
[upgrade/staticpods] Component "etcd" upgraded successfully!
[upgrade/etcd] Waiting for etcd to become available
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests030827669"
[upgrade/staticpods] Preparing for "kube-apiserver" upgrade
[upgrade/staticpods] Renewing apiserver certificate
[upgrade/staticpods] Renewing apiserver-kubelet-client certificate
[upgrade/staticpods] Renewing front-proxy-client certificate
[upgrade/staticpods] Renewing apiserver-etcd-client certificate
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2023-10-30-14-48-18/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-apiserver-kmaster.example.com hash: 49aa273c129c8e09a654a9d8c6dd7108
Static pod: kube-apiserver-kmaster.example.com hash: 49aa273c129c8e09a654a9d8c6dd7108
Static pod: kube-apiserver-kmaster.example.com hash: 83d09b1a32f5ef0f69a1d0e58a2792da
[apiclient] Found 1 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-controller-manager" upgrade
[upgrade/staticpods] Renewing controller-manager.conf certificate
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2023-10-30-14-48-18/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-controller-manager-kmaster.example.com hash: 62e6b0830ba7c30db160fb40851cccd0
Static pod: kube-controller-manager-kmaster.example.com hash: 0f81268495dab6ed796eae5347711e04
[apiclient] Found 1 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-scheduler" upgrade
[upgrade/staticpods] Renewing scheduler.conf certificate
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2023-10-30-14-48-18/kube-scheduler.yaml"
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
[vagrant@kmaster ~]$ 

[vagrant@kmaster ~]$ 
[vagrant@kmaster ~]$ sudo kubeadm upgrade node
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[upgrade] Upgrading your Static Pod-hosted control plane instance to version "v1.16.15"...
Static pod: kube-apiserver-kmaster.example.com hash: 83d09b1a32f5ef0f69a1d0e58a2792da
Static pod: kube-controller-manager-kmaster.example.com hash: 0f81268495dab6ed796eae5347711e04
Static pod: kube-scheduler-kmaster.example.com hash: 463b02139da48f3e55ac8f355ab95be1
[upgrade/etcd] Upgrading to TLS for etcd
[upgrade/etcd] Non fatal issue encountered during upgrade: the desired etcd version for this Kubernetes version "v1.16.15" is "3.3.15-0", but the current etcd version is "3.3.15". Won't downgrade etcd, instead just continue
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests064542838"
[upgrade/staticpods] Preparing for "kube-apiserver" upgrade
[upgrade/staticpods] Current and new manifests of kube-apiserver are equal, skipping upgrade
[upgrade/staticpods] Preparing for "kube-controller-manager" upgrade
[upgrade/staticpods] Current and new manifests of kube-controller-manager are equal, skipping upgrade
[upgrade/staticpods] Preparing for "kube-scheduler" upgrade
[upgrade/staticpods] Current and new manifests of kube-scheduler are equal, skipping upgrade
[upgrade] The control plane instance for this node was successfully updated!
[kubelet-start] Downloading configuration for the kubelet from the "kubelet-config-1.16" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[upgrade] The configuration for this node was successfully updated!
[upgrade] Now you should go ahead and upgrade the kubelet package using your package manager.
[vagrant@kmaster ~]$
[vagrant@kmaster ~]$ kubectl get node
NAME                   STATUS   ROLES    AGE     VERSION
kmaster.example.com    Ready    master   3h23m   v1.15.12
kworker1.example.com   Ready    <none>   3h18m   v1.15.12
[vagrant@kmaster ~]$ sudo yum install -y kubelet-1.16.15-0 kubectl-1.16.15-0 --disableexcludes=kubernetes
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.thzhost.com
 * extras: mirrors.qlu.edu.cn
 * updates: mirrors.thzhost.com
Resolving Dependencies
--> Running transaction check
---> Package kubectl.x86_64 0:1.15.12-0 will be updated
---> Package kubectl.x86_64 0:1.16.15-0 will be an update
---> Package kubelet.x86_64 0:1.15.12-0 will be updated
---> Package kubelet.x86_64 0:1.16.15-0 will be an update
--> Finished Dependency Resolution

Dependencies Resolved

=================================================================================================================================
 Package                      Arch                        Version                          Repository                       Size
=================================================================================================================================
Updating:
 kubectl                      x86_64                      1.16.15-0                        kubernetes                      9.3 M
 kubelet                      x86_64                      1.16.15-0                        kubernetes                       20 M

Transaction Summary
=================================================================================================================================
Upgrade  2 Packages

Total download size: 30 M
Downloading packages:
No Presto metadata available for kubernetes
(1/2): 5323af1096a6deff135ecbc56dbdf8ca305e2ff8e6666d42a8673852f106d1d2-kubectl-1.16.15-0.x86_64.rpm      | 9.3 MB  00:00:03     
(2/2): 3696890bc43ba8aa59f4158b8f3fb23d6f99883d03867f99929c380dd40f99e1-kubelet-1.16.15-0.x86_64.rpm      |  20 MB  00:00:08     
---------------------------------------------------------------------------------------------------------------------------------
Total                                                                                            3.6 MB/s |  30 MB  00:00:08     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : kubectl-1.16.15-0.x86_64                                                                                      1/4 
  Updating   : kubelet-1.16.15-0.x86_64                                                                                      2/4 
  Cleanup    : kubectl-1.15.12-0.x86_64                                                                                      3/4 
  Cleanup    : kubelet-1.15.12-0.x86_64                                                                                      4/4 
  Verifying  : kubelet-1.16.15-0.x86_64                                                                                      1/4 
  Verifying  : kubectl-1.16.15-0.x86_64                                                                                      2/4 
  Verifying  : kubelet-1.15.12-0.x86_64                                                                                      3/4 
  Verifying  : kubectl-1.15.12-0.x86_64                                                                                      4/4 

Updated:
  kubectl.x86_64 0:1.16.15-0                                      kubelet.x86_64 0:1.16.15-0                                     

Complete!
[vagrant@kmaster ~]$ 
[vagrant@kmaster ~]$ kubectl drain kmaster.example.com --ignore-daemonsets
node/kmaster.example.com cordoned
WARNING: ignoring DaemonSet-managed Pods: kube-system/kube-flannel-ds-amd64-tjtl7, kube-system/kube-proxy-cwt79
evicting pod "coredns-5644d7b6d9-2l27w"
pod/coredns-5644d7b6d9-2l27w evicted
node/kmaster.example.com evicted
[vagrant@kmaster ~]$ 
[vagrant@kmaster ~]$ kubelet --version
Kubernetes v1.16.15
[vagrant@kmaster ~]$ kubectl version
Client Version: version.Info{Major:"1", Minor:"16", GitVersion:"v1.16.15", GitCommit:"2adc8d7091e89b6e3ca8d048140618ec89b39369", GitTreeState:"clean", BuildDate:"2020-09-02T11:40:00Z", GoVersion:"go1.13.15", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"16", GitVersion:"v1.16.15", GitCommit:"2adc8d7091e89b6e3ca8d048140618ec89b39369", GitTreeState:"clean", BuildDate:"2020-09-02T11:31:21Z", GoVersion:"go1.13.15", Compiler:"gc", Platform:"linux/amd64"}
[vagrant@kmaster ~]$
[vagrant@kmaster ~]$ kubectl get node
NAME                   STATUS                     ROLES    AGE     VERSION
kmaster.example.com    Ready,SchedulingDisabled   master   3h25m   v1.15.12
kworker1.example.com   Ready                      <none>   3h20m   v1.15.12
[vagrant@kmaster ~]$ 
[vagrant@kmaster ~]$ sudo systemctl restart kubelet
Warning: kubelet.service changed on disk. Run 'systemctl daemon-reload' to reload units.
[vagrant@kmaster ~]$ sudo systemctl daemon-reload
[vagrant@kmaster ~]$ 
[vagrant@kmaster ~]$ k get node
NAME                   STATUS                     ROLES    AGE     VERSION
kmaster.example.com    Ready,SchedulingDisabled   master   3h26m   v1.16.15
kworker1.example.com   Ready                      <none>   3h21m   v1.15.12
[vagrant@kmaster ~]$
[vagrant@kmaster ~]$ kubectl uncordon kmaster.example.com 
node/kmaster.example.com uncordoned
[vagrant@kmaster ~]$ 
[vagrant@kmaster ~]$ 
[vagrant@kmaster ~]$ k get node
NAME                   STATUS   ROLES    AGE     VERSION
kmaster.example.com    Ready    master   3h26m   v1.16.15
kworker1.example.com   Ready    <none>   3h22m   v1.15.12
[vagrant@kmaster ~]$ 
[vagrant@kmaster ~]$ /opt/cni/bin/flannel --version
CNI flannel plugin v0.8.6
[vagrant@kmaster ~]$

[vagrant@kmaster ~]$ k get pod -A
NAMESPACE     NAME                                          READY   STATUS              RESTARTS   AGE
kube-system   coredns-5644d7b6d9-9b462                      0/1     ContainerCreating   0          2m43s
kube-system   coredns-5644d7b6d9-qzhvj                      0/1     ContainerCreating   0          115m
kube-system   etcd-kmaster.example.com                      1/1     Running             1          80s
kube-system   kube-apiserver-kmaster.example.com            1/1     Running             0          80s
kube-system   kube-controller-manager-kmaster.example.com   1/1     Running             0          80s
kube-system   kube-flannel-ds-amd64-8hmzf                   1/1     Running             1          3h22m
kube-system   kube-flannel-ds-amd64-tjtl7                   1/1     Running             1          3h27m
kube-system   kube-flannel-ds-gvrb6                         2/2     Running             0          3h21m
kube-system   kube-proxy-c6m5g                              1/1     Running             0          115m
kube-system   kube-proxy-cwt79                              1/1     Running             1          114m
kube-system   kube-scheduler-kmaster.example.com            1/1     Running             0          80s
[vagrant@kmaster ~]$
[vagrant@kmaster ~]$ kubectl describe -n kube-system pod coredns-5644d7b6d9-9b462 
Name:                 coredns-5644d7b6d9-9b462
Namespace:            kube-system
Priority:             2000000000
Priority Class Name:  system-cluster-critical
Node:                 kworker1.example.com/192.168.56.201
Start Time:           Mon, 30 Oct 2023 07:22:50 +0000
Labels:               k8s-app=kube-dns
                      pod-template-hash=5644d7b6d9
Annotations:          <none>
Status:               Pending
IP:                   
IPs:                  <none>
Controlled By:        ReplicaSet/coredns-5644d7b6d9
Containers:
  coredns:
    Container ID:  
    Image:         k8s.gcr.io/coredns:1.6.2
    Image ID:      
    Ports:         53/UDP, 53/TCP, 9153/TCP
    Host Ports:    0/UDP, 0/TCP, 0/TCP
    Args:
      -conf
      /etc/coredns/Corefile
    State:          Waiting
      Reason:       ContainerCreating
    Ready:          False
    Restart Count:  0
    Limits:
      memory:  170Mi
    Requests:
      cpu:        100m
      memory:     70Mi
    Liveness:     http-get http://:8080/health delay=60s timeout=5s period=10s #success=1 #failure=5
    Readiness:    http-get http://:8181/ready delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:  <none>
    Mounts:
      /etc/coredns from config-volume (ro)
      /var/run/secrets/kubernetes.io/serviceaccount from coredns-token-nzwqj (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             False 
  ContainersReady   False 
  PodScheduled      True 
Volumes:
  config-volume:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      coredns
    Optional:  false
  coredns-token-nzwqj:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  coredns-token-nzwqj
    Optional:    false
QoS Class:       Burstable
Node-Selectors:  beta.kubernetes.io/os=linux
Tolerations:     CriticalAddonsOnly
                 node-role.kubernetes.io/master:NoSchedule
                 node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type     Reason                  Age                    From                           Message
  ----     ------                  ----                   ----                           -------
  Normal   Scheduled               <unknown>              default-scheduler              Successfully assigned kube-system/coredns-5644d7b6d9-9b462 to kworker1.example.com
  Warning  FailedCreatePodSandBox  9m7s                   kubelet, kworker1.example.com  Failed create pod sandbox: rpc error: code = Unknown desc = [failed to set up sandbox container "99b9a3cbeb853476d12f1e1af8d3fb2eda7064f3f1d4da5e7feb8a27a438cdfd" network for pod "coredns-5644d7b6d9-9b462": NetworkPlugin cni failed to set up pod "coredns-5644d7b6d9-9b462_kube-system" network: failed to find plugin "flannel" in path [/opt/cni/bin], failed to clean up sandbox container "99b9a3cbeb853476d12f1e1af8d3fb2eda7064f3f1d4da5e7feb8a27a438cdfd" network for pod "coredns-5644d7b6d9-9b462": NetworkPlugin cni failed to teardown pod "coredns-5644d7b6d9-9b462_kube-system" network: failed to find plugin "flannel" in path [/opt/cni/bin]]
  Normal   SandboxChanged          3m46s (x25 over 9m7s)  kubelet, kworker1.example.com  Pod sandbox changed, it will be killed and re-created.
[vagrant@kmaster ~]$ 

[vagrant@kmaster ~]$ kubectl delete -n kube-system pod coredns-5644d7b6d9-nls2v --grace-period 0
[vagrant@kmaster ~]$ k get pod -A | grep dns
kube-system   coredns-5644d7b6d9-nktck                      1/1     Running   0          41s
kube-system   coredns-5644d7b6d9-qp66v                      1/1     Running   0          23m
[vagrant@kmaster ~]$
```

### Upgrade Worker Node Step
#### Master Node - drain the Worker Node
```
[vagrant@kmaster ~]$ kubectl drain kworker1.example.com --ignore-daemonsets
node/kworker1.example.com cordoned
WARNING: ignoring DaemonSet-managed Pods: kube-system/kube-flannel-ds-amd64-fpjcl, kube-system/kube-flannel-ds-j9gcf, kube-system/kube-proxy-5gwtf
evicting pod "coredns-5644d7b6d9-ftltv"
evicting pod "nginx-8d4c546f5-t4hx8"
evicting pod "coredns-5644d7b6d9-7t76r"
pod/coredns-5644d7b6d9-ftltv evicted
pod/coredns-5644d7b6d9-7t76r evicted
pod/nginx-8d4c546f5-t4hx8 evicted
node/kworker1.example.com evicted
[vagrant@kmaster ~]$  
```

#### Worker Node - upgrade kubeadm
```
sudo yum install -y kubeadm-1.16.15-0 --disableexcludes=kubernetes

[vagrant@kworker1 ~]$ sudo yum install -y kubeadm-1.16.15-0 --disableexcludes=kubernetes
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.bfsu.edu.cn
 * extras: mirrors.nipa.cloud
 * updates: mirrors.nipa.cloud
Resolving Dependencies
--> Running transaction check
---> Package kubeadm.x86_64 0:1.15.12-0 will be updated
---> Package kubeadm.x86_64 0:1.16.15-0 will be an update
--> Finished Dependency Resolution

Dependencies Resolved

==========================================================================================================================================
 Package                        Arch                          Version                             Repository                         Size
==========================================================================================================================================
Updating:
 kubeadm                        x86_64                        1.16.15-0                           kubernetes                        8.8 M

Transaction Summary
==========================================================================================================================================
Upgrade  1 Package

Total download size: 8.8 M
Downloading packages:
No Presto metadata available for kubernetes
c0dee0d6cbf2a2269e4d84f7c6e08849f80959a1c3b1425d26535df7b027d7d8-kubeadm-1.16.15-0.x86_64.rpm                      | 8.8 MB  00:00:01     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : kubeadm-1.16.15-0.x86_64                                                                                               1/2 
  Cleanup    : kubeadm-1.15.12-0.x86_64                                                                                               2/2 
  Verifying  : kubeadm-1.16.15-0.x86_64                                                                                               1/2 
  Verifying  : kubeadm-1.15.12-0.x86_64                                                                                               2/2 

Updated:
  kubeadm.x86_64 0:1.16.15-0                                                                                                              

Complete!
[vagrant@kworker1 ~]$

```
### kubeadm upgrade node 
#### Worker Node - upgrade kubelet
```
sudo yum install -y kubelet-1.16.15-0 kubectl-1.16.15-0 --disableexcludes=kubernetes
sudo systemctl restart kubelet

[vagrant@kworker1 ~]$ sudo yum install -y kubelet-1.16.15-0 kubectl-1.16.15-0 --disableexcludes=kubernetes
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.bfsu.edu.cn
 * extras: mirrors.nipa.cloud
 * updates: mirrors.nipa.cloud
Resolving Dependencies
--> Running transaction check
---> Package kubectl.x86_64 0:1.15.12-0 will be updated
---> Package kubectl.x86_64 0:1.16.15-0 will be an update
---> Package kubelet.x86_64 0:1.15.12-0 will be updated
---> Package kubelet.x86_64 0:1.16.15-0 will be an update
--> Finished Dependency Resolution

Dependencies Resolved

==========================================================================================================================================
 Package                        Arch                          Version                             Repository                         Size
==========================================================================================================================================
Updating:
 kubectl                        x86_64                        1.16.15-0                           kubernetes                        9.3 M
 kubelet                        x86_64                        1.16.15-0                           kubernetes                         20 M

Transaction Summary
==========================================================================================================================================
Upgrade  2 Packages

Total download size: 30 M
Downloading packages:
No Presto metadata available for kubernetes
(1/2): 5323af1096a6deff135ecbc56dbdf8ca305e2ff8e6666d42a8673852f106d1d2-kubectl-1.16.15-0.x86_64.rpm               | 9.3 MB  00:00:02     
(2/2): 3696890bc43ba8aa59f4158b8f3fb23d6f99883d03867f99929c380dd40f99e1-kubelet-1.16.15-0.x86_64.rpm               |  20 MB  00:00:03     
------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                     9.4 MB/s |  30 MB  00:00:03     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : kubectl-1.16.15-0.x86_64                                                                                               1/4 
  Updating   : kubelet-1.16.15-0.x86_64                                                                                               2/4 
  Cleanup    : kubectl-1.15.12-0.x86_64                                                                                               3/4 
  Cleanup    : kubelet-1.15.12-0.x86_64                                                                                               4/4 
  Verifying  : kubelet-1.16.15-0.x86_64                                                                                               1/4 
  Verifying  : kubectl-1.16.15-0.x86_64                                                                                               2/4 
  Verifying  : kubelet-1.15.12-0.x86_64                                                                                               3/4 
  Verifying  : kubectl-1.15.12-0.x86_64                                                                                               4/4 

Updated:
  kubectl.x86_64 0:1.16.15-0                                          kubelet.x86_64 0:1.16.15-0                                         

Complete!
[vagrant@kworker1 ~]$ sudo systemctl restart kubelet
Warning: kubelet.service changed on disk. Run 'systemctl daemon-reload' to reload units.
[vagrant@kworker1 ~]$ sudo systemctl daemon-reload
[vagrant@kworker1 ~]$
```
#### Master Node - uncordon the Worker Node
```
[vagrant@kmaster ~]$ k get pod -A
NAMESPACE     NAME                                          READY   STATUS    RESTARTS   AGE
default       nginx-8d4c546f5-2f86t                         0/1     Pending   0          3m22s
kube-system   coredns-5644d7b6d9-84zzg                      1/1     Running   0          3m22s
kube-system   coredns-5644d7b6d9-kqc6b                      1/1     Running   0          3m22s
kube-system   etcd-kmaster.example.com                      1/1     Running   1          4m44s
kube-system   kube-apiserver-kmaster.example.com            1/1     Running   1          4m50s
kube-system   kube-controller-manager-kmaster.example.com   1/1     Running   0          4m44s
kube-system   kube-flannel-ds-amd64-fpjcl                   1/1     Running   3          18m
kube-system   kube-flannel-ds-amd64-gk9l9                   1/1     Running   1          20m
kube-system   kube-flannel-ds-j9gcf                         2/2     Running   2          18m
kube-system   kube-proxy-5gwtf                              1/1     Running   1          6m45s
kube-system   kube-proxy-z6zkw                              1/1     Running   1          7m3s
kube-system   kube-scheduler-kmaster.example.com            1/1     Running   0          4m44s
[vagrant@kmaster ~]$
[vagrant@kmaster ~]$ kubectl uncordon kworker1.example.com 
node/kworker1.example.com uncordoned
[vagrant@kmaster ~]$ 
[vagrant@kmaster ~]$ 
[vagrant@kmaster ~]$ k get pod
NAME                    READY   STATUS              RESTARTS   AGE
nginx-8d4c546f5-2f86t   0/1     ContainerCreating   0          3m52s
[vagrant@kmaster ~]$ k get pod
NAME                    READY   STATUS    RESTARTS   AGE
nginx-8d4c546f5-2f86t   1/1     Running   0          3m54s
[vagrant@kmaster ~]$

[vagrant@kmaster ~]$ k get node
NAME                   STATUS   ROLES    AGE   VERSION
kmaster.example.com    Ready    master   22m   v1.16.15
kworker1.example.com   Ready    <none>   20m   v1.16.15
[vagrant@kmaster ~]$ kubectl get pod -A
NAMESPACE     NAME                                          READY   STATUS    RESTARTS   AGE
default       nginx-8d4c546f5-2f86t                         1/1     Running   0          4m49s
kube-system   coredns-5644d7b6d9-84zzg                      1/1     Running   0          4m49s
kube-system   coredns-5644d7b6d9-kqc6b                      1/1     Running   0          4m49s
kube-system   etcd-kmaster.example.com                      1/1     Running   1          6m11s
kube-system   kube-apiserver-kmaster.example.com            1/1     Running   1          6m17s
kube-system   kube-controller-manager-kmaster.example.com   1/1     Running   0          6m11s
kube-system   kube-flannel-ds-amd64-fpjcl                   1/1     Running   3          20m
kube-system   kube-flannel-ds-amd64-gk9l9                   1/1     Running   1          21m
kube-system   kube-flannel-ds-j9gcf                         2/2     Running   2          19m
kube-system   kube-proxy-5gwtf                              1/1     Running   1          8m12s
kube-system   kube-proxy-z6zkw                              1/1     Running   1          8m30s
kube-system   kube-scheduler-kmaster.example.com            1/1     Running   0          6m11s
[vagrant@kmaster ~]$

```
### Problem about Flannel 
```
[vagrant@kmaster ~]$ k get pod -A
NAMESPACE     NAME                                          READY   STATUS             RESTARTS   AGE
default       nginx-f95985f4c-xb8pn                         1/1     Running            0          12m
kube-system   coredns-5644d7b6d9-4q69b                      1/1     Running            0          12m
kube-system   coredns-5644d7b6d9-qp66v                      1/1     Running            0          42m
kube-system   etcd-kmaster.example.com                      1/1     Running            2          3h24m
kube-system   kube-apiserver-kmaster.example.com            1/1     Running            1          3h24m
kube-system   kube-controller-manager-kmaster.example.com   1/1     Running            1          3h24m
kube-system   kube-flannel-ds-amd64-8hmzf                   0/1     CrashLoopBackOff   6          6h45m
kube-system   kube-flannel-ds-amd64-tjtl7                   1/1     Running            2          6h49m
kube-system   kube-flannel-ds-gvrb6                         1/2     CrashLoopBackOff   6          6h44m
kube-system   kube-proxy-c6m5g                              1/1     Running            1          5h18m
kube-system   kube-proxy-cwt79                              1/1     Running            2          5h17m
kube-system   kube-scheduler-kmaster.example.com            1/1     Running            1          3h24m
[vagrant@kmaster ~]$

[root@kworker1 vagrant]# docker ps -a
CONTAINER ID   IMAGE                    COMMAND                  CREATED          STATUS                        PORTS     NAMES
67ca72ef8396   f0fad859c909             "/opt/bin/flanneld -…"   5 seconds ago    Exited (1) 4 seconds ago                k8s_kube-flannel_kube-flannel-ds-gvrb6_kube-system_62162981-57c3-42da-8ddd-c1ab69c5b8e4_8
039d0cca98c7   ff281650a721             "/opt/bin/flanneld -…"   50 seconds ago   Exited (1) 49 seconds ago               k8s_kube-flannel_kube-flannel-ds-amd64-8hmzf_kube-system_42f8ef3f-683c-4d9e-837a-951ac489278b_8
6c5a8584759a   nginx                    "/docker-entrypoint.…"   10 minutes ago   Up 10 minutes                           k8s_nginx_nginx-f95985f4c-xb8pn_default_1a009d5d-ef97-4da0-a6cd-8be58f27fa34_0
e01ff34ef8c7   k8s.gcr.io/pause:3.1     "/pause"                 10 minutes ago   Up 10 minutes                           k8s_POD_nginx-f95985f4c-xb8pn_default_1a009d5d-ef97-4da0-a6cd-8be58f27fa34_0
225fcc3d3ee6   f0fad859c909             "/bin/sh -c 'set -e …"   11 minutes ago   Up 11 minutes                           k8s_install-cni_kube-flannel-ds-gvrb6_kube-system_62162981-57c3-42da-8ddd-c1ab69c5b8e4_1
34d679ec9b76   6133ee425f8b             "/usr/local/bin/kube…"   12 minutes ago   Up 12 minutes                           k8s_kube-proxy_kube-proxy-c6m5g_kube-system_96f8db8b-f37c-4f68-a593-12db5a973ddc_1
927ca90d4d08   k8s.gcr.io/kube-proxy    "/usr/local/bin/kube…"   4 hours ago      Exited (2) 12 minutes ago               k8s_kube-proxy_kube-proxy-c6m5g_kube-system_96f8db8b-f37c-4f68-a593-12db5a973ddc_0
6fc22a08f8b4   k8s.gcr.io/pause:3.1     "/pause"                 4 hours ago      Up 4 hours                              k8s_POD_kube-proxy-c6m5g_kube-system_96f8db8b-f37c-4f68-a593-12db5a973ddc_0
e571d5dc5163   f0fad859c909             "/bin/sh -c 'set -e …"   5 hours ago      Exited (137) 11 minutes ago             k8s_install-cni_kube-flannel-ds-gvrb6_kube-system_62162981-57c3-42da-8ddd-c1ab69c5b8e4_0
761b40d77932   k8s.gcr.io/pause:3.1     "/pause"                 5 hours ago      Up 5 hours                              k8s_POD_kube-flannel-ds-gvrb6_kube-system_62162981-57c3-42da-8ddd-c1ab69c5b8e4_0
df55d87a286e   quay.io/coreos/flannel   "cp -f /etc/kube-fla…"   5 hours ago      Exited (0) 5 hours ago                  k8s_install-cni_kube-flannel-ds-amd64-8hmzf_kube-system_42f8ef3f-683c-4d9e-837a-951ac489278b_0
da2ee5a64056   k8s.gcr.io/pause:3.1     "/pause"                 5 hours ago      Up 5 hours                              k8s_POD_kube-flannel-ds-amd64-8hmzf_kube-system_42f8ef3f-683c-4d9e-837a-951ac489278b_0
[root@kworker1 vagrant]# docker logs 67ca72ef8396
I1030 09:02:08.340070       1 main.go:475] Determining IP address of default interface
I1030 09:02:08.340851       1 main.go:488] Using interface with name eth0 and address 10.0.2.15
I1030 09:02:08.340871       1 main.go:505] Defaulting external address to interface address (10.0.2.15)
E1030 09:02:08.350768       1 main.go:232] Failed to create SubnetManager: error retrieving pod spec for 'kube-system/kube-flannel-ds-gvrb6': pods "kube-flannel-ds-gvrb6" is forbidden: User "system:serviceaccount:kube-system:flannel" cannot get resource "pods" in API group "" in the namespace "kube-system"
[root@kworker1 vagrant]#
```

## v1.16.x-v.1.17.x
### Master Node - upgrade kubeadm
```
[vagrant@kmaster ~]$ yum list --showduplicates kubeadm --disableexcludes=kubernetes | grep 1.17.
kubeadm.x86_64                       1.17.0-0                        kubernetes 
kubeadm.x86_64                       1.17.1-0                        kubernetes 
kubeadm.x86_64                       1.17.2-0                        kubernetes 
kubeadm.x86_64                       1.17.3-0                        kubernetes 
kubeadm.x86_64                       1.17.4-0                        kubernetes 
kubeadm.x86_64                       1.17.5-0                        kubernetes 
kubeadm.x86_64                       1.17.6-0                        kubernetes 
kubeadm.x86_64                       1.17.7-0                        kubernetes 
kubeadm.x86_64                       1.17.7-1                        kubernetes 
kubeadm.x86_64                       1.17.8-0                        kubernetes 
kubeadm.x86_64                       1.17.9-0                        kubernetes 
kubeadm.x86_64                       1.17.11-0                       kubernetes 
kubeadm.x86_64                       1.17.12-0                       kubernetes 
kubeadm.x86_64                       1.17.13-0                       kubernetes 
kubeadm.x86_64                       1.17.14-0                       kubernetes 
kubeadm.x86_64                       1.17.15-0                       kubernetes 
kubeadm.x86_64                       1.17.16-0                       kubernetes 
kubeadm.x86_64                       1.17.17-0                       kubernetes 
[vagrant@kmaster ~]$
[vagrant@kmaster ~]$ sudo yum install -y kubeadm-1.17.17-0 --disableexcludes=kubernetes
[vagrant@kmaster ~]$ kubeadm version
[vagrant@kmaster ~]$ sudo kubeadm upgrade plan
[vagrant@kmaster ~]$ sudo kubeadm upgrade apply v1.17.17
[vagrant@kmaster ~]$ sudo kubeadm upgrade node
```
### Master Node - upgrade kubectl and kubelet
```
sudo yum install -y kubelet-1.17.17-0  kubectl-1.17.17-0 --disableexcludes=kubernetes
kubectl drain kmaster.example.com --ignore-daemonsets
sudo systemctl restart kubelet
sudo systemctl daemon-reload
kubectl uncordon kmaster.example.com
k get node
```
### Worker Node
### Master Node - drain the Worker Node
```
kubectl drain kworker1.example.com --ignore-daemonsets
```
### Worker Node - upgrade kubeadm
```
sudo yum install -y kubeadm-1.17.17-0 --disableexcludes=kubernetes
sudo kubeadm upgrade node
```
### Worker Node - upgrade kubectl
```
sudo yum install -y kubelet-1.17.17-0 kubectl-1.17.17-0 --disableexcludes=kubernetes
sudo systemctl restart kubelet
sudo systemctl daemon-reload
```
### Master Node - uncordon the Worker Node
```
kubectl uncordon kworker1.example.com
```
```
[vagrant@kmaster ~]$ k get node
NAME                   STATUS   ROLES    AGE   VERSION
kmaster.example.com    Ready    master   52m   v1.17.17
kworker1.example.com   Ready    <none>   50m   v1.17.17
[vagrant@kmaster ~]$ k get pod -A
NAMESPACE     NAME                                          READY   STATUS    RESTARTS   AGE
default       nginx-8d4c546f5-dhwfd                         1/1     Running   0          110s
kube-system   coredns-6955765f44-gjbwv                      1/1     Running   0          110s
kube-system   coredns-6955765f44-p6krs                      1/1     Running   0          110s
kube-system   etcd-kmaster.example.com                      1/1     Running   0          7m38s
kube-system   kube-apiserver-kmaster.example.com            1/1     Running   0          7m28s
kube-system   kube-controller-manager-kmaster.example.com   1/1     Running   0          7m26s
kube-system   kube-flannel-ds-amd64-fpjcl                   1/1     Running   3          50m
kube-system   kube-flannel-ds-amd64-gk9l9                   1/1     Running   1          52m
kube-system   kube-flannel-ds-j9gcf                         2/2     Running   2          50m
kube-system   kube-proxy-bzsbh                              1/1     Running   0          6m46s
kube-system   kube-proxy-zk5z2                              1/1     Running   0          6m34s
kube-system   kube-scheduler-kmaster.example.com            1/1     Running   0          7m25s
[vagrant@kmaster ~]$
```

## Upgrade v1.17.x-v.1.18.x
### Master Node - upgrade kubeadm
```
[vagrant@kmaster ~]$ yum list --showduplicates kubeadm --disableexcludes=kubernetes | grep 1.18.
kubeadm.x86_64                       1.18.0-0                        kubernetes 
kubeadm.x86_64                       1.18.1-0                        kubernetes 
kubeadm.x86_64                       1.18.2-0                        kubernetes 
kubeadm.x86_64                       1.18.3-0                        kubernetes 
kubeadm.x86_64                       1.18.4-0                        kubernetes 
kubeadm.x86_64                       1.18.4-1                        kubernetes 
kubeadm.x86_64                       1.18.5-0                        kubernetes 
kubeadm.x86_64                       1.18.6-0                        kubernetes 
kubeadm.x86_64                       1.18.8-0                        kubernetes 
kubeadm.x86_64                       1.18.9-0                        kubernetes 
kubeadm.x86_64                       1.18.10-0                       kubernetes 
kubeadm.x86_64                       1.18.12-0                       kubernetes 
kubeadm.x86_64                       1.18.13-0                       kubernetes 
kubeadm.x86_64                       1.18.14-0                       kubernetes 
kubeadm.x86_64                       1.18.15-0                       kubernetes 
kubeadm.x86_64                       1.18.16-0                       kubernetes 
kubeadm.x86_64                       1.18.17-0                       kubernetes 
kubeadm.x86_64                       1.18.18-0                       kubernetes 
kubeadm.x86_64                       1.18.19-0                       kubernetes 
kubeadm.x86_64                       1.18.20-0                       kubernetes 
[vagrant@kmaster ~]$
[vagrant@kmaster ~]$ sudo yum install -y kubeadm-1.18.20-0 --disableexcludes=kubernetes
[vagrant@kmaster ~]$ kubeadm version
[vagrant@kmaster ~]$ sudo kubeadm upgrade plan
[vagrant@kmaster ~]$ sudo kubeadm upgrade apply v1.18.20
[vagrant@kmaster ~]$ sudo kubeadm upgrade node
```
### Master Node - upgrade kubectl and kubelet
```
sudo yum install -y kubelet-1.18.20-0  kubectl-1.18.20-0 --disableexcludes=kubernetes
kubectl drain kmaster.example.com --ignore-daemonsets
sudo systemctl restart kubelet
sudo systemctl daemon-reload
kubectl uncordon kmaster.example.com
k get node
```
### Worker Node
### Master Node - drain the Worker Node
```
kubectl drain kworker1.example.com --ignore-daemonsets
```
### Worker Node - upgrade kubeadm
```
sudo yum install -y kubeadm-1.18.20-0 --disableexcludes=kubernetes
sudo kubeadm upgrade node
```
### Worker Node - upgrade kubectl
```
sudo yum install -y kubelet-1.18.20-0 kubectl-1.18.20-0 --disableexcludes=kubernetes
sudo systemctl restart kubelet
sudo systemctl daemon-reload
```
### Master Node - uncordon the Worker Node
```
kubectl uncordon kworker1.example.com
```
```
[vagrant@kmaster ~]$ k get node 
NAME                   STATUS   ROLES    AGE   VERSION
kmaster.example.com    Ready    master   60m   v1.18.20
kworker1.example.com   Ready    <none>   58m   v1.18.20
[vagrant@kmaster ~]$  k get pod -A
NAMESPACE     NAME                                          READY   STATUS    RESTARTS   AGE
default       nginx-8d4c546f5-95lhs                         1/1     Running   0          2m
kube-system   coredns-66bff467f8-dj8fg                      1/1     Running   0          2m
kube-system   coredns-66bff467f8-t9fjp                      1/1     Running   0          2m
kube-system   etcd-kmaster.example.com                      1/1     Running   1          2m35s
kube-system   kube-apiserver-kmaster.example.com            1/1     Running   0          2m35s
kube-system   kube-controller-manager-kmaster.example.com   1/1     Running   0          2m35s
kube-system   kube-flannel-ds-amd64-fpjcl                   1/1     Running   3          58m
kube-system   kube-flannel-ds-amd64-gk9l9                   1/1     Running   1          60m
kube-system   kube-flannel-ds-j9gcf                         2/2     Running   2          58m
kube-system   kube-proxy-4lvnn                              1/1     Running   0          3m14s
kube-system   kube-proxy-b2twq                              1/1     Running   0          2m58s
kube-system   kube-scheduler-kmaster.example.com            1/1     Running   0          2m35s
[vagrant@kmaster ~]$
```
since it's kubernetes you may encounter some issues, feel free to poke me

