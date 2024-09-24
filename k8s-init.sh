sudo apt -y update
sudo ufw status
sudo swapoff -a
free
sudo sed -i '/ swap / s/^/#/' /etc/fstab
sudo vi /etc/fstab
sudo apt -y install ntp
sudo systemctl restart ntp
sudo systemctl status ntp
sudo ntpq -p

sudo sysctl -w net.ipv4.ip_forward=1
sudo cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
sudo cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
# apt-cache policy docker-ce # Candidate 버전

# 
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo sh -c "containerd config default > /etc/containerd/config.toml"   # 기본 컨테이너 설정을 toml 파일로 만듦 "disabled_plugins = []" 이어야 함
sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml # SystemdCgroup 을 true로 만들어 줌
sudo systemctl restart containerd.service

# k8s의 daemon 자체에 서비스를 기본 cgroup native로 설정
sudo cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo usermod -aG docker dogring232
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl restart docker
sudo systemctl status docker
sudo systemctl restart containerd.service
sudo systemctl status containerd.service

sudo reboot

docker info # Cgroup Driver: systemd 확인

# k8s v1.28
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key |
sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | 
sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update

sudo apt-cache policy kubeadm

# kubelet: 데몬(노드간 통신) / kubeadm: 초기화, 업그레이드, join 등 / kubectl: 모든 작업
sudo apt -y install kubelet kubeadm kubectl

# 모두 버전이 맞는지 확인
kubeadm version
kubectl version
kubelet --version 

# apt의 자동 업데이트 방지
sudo apt-mark hold kubelet kubeadm kubectl

# kubelet start 상태 유지
sudo systemctl daemon-reload
sudo systemctl restart kubelet.service
sudo systemctl enable --now kubelet.service

# node host 입력 <ip> <nodename>
sudo vi /etc/hosts

# pod-network-cidr(10.x.x.x) 기본값=10.96.0.0/12 
# apiserver-advertise-address 는 수신 대기 중임을 알릴 IP 주소. Master node의 IP 주소 설정
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.0.12
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

sudo apt install bash-completion -y
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
complete -F __start_kubectl k
echo "alias k=kubectl
alias kg='kubectl get'
alias kc='kubectl create'
alias ka='kubectl apply'
alias kr='kubectl run'
alias kd='kubectl delete'
complete -F __start_kubectl k" >> ~/.bashrc

# calico 설치
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
# flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# dashboard 설치
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

## Dashboard 생성을 위한 SA 생성과 권한 부여 namespace: dashboard 에 만들어 놓음
mkdir dashboard_rbac && cd $_
echo "apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
" > dashboard-admin-user.yaml

echo "apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
" > ClusterRoleBinding-admin-user.yml

kubectl apply -f dashboard-admin-user.yaml
kubectl apply -f ClusterRoleBinding-admin-user.yml

# SA 토큰 확인
kubectl -n kubernetes-dashboard create token admin-user

# cert와 key 생성
grep 'client-certificate-data' ~/.kube/config | head -n 1 | awk '{print $2}' | base64 -d >> kubecfg.crt
grep 'client-key-data' ~/.kube/config | head -n 1 | awk '{print $2}' | base64 -d >> kubecfg.key

# 키를 기반으로 p12 인증서 파일 생성 (인증서 암호 설정)
openssl pkcs12 -export -clcerts -inkey kubecfg.key -in kubecfg.crt -out kubecfg.p12 -name "kubernetes-admin"

# 클러스터 생성시 가지는 인증서
sudo cp /etc/kubernetes/pki/ca.crt  ./

# kubeshark
sh <(curl -Ls https://kubeshark.co/install)
ks tap --proxy-host 0.0.0.0 # 클러스터 내 패패킷을 캡쳐

helm repo add kubeshark https://helm.kubeshark.co
helm install kubeshark kubeshark/kubeshark -n kubeshark
kubectl port-forward -n kubeshark service/kubeshark-front 8899:80

sudo mkdir -p /DATA1
# kubectl create ns portainer
echo "apiVersion: v1
kind: PersistentVolume
metadata:
  name: portainer-pv
  namespace: portainer
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  local:
    path: /DATA1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - {key: kubernetes.io/hostname, operator: In, values: [vm-gpu-node-0]}
" > portainer-pv.yaml
kubectl apply -n portainer -f portainer-pv.yaml
# /DATA1 의 경로가 없을 수 있다. 

# Portainer LB
kubectl apply -n portainer -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer-lb.yaml

# Portainer Nodeport
kubectl apply -n portainer -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer.yaml

# portainer 창 오류 시
kubectl rollout restart deployment -n portainer portainer

# Prometheus
git clone https://github.com/brayanlee/k8s-prometheus.git

kc -f prometheus/prometheus-Deployment.yaml
kc -f kube-state/kube-state-Deployment.yaml
kc -f grafana/grafana-Deployment.yaml

# Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring

# k9s
wget https://github.com/derailed/k9s/releases/download/v0.26.7/k9s_Linux_x86_64.tar.gz
tar zxvf k9s_Linux_x86_64.tar.gz
sudo mv k9s /usr/local/bin/k9s



# GPU
kubectl create ns gpu-operator
kubectl label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia \
    && helm repo update
helm install --wait --generate-name \
    -n gpu-operator --create-namespace \
    nvidia/gpu-operator