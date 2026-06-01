#!/bin/bash
echo "🚀 Setting up Kubernetes Runtime Threat Detection Environment..."

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "----------------------------------------"
echo "[1/4] Creating kind cluster..."
kind create cluster --config cluster/kind-config.yaml

echo "----------------------------------------"
echo "[2/4] Adding Falco Helm repository..."
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

echo "----------------------------------------"
echo "[3/4] Installing Falco & Falcosidekick UI..."
helm install falco falcosecurity/falco \
  --namespace falco-system \
  --create-namespace \
  -f falco/values.yaml \
  -f falco/custom-rules.yaml \
  --set falcosidekick.enabled=true \
  --set falcosidekick.webui.enabled=true

echo "----------------------------------------"
echo "[4/4] Waiting for Falco pods to initialize..."
echo "(This may take a few minutes while the eBPF probe is downloaded and UI images are pulled)"
kubectl wait --for=condition=Ready pods --all -n falco-system --timeout=300s

echo "----------------------------------------"
echo "✅ Setup Complete!"
echo "Run ./start-dashboard.sh to access the UI."
