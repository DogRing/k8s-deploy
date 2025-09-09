helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm show values ingress-nginx/ingress-nginx > values.yaml

helm upgrade --install ingress-nginx ingress-nginx `
  --repo https://kubernetes.github.io/ingress-nginx `
  --namespace ingress-nginx --create-namespace `
  --set controller.allowSnippetAnnotations=true


helm upgrade --install ingress-nginx ingress-nginx `
  --repo https://kubernetes.github.io/ingress-nginx `
  --namespace ingress-nginx --create-namespace `
  --set controller.allowSnippetAnnotations=true `
  --set controller.service.type=LoadBalancer `
  --set controller.service.loadBalancerClass="io.cilium/l2-announcer" `
  --set controller.service.annotations."lbipam\.cilium\.io/ips"="192.168.0.241" `
  --set controller.admissionWebhooks.enabled=false

