kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl edit deployments.apps -n kube-system metrics-server

spec:
  template:
    spec:
      containers:
        args:
        - --kubelet-insecure-tls
        - --kubelet-preferred-address-types=InternalIP, ExternalIP, Hostname