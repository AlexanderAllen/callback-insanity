# Print Helm version.
helm version

# Create CRDs - Custom Resource Definitions.
kubectl apply -f cert-man-crds.yml

# Add a label to the kube-system namespace, where we’ll install cert-manager
# to enable advanced resource validation using a webhook.
kubectl label namespace kube-system certmanager.k8s.io/disable-validation="true"

# Add the Jetstack Helm repository to Helm. This repository contains the cert-manager Helm chart.
helm repo add jetstack https://charts.jetstack.io

# Finally, we can install the chart into the kube-system namespace:
helm install --name cert-manager --namespace kube-system jetstack/cert-manager --version v0.8.0

# Create both production and testing certificate ClusterIssuer objects.
kubectl apply -f staging-issuer.yml
kubectl apply -f prod-issuer.yml

# Apply TLS to ingress.
kubectl apply -f ../ingress/ghost-ingress-tls-prod.yml

# Use kubectl describe to track the state of the Ingress changes you've just applied:
kubectl describe ingress
kubectl describe certificate

