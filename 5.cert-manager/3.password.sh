sudo apt-get install apache2-utils
sudo htpasswd -c auth dogring # 사용할 id, password 입력
kubectl create secret generic code-auth --from-file=auth -n code-server
