# เริ่มเรียนรู้ Kubernetes ด้วย minikube กัน
minikube เป็นเครื่องที่ช่วยในการติดตั้ง Kubernetes Cluster บนเครื่อง PC (Local) ทั้งระบบปฏิบัติการ macOS, Linux และ Windows โดยเครื่องมือสร้างขึ้นมาเพื่อช่วย developer ใช้พัฒนาโปรแกรมและสำหรับคนที่เริ่มทำการศึกษา Kubernetes ให้เรียนรู้ได้อย่างง่ายๆ 

## จุดเด่น
- รองรับ Kuernetes releases ใหม่ๆ เสมอ
- รองรับได้หลาย Platform (Linux, macOS, Windows)
- สามารถ Deploy บน VM, Container หรือ bare-metal
- รองรับ Container Runtime ได้หลายๆ ตัว (CRI-O, containerd, docker)
- รองรับ Docker API endpoint รองรับการ [push images](https://minikube.sigs.k8s.io/docs/handbook/pushing/#pushing-directly-to-the-in-cluster-docker-daemon) ได้ง่าย
- รองรับ advanced features เช่น LoadBalancer, filesystem moutns และ FeatureGates
- [Addons](https://minikube.sigs.k8s.io/docs/handbook/deploying/#addons) สำหรับการติดตั้ง Kubernetes applications ได้ง่าย

## เริ่มใข้งาน minikube
minikube เป็นการใช้งาน Kubernetes บน Local โดยการตั้งค่าที่ง่ายและเหมาะสำหรับการเรียนรู้ หรือสำหรับการพัฒนา application ต่างๆ บน Kubernetes 

ซึ่งในการติดตั้ง Kubernetes ปกติแล้วจะต้องมี Virtual Machine หรือ Docker ก่อน แต่สำหรับ minikube จะจัดการติดตั้งให้ทุกอย่าง เพียงใช้แค่คำสั่งเดียวคือ minikube start

## ต้องเตรียมอะไรไว้ก่อนบ้าง
- 2 CPUs  หรือมากกว่า
- 2GB free memory 
- 20GB free disk space
- internet connection
- Container หรือ Virtual Machine manager เช่น Docker, Hyperkit, Hyper-V, KVM, Parallels, Podman, VirtualBox หรือ VMWare.

## วิธีการติดตั้ง minikube

### 1. วิธีการติดตั้งบน macOS 
```
brew install minikube
```
ถ้าติดตั้งแล้วมีปัญหาลอง 
```
brew cask remove minikube
brew link minikube
```
### 2. ทำการติดตั้ง virtualbox บน macOS
```
brew install virtualbox
```
### 3. Start your cluster
ทำการเปิด Terminal ด้วย administrator access (แต่ไม่จำเป็นต้องใช้ root login), จากนั้นก็ใช้คำสั่ง
```
minikube start
```
ค่าเริ่มต้นจะใช้ driver ของ virtualbox แต่ถ้าต้องการใช้กับ VM Manager ตัวอื่นๆ ลองเข้าไปดูที่หน้า [Drivers](https://minikube.sigs.k8s.io/docs/drivers/) ที่รองรับการใช้งาน

หลังจากการติดตั้งและตั้งค่าต่างๆ เสร็จแล้ว ลองใช้คำสั่ง เพื่อดูค่าต่างๆ ผ่านคำสั่ง kubectl ดู
```
kubectl get node
```
บน minikube จะติดตั้งตัว Kubernetes Dashborad มาแล้ว
```
minikube dashboard
```
### 4. ทดสอบ Deploy Application
ลองทำการ deploy simple app และ expose บน port 8080
```
kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.4
kubectl expose deployment hello-minikube --type=NodePort --port=8080
```
ลองดูรายการของ Services ของ hello-minikube
```
kubectl get services hello-minikube
```
เราสามารถใช้ minikube ในการเข้าถึง service ของ hello-minikube ได้โดยคำสั่งนี้ แล้วมันจะทำการเปิด web browser ขึ้นมาให้
```
minikube service hello-minikubes
```
หรืออีกทางคือใช้คำสั่งจาก kubectl สำหรับการ forward port ออกมาให้สามารถเรียกด้วย http://localhost:7080 ได้
```
kubectl port-forward service/hello-minikube 7080:8080
```
### 5. การจัดการ Kubernetes Cluster ด้วย minikube
ทำการ pause kubernetes 
```
minikube pause
```
ทำการปิด (Halt) Cluster
```
minikube stop
```
ทำการเพิ่ม memory limit (ต้องทำการ restart)
```
minikube config set memory 16384
```
ทำการลบ minikube cluster ทั้งหมด
```
minikube delete --all
```

ตัวอย่างการเรียนรู้
```
$ minikube start
😄  minikube v1.14.2 on Darwin 10.15.7
✨  Automatically selected the virtualbox driver
👍  Starting control plane node minikube in cluster minikube
🔥  Creating virtualbox VM (CPUs=2, Memory=4000MB, Disk=20000MB) ...

$kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.4

$kubectl expose deployment hello-minikube --type=NodePort --port=8080
deployment.apps/hello-minikube created
service/hello-minikube exposed

$kubectl get pod
NAME                              READY   STATUS    RESTARTS   AGE
hello-minikube-6ddfcc9757-qlvnh   1/1     Running   0          8s

$kubectl get pod -o wide
NAME                              READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
hello-minikube-6ddfcc9757-qlvnh   1/1     Running   0          14s   172.17.0.3   minikube   <none>           <none>

$kubectl get svc hello-minikube
NAME             TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
hello-minikube   NodePort   10.107.203.179   <none>        8080:32536/TCP   29s

$minikube service hello-minikube 
|-----------|----------------|-------------|-----------------------------|
| NAMESPACE |      NAME      | TARGET PORT |             URL             |
|-----------|----------------|-------------|-----------------------------|
| default   | hello-minikube |        8080 | http://192.168.99.103:32536 |
|-----------|----------------|-------------|-----------------------------|
🎉  Opening service default/hello-minikube in default browser...

$ kubectl port-forward service/hello-minikube 
Forwarding from 127.0.0.1:7080 -> 8080
Forwarding from [::1]:7080 -> 8080
Handling connection for 7080
Handling connection for 7080
^C%        

$minikube delete --all
🔥  Deleting "minikube" in virtualbox ...
💀  Removed all traces of the "minikube" cluster.
🔥  Successfully deleted all profiles
```

อ้างอิงเพิ่งเติมตามนี้ link นี้
https://minikube.sigs.k8s.io/docs/

create by bugstum