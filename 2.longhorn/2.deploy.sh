kubectl create namespace longhorn

helm repo add longhorn https://charts.longhorn.io
helm repo update

helm show values longhorn/longhorn > values.yaml

helm upgrade --install longhorn longhorn/longhorn --namespace longhorn --create-namespace -f values.yaml

kubectl get volumes.longhorn.io -n longhorn
kubectl describe volumes.longhorn.io -n longhorn <볼륨이름> 


kubectl -n longhorn edit settings.longhorn.io deleting-confirmation-flag  
### ture 로 변경
helm uninstall longhorn -n longhorn