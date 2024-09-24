curl -L https://istio.io/downloadIstio | sh -
sudo mv istio-1.23.2 /usr/lib/
export PATH=/usr/lib/istio-1.23.2/bin:$PATH

istioctl operator init
kubectl create ns istio-system

kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: default
EOF

## delete 
kubectl delete istiooperators.install.istio.io -n istio-system example-istiocontrolplane
istioctl operator remove --revision <revision> #default
istioctl uninstall -y --purge
kubectl delete ns istio-system istio-operator