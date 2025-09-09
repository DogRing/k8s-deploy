helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm show values prometheus-community/kube-prometheus-stack > values.yaml

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f values.yaml

kubectl patch deployment prometheus-grafana -n monitoring -p '{"spec":{"template":{"spec":{"containers":[{"name":"grafana","env":[{"name":"GF_SERVER_ROOT_URL","value":"https://grafana.dogring.kr"},{"name":"GF_SERVER_SERVE_FROM_SUB_PATH","value":"false"}]}]}}}}'

# helm repo add minio https://charts.min.io/
# helm repo update
# helm show values minio/minio > values.yaml

# helm upgrade --install minio minio/minio \
#   -n minio \
#   --create-namespace \
#   -f values.yaml


helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm show values grafana/loki > values.yaml
helm upgrade --install loki grafana/loki \
  -n loki --create-namespace \
  -f v

helm show values grafana/promtail > values.yaml
helm upgrade --install promtail grafana/promtail \
  --namespace loki \
  -f v

kubectl label --overwrite namespace loki \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged