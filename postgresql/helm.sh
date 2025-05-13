sudo helm upgrade --install --kubeconfig ~/.kube/config postgres -n postgres --create-namespace .

helm upgrade postgresql bitnami/postgresql \
  --set resources.requests.cpu=1 \
  --set resources.limits.cpu=2 \
  --set resources.requests.memory=2Gi \
  --set resources.limits.memory=4Gi

postgres-postgresql.postgres.svc.cluster.local

export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgres postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

kubectl run postgres-postgresql-client --rm --tty -i --restart='Never' --namespace postgres --image docker.io/bitnami/postgresql:17.4.0-debian-12-r15 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
  --command -- psql --host postgres-postgresql -U postgres -d postgres -p 5432