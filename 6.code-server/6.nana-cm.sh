SECRET_NAME=$(kubectl get serviceaccount nana-user -n default -o jsonpath='{.secrets[0].name}')
TOKEN=$(kubectl get secret $SECRET_NAME -n default -o jsonpath='{.data.token}' | base64 --decode)

CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA_CERT=$(kubectl get secret $SECRET_NAME -n default -o jsonpath='{.data.ca\.crt}')

cat << EOF > nana-user-kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CA_CERT}
    server: ${CLUSTER_SERVER}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    user: nana-user
  name: nana-user-context
current-context: nana-user-context
users:
- name: nana-user
  user:
    token: ${TOKEN}
EOF

kubectl create configmap nana-user-kubeconfig --from-file=config=nana-user-kubeconfig.yaml -n code-server