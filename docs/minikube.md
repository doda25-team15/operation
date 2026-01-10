# MiniKube Deployment Guide

This guide provides instructions on how to deploy the SMS Spam Checker application on a local Kubernetes cluster using MiniKube.

### Prerequisites

- Docker
- Minikube
- Kubectl
- Helm

### 1. Start Minikube Cluster

```bash
minikube start --driver=docker
minikube addons enable ingress
```

Wait for ingress controller to be ready:

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### 2. Setup Model Files

The model service requires trained model files. You can use the example model files provided in the `model/` directory of this repository. See [operation/model/README.md](./model/README.md) for details. Or use the trained model files from the [releases page](https://github.com/doda25-team15/model-service/releases). Once obtained, copy them to the minikube mounted volume:

1. Create directory in minikube
   ```bash
   minikube ssh "sudo mkdir -p /mnt/shared/output"
   ```

2. Copy model files
   ```bash
   minikube cp ./model/model.joblib /mnt/shared/output/model.joblib
   minikube cp ./model/preprocessor.joblib /mnt/shared/output/preprocessor.joblib
   ```

3. Verify the files are copied
   ```bash
   minikube ssh "ls -lh /mnt/shared/output/"
   ```

Do the same for the canary and shadow models: `/mnt/shared/output-canary/` and `/mnt/shared/output-shadow/`.

### 3. Deploy with Helm

```bash
helm install sms-checker ./helm_chart --dependency-update
```

Verify all pods are running and ready before proceeding with next steps:
```bash
kubectl get pods
```