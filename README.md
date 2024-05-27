# kubernetes-playgrounds
Kubernetes Playgrounds

จะเป็นการเรียนรู้เกี่ยวกับเรื่อง Kubernetes เบื้องต้น เหมาะสำหรับคนที่กำลังเริ่มต้นศึกษา

## Prepare/Install vagrant and virtualbox on Win10
Choco for Windows install 
https://chocolatey.org/install

Installation vagrant
```
choco install vagrant -y 
```

Installation virtualbox
```
choco install vitualbox -y
```
## Prepare/Install vagrant and virtualbox on MacOS

Installation vagrant
```
brew cask install vagrant 
```

Installation virtualbox
```
brew cask install vitualbox
```

### Check vagrant version
```
vagrant version

Installed Version: 2.4.1
Latest Version: 2.4.1

```
If Win10 can't ssh to all node in vagrant, How to fixed like below.
https://github.com/hashicorp/vagrant/issues/9950

```
$env:VAGRANT_PREFER_SYSTEM_BIN="0"
```

# Kuberentes How to Installation 
เอกสารสำหรับการติดตั้ง เพื่อทดสอบการทำงานของ Kubernetes

- [เรียนรู้ Kubernetes ด้วย minikube กัน ](k8s-docs/how-to-install-k8s-with-kubeadm.md)
- [How To Install K8S all-in-one on Ubuntu with kubeadm ](k8s-docs/how-to-install-k8s-with-kubeadm.md)
- [How To Upgrade K8s v1.15.x to 1.18.x on CentOS 7 with kubeadm ](k8s-docs/howto-upgrade-k8s-15to18-with-kubeadm_V1.md)
