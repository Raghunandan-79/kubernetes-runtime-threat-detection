# !/bin/bash
echo "Starting Falcosidekick Dashboard Port-Forward..."
echo "Once started, open http://localhost:2802 in your browser."
kubectl port-forward svc/falco-falcosidekick-ui -n falco-system 2802:2802