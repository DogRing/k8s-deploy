sudo apt update
sudo apt install bash-completion vim -y
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
complete -F __start_kubectl k
echo "KUBE_EDITOR=vim
alias k=kubectl
alias kg='kubectl get'
alias kc='kubectl create'
alias ka='kubectl apply'
alias kr='kubectl run'
alias kd='kubectl delete'
complete -F __start_kubectl k" >> ~/.bashrc
. ~/.bashrc

git config --global user.name "DogRing"
git config --global user.email "changh232@naver.com"