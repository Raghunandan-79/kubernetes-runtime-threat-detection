#!/bin/bash
echo "🚀 Starting automated Kubernetes attack simulations..."

echo "----------------------------------------"
echo "[Attack 1] Launching Privileged Container..."
kubectl apply -f simulations/02-privileged-pod.yaml
sleep 2

echo "----------------------------------------"
echo "[Attack 2] Reading Sensitive Files..."
kubectl apply -f simulations/03-sensitive-file-read.yaml
sleep 2

echo "----------------------------------------"
echo "[Attack 3] Making Suspicious Network Connection..."
kubectl apply -f simulations/04-suspicious-network.yaml
sleep 2

echo "----------------------------------------"
echo "[Attack 4] Attempting Container Escape..."
kubectl apply -f simulations/05-container-escape.yaml
sleep 2

echo "----------------------------------------"
echo "[Attack 5] Modifying Critical Files..."
kubectl apply -f simulations/06-file-modification.yaml
sleep 2

echo "----------------------------------------"
echo "[Attack 6] Executing Unexpected Binary..."
kubectl apply -f simulations/07-unexpected-binary.yaml
sleep 2

echo "----------------------------------------"
echo "✅ Automated attacks deployed!"
echo "Check your Falcosidekick UI to view the real-time alerts."
