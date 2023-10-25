[root@kubemaster vagrant]# kubectl version
Client Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.12", GitCommit:"e2a822d9f3c2fdb5c9bfbe64313cf9f657f0a725", GitTreeState:"clean", BuildDate:"2020-05-06T05:17:59Z", GoVersion:"go1.12.17", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.12", GitCommit:"e2a822d9f3c2fdb5c9bfbe64313cf9f657f0a725", GitTreeState:"clean", BuildDate:"2020-05-06T05:09:48Z", GoVersion:"go1.12.17", Compiler:"gc", Platform:"linux/amd64"}
[root@kubemaster vagrant]# 
[root@kubemaster vagrant]# 
[root@kubemaster vagrant]# kubectl get node
NAME         STATUS   ROLES    AGE   VERSION
kubemaster   Ready    master   71m   v1.15.12
[root@kubemaster vagrant]#


### Upgrade 1.15.12 to 1.16.15 is NotReady ###


yum list --showduplicates kubeadm --disableexcludes=kubernetes
# find the latest 1.16 version in the list
# it should look like 1.16.x-0, where x is the latest patch


# replace x in 1.16.x-00 with the latest patch version
yum install -y kubeadm-1.16.15-0 --disableexcludes=kubernetes

kubeadm version

sudo kubeadm upgrade plan


sudo kubeadm upgrade apply v1.16.x


[root@kubemaster vagrant]# yum install -y kubeadm-1.16.15-0 --disableexcludes=kubernetes
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.nipa.cloud
 * epel: mirror2.totbb.net
 * extras: mirrors.nipa.cloud
 * updates: mirrors.aliyun.com
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
[root@kubemaster vagrant]# kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"16", GitVersion:"v1.16.15", GitCommit:"2adc8d7091e89b6e3ca8d048140618ec89b39369", GitTreeState:"clean", BuildDate:"2020-09-02T11:37:34Z", GoVersion:"go1.13.15", Compiler:"gc", Platform:"linux/amd64"}
[root@kubemaster vagrant]# kubectl get node
NAME         STATUS   ROLES    AGE   VERSION
kubemaster   Ready    master   79m   v1.15.12
[root@kubemaster vagrant]# sudo kubeadm upgrade plan
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[preflight] Running pre-flight checks.
[upgrade] Making sure the cluster is healthy:
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: v1.15.12
[upgrade/versions] kubeadm version: v1.16.15
I1024 16:01:50.712845   19464 version.go:251] remote version is much newer: v1.28.3; falling back to: stable-1.16
[upgrade/versions] Latest stable version: v1.16.15
[upgrade/versions] Latest version in the v1.15 series: v1.15.12

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   CURRENT        AVAILABLE
Kubelet     1 x v1.15.12   v1.16.15

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

[root@kubemaster vagrant]# 

[root@kubemaster vagrant]# sudo kubeadm upgrade apply v1.16.15
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
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-kube-controller-manager
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-etcd
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[upgrade/prepull] Prepulled image for component kube-apiserver.
[upgrade/prepull] Prepulled image for component kube-controller-manager.
[upgrade/prepull] Prepulled image for component kube-scheduler.
[upgrade/prepull] Prepulled image for component etcd.
[upgrade/prepull] Successfully prepulled the images for all the control plane components
[upgrade/apply] Upgrading your Static Pod-hosted control plane to version "v1.16.15"...
Static pod: kube-apiserver-kubemaster hash: 2119518ef4e3959e4cf52004ed889735
Static pod: kube-controller-manager-kubemaster hash: 03c0d36f658f19811b9be5e569cfab84
Static pod: kube-scheduler-kubemaster hash: 37bbbfb82a966a388adac318f32b758f
[upgrade/etcd] Upgrading to TLS for etcd
Static pod: etcd-kubemaster hash: 3f282d4b5256b860fc05fb854be0372f
[upgrade/staticpods] Preparing for "etcd" upgrade
[upgrade/staticpods] Renewing etcd-server certificate
[upgrade/staticpods] Renewing etcd-peer certificate
[upgrade/staticpods] Renewing etcd-healthcheck-client certificate
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/etcd.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2023-10-24-16-03-03/etcd.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: etcd-kubemaster hash: 3f282d4b5256b860fc05fb854be0372f
Static pod: etcd-kubemaster hash: 3f282d4b5256b860fc05fb854be0372f
Static pod: etcd-kubemaster hash: 2878ce0a6f33cdaaf2c39849f872fd1d
[apiclient] Found 1 Pods for label selector component=etcd
[upgrade/staticpods] Component "etcd" upgraded successfully!
[upgrade/etcd] Waiting for etcd to become available
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests353835963"
[upgrade/staticpods] Preparing for "kube-apiserver" upgrade
[upgrade/staticpods] Renewing apiserver certificate
[upgrade/staticpods] Renewing apiserver-kubelet-client certificate
[upgrade/staticpods] Renewing front-proxy-client certificate
[upgrade/staticpods] Renewing apiserver-etcd-client certificate
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2023-10-24-16-03-03/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-apiserver-kubemaster hash: 2119518ef4e3959e4cf52004ed889735
Static pod: kube-apiserver-kubemaster hash: 2119518ef4e3959e4cf52004ed889735
Static pod: kube-apiserver-kubemaster hash: 3f32a2d867c38f07b29cbfb2939989d2
[apiclient] Found 1 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-controller-manager" upgrade
[upgrade/staticpods] Renewing controller-manager.conf certificate
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2023-10-24-16-03-03/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-controller-manager-kubemaster hash: 03c0d36f658f19811b9be5e569cfab84
Static pod: kube-controller-manager-kubemaster hash: 6468045668764563a69183f9630ba77f
[apiclient] Found 1 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-scheduler" upgrade
[upgrade/staticpods] Renewing scheduler.conf certificate
[upgrade/staticpods] Moved new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backed up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2023-10-24-16-03-03/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This might take a minute or longer depending on the component/version gap (timeout 5m0s)
Static pod: kube-scheduler-kubemaster hash: 37bbbfb82a966a388adac318f32b758f
Static pod: kube-scheduler-kubemaster hash: 463b02139da48f3e55ac8f355ab95be1
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
[root@kubemaster vagrant]#

[root@kubemaster vagrant]# sudo kubeadm upgrade node
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[upgrade] Upgrading your Static Pod-hosted control plane instance to version "v1.16.15"...
Static pod: kube-apiserver-kubemaster hash: 3f32a2d867c38f07b29cbfb2939989d2
Static pod: kube-controller-manager-kubemaster hash: 6468045668764563a69183f9630ba77f
Static pod: kube-scheduler-kubemaster hash: 463b02139da48f3e55ac8f355ab95be1
[upgrade/etcd] Upgrading to TLS for etcd
[upgrade/etcd] Non fatal issue encountered during upgrade: the desired etcd version for this Kubernetes version "v1.16.15" is "3.3.15-0", but the current etcd version is "3.3.15". Won't downgrade etcd, instead just continue
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests268351227"
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
[root@kubemaster vagrant]# 

[root@kubemaster vagrant]# sudo systemctl restart kubelet
Warning: kubelet.service changed on disk. Run 'systemctl daemon-reload' to reload units.
[root@kubemaster vagrant]# systemctl daemon-reload
[root@kubemaster vagrant]# 
