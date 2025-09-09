helm repo add immich https://immich-app.github.io/immich-charts
helm repo update

helm show values oci://ghcr.io/immich-app/immich-charts/immich > 12.immich/values.yaml

helm upgrade --install --create-namespace --namespace immich \
  immich oci://ghcr.io/immich-app/immich-charts/immich \
  -f values.yaml