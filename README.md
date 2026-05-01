# Kubernetes Runtime Threat Detection with Falco

This project demonstrates a real-time Kubernetes runtime threat detection system using **Falco** deployed as a DaemonSet within a local **kind** cluster. It detects common container security threats, leveraging eBPF (Extended Berkeley Packet Filter) to trace system calls and evaluate them against custom security rules.

## Project Goals

- Deploy Falco inside a kind Kubernetes cluster via Helm.
- Configure Falco to use the `modern_bpf` driver.
- Implement custom detection rules for common container attacks.
- Provide reproducible attack simulations.

## Detection Scenarios

The system is configured to detect the following scenarios:
1. **Shell access inside containers** (`kubectl exec`)
2. **Privileged container execution**
3. **Access to sensitive files** (e.g., `/etc/shadow`)
4. **Suspicious outbound network connections** (e.g., `netcat`)
5. **Container escape attempts** (e.g., host filesystem mount)
6. **Modification of critical files** (e.g., `/etc/passwd`)
7. **Execution of unexpected binaries inside containers** (e.g., run from `/tmp`)

## Prerequisites

- **Linux OS** with Kernel version >= 5.8 (for `modern_bpf` support)
- [Docker](https://docs.docker.com/get-docker/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) (Kubernetes in Docker)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)

---

## 🚀 Setup Instructions

### 1. Create the kind Cluster
Create a local cluster using the provided configuration:
```bash
kind create cluster --config cluster/kind-config.yaml
```
Verify the cluster is running:
```bash
kubectl get nodes
```

### 2. Add Falco Helm Repository
```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
```

### 3. Deploy Falco
Install Falco via Helm using the provided configuration files. The `modern_bpf` driver is used here to avoid compiling kernel modules.

```bash
helm install falco falcosecurity/falco \
  --namespace falco-system \
  --create-namespace \
  -f falco/values.yaml \
  -f falco/custom-rules.yaml
```

Wait for the Falco pods to be ready:
```bash
kubectl get pods -n falco-system -w
```

### 4. Monitor Falco Logs
Keep a terminal window open to monitor the Falco output. Since Falco outputs raw JSON by default in this project, you can pipe it to `jq` for pretty printing:
```bash
kubectl logs -l app.kubernetes.io/name=falco -n falco-system -c falco -f | jq .
```

### 5. Access the Falcosidekick Dashboard
This project includes the Falcosidekick Web UI to visualize security events in a beautiful dashboard. To access it, run a port-forward:
```bash
kubectl port-forward svc/falco-falcosidekick-ui -n falco-system 2802:2802
```
Then open your browser and navigate to: http://localhost:2802

---

## ⚔️ Attack Simulations

In a separate terminal window, run the following commands to simulate attacks and verify the detection.

### Scenario 1: Shell Access and Interactive Attacks (`kubectl exec`)
Run a pod and exec into it to simulate an attacker gaining a reverse shell:
```bash
kubectl run innocent-pod --image=ubuntu --command -- sleep infinity
kubectl exec -it innocent-pod -- /bin/bash
```
**Expected Falco Alert:**
`Notice A shell was spawned in a container with an attached terminal...`

**Interactive Attack Simulation:**
While inside the `innocent-pod` bash shell, run the following commands to trigger real-time alerts in the Falcosidekick Dashboard:
```bash
# 1. Attempt to read sensitive credentials
cat /etc/shadow

# 2. Modify critical system files (Establish Persistence)
echo "hacker:x:0:0::/root:/bin/bash" >> /etc/passwd

# 3. Execute a binary from a writable directory
cp /bin/ls /tmp/ls
/tmp/ls

# 4. Make an unexpected outbound network connection (C2 Communication)
apt-get update && apt-get install -y curl
curl http://example.com
```
Type `exit` when you are finished.

### Scenario 2: Privileged Container Execution
```bash
kubectl apply -f simulations/02-privileged-pod.yaml
```
**Expected Falco Alert:**
`Warning Privileged container launched...`

### Scenario 3: Access to Sensitive Files
```bash
kubectl apply -f simulations/03-sensitive-file-read.yaml
```
**Expected Falco Alert:**
`Warning Sensitive file opened for reading by non-trusted program... file=/etc/shadow`

### Scenario 4: Suspicious Outbound Network Connections
```bash
kubectl apply -f simulations/04-suspicious-network.yaml
```
**Expected Falco Alert:**
`Warning Suspicious network connection from container... command=nc -z 8.8.8.8 53`

### Scenario 5: Container Escape Attempts (Host Filesystem)
```bash
kubectl apply -f simulations/05-container-escape.yaml
```
**Expected Falco Alert:**
`Warning Container launched with host filesystem mounted...`

### Scenario 6: Modification of Critical Files
```bash
kubectl apply -f simulations/06-file-modification.yaml
```
**Expected Falco Alert:**
`Warning File below /etc opened for writing... file=/etc/passwd`

### Scenario 7: Execution of Unexpected Binaries
```bash
kubectl apply -f simulations/07-unexpected-binary.yaml
```
**Expected Falco Alert:**
`Warning Unexpected binary executed from writable directory... path=/tmp/ls`

---

## 🐛 Troubleshooting

- **Falco pod CrashLoopBackOff**: If the falco pod fails to start, verify your kernel version supports `modern_bpf` (`uname -r` should be >= 5.8). If you have an older kernel, you may need to switch to the `ebpf` driver in `falco/values.yaml` and install kernel headers on your host.
- **Alerts not triggering**: Ensure the pods are successfully running. Use `kubectl get pods` to check for ImagePullBackOff or other errors. 
- **View Falco events without JSON**: Remove the `json_output: true` line in `falco/values.yaml` and upgrade the helm release: `helm upgrade falco falcosecurity/falco -n falco-system -f falco/values.yaml -f falco/custom-rules.yaml`.

## Cleanup
To clean up the environment, delete the kind cluster:
```bash
kind delete cluster
```
