# Team 15

Emīls Dzintars, Frederik van der Els, Riya Gupta, Arjun Rajesh Nair, Jimmy Oei, Sneha Prashanth

## Operation Repository

https://github.com/doda25-team15/operation/tree/a3

## Model Service (Backend) Repository

https://github.com/doda25-team15/model-service/tree/a3
**Workflows**:

- Release workflow: workflow consisting of two jobs: training the model and releasing the Docker image for the model-service.

**Configuration (Dockerfile env variables):**

- `PORT`: Server port (default: 8081)

**Notes**:

- The service expects the model files to be available at `/app/output`, which is mounted from the host's `/mnt/shared/output` directory. If not found there, it will attempt to download them from GitHub Releases.

## App (Frontend) Repository

https://github.com/doda25-team15/app/tree/a3

**Workflows**:

- Release workflow: releases Docker image for the app service on

**Configuration (Dockerfile env variables):**

- `PORT`: Server port (default: 8080)
- `MODEL_SERVICE_URL`: URL to the model-service endpoint (default: http://localhost:8081)

**Notes**:

- We used Gradle to build the app instead of Maven.

## Lib Repository

https://github.com/doda25-team15/lib-version/tree/a3

**Workflows**:

- Release workflow: builds and releases the library.

**Notes**:

- Uses Gradle instead of Maven.

## Run the application

To run the project make sure Docker is installed.

You can run the project using docker-compose.yml file. Just go to the operation directory and write the following commands:

```bash
docker compose up
```

The configuration can be customized by setting the environment variables in the `.env` file.

# Provisioning the Kubernetes Cluster

Ensure you have Vagrant and VirtualBox installed to do the provisioning.
The configuration of the provisioning can be customized by setting the environment variables in the `.env` file.

### 1. Provision VMs and Initialize Cluster

Start the Vagrant environment to provision the controller and worker nodes:

```bash
vagrant up
```

This will:

- Create the controller VM (`ctrl`) and worker VMs (`node-1`, `node-2`)
- Run general setup (Step 1-12)
- Initialize the Kubernetes cluster on the controller (Step 13-17)
- Join worker nodes to the cluster (Step 18-19)

### 2. Verify Cluster Status

Check that all nodes have joined the cluster successfully:

```bash
vagrant ssh ctrl
kubectl get nodes
```

You should see all nodes (`ctrl`, `node-1`, `node-2`) with status `Ready`.

### 3. Finalize Cluster Setup

After the VMs are provisioned and the cluster is initialized, run the `finalization.yml` playbook to install MetalLB and the Nginx Ingress Controller:

```bash
ansible-playbook -u vagrant -i 192.168.56.100, finalization.yml
```

This will:

- Install MetalLB for load balancing (Step 20)
- Configure IP address pool (192.168.56.90-99)
- Install Nginx Ingress Controller (Step 21) at IP 192.168.56.90
- Deploy Kubernetes Dashboard (Step 22)

### 4. Access the Cluster

You can now access your Kubernetes cluster from the host machine:

```bash
# Using the exported kubeconfig
export KUBECONFIG=./admin.conf
kubectl get nodes

# or directly:
kubectl --kubeconfig=./admin.conf get nodes
```

### 5. Access Kubernetes Dashboard

!!! NOTE step 22 is not final yet, there is some issue with authorization into the dashboard but the dashboard is deployed.

You can access the Kubernetes Dashboard by navigating to the following URL in your web browser:

```
http://dashboard.192.168.56.90.nip.io
```

Use the `admin-user` ServiceAccount token to log in. You can create one token by executing the following command when ssh'd into the `ctrl`:

```bash
# ssh into ctrl
vagrant ssh ctrl

# Create token for admin-user
kubectl -n kubernetes-dashboard create token admin-user
```

Currently metalLB is not working. To see website port-forwarding is required:

```bash
kubectl expose deployment app-service \
  --type=NodePort \
  --name=app-np \
  --port=8080

kubectl get svc app-np

#you will get something like
8080:3xxxx/TCP
#copy 3xxxx

```

write in the browser http://192.168.56.100:<3xxxx>

---

# Kubernetes Cluster Deployment

## Prerequisites

- kubectl
- minikube
- helm 3.x
- Docker running locally
- Nginx Ingress Controller

## Start Kubernetes Cluster

Start cluster:

```
minikube start --driver=docker
```

Enable Ingress:

```
minikube addons enable ingress
```

Wait for Ingress Controller:

```
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

## Setup Model Files Volume Mount

The model-service requires trained model files (`model.joblib` and `preprocessor.joblib`). These files need to be available in the shared volume before deploying the application.

**Setup steps for minikube:**

1. Get the model files. You can either train the model yourself, or download a trained model form the GitHub Releases page https://github.com/doda25-team15/model-service/releases.

2. Create the shared volume directory in minikube:

```bash
minikube ssh "sudo mkdir -p /mnt/shared/output"
```

3. Copy the model files to minikube:

```bash
minikube cp <path to model files on your system>/model.joblib /mnt/shared/output/model.joblib

minikube cp <path to model files on your system>/preprocessor.joblib /mnt/shared/output/preprocessor.joblib
```

4. Verify the files are present:

```bash
minikube ssh "ls -lh /mnt/shared/output/"
```

## Deploy Using Kubernetes Manifests (k8s)

```bash
kubectl apply -f k8s -R
```

To verify:

```bash
kubectl get pods
kubectl get svc
kubectl get ingress
```

## Access Application

Add hostname:

```bash
echo "127.0.0.1 sms-checker-app" | sudo tee -a /etc/hosts
```

Port-forward Ingress Controller using kubectl:

```bash
kubectl port-forward -n ingress-nginx \
  service/ingress-nginx-controller 8080:80
```

Open in browser:

```bash
http://sms-checker-app:8080/sms/
```

## Deployment using Helm

Install with Helm:

```bash
cd helm_chart
helm install sms-checker .
```

Check release:

```bash
helm status sms-checker
kubectl get all
```

Open in browser:

```bash
http://sms-checker-app:8080/sms/
```

## Customise Helm Deployment

### Examples

Change number of replicas:

```
helm install sms-checker . --set replicaCount.app=5
```

Change Ingress hostname:

```
helm install sms-checker . --set ingress.host=myapp.local
```

Inject SMTP Credentials:

```
helm install sms-checker . \
  --set secret.smtpUser="abc@mail" \
  --set secret.smtpPass="secret"
```

Disable Ingress:

```
helm install sms-checker . --set ingress.enabled=false
```

**Verify changes:**

```
# Check replica count
kubectl get pods -l component=app
# Check hostname
kubectl get ingress app-ingress -o jsonpath='{.spec.rules[0].host}'
```

## Testing the Deployment

Check pods:

```
kubectl get pods
```

Tail logs:

```
kubectl logs -l app=sms-checker
```

Verify ConfigMap is mounted:

```
kubectl exec deploy/app-deployment -- env | grep MODEL_HOST
```

Verify Ingress:

```
kubectl describe ingress
```

## Additional Functionality

Upgrade:

```
helm upgrade sms-checker .
```

Rollback:

```
helm rollback sms-checker
```

Uninstall:

```
helm uninstall sms-checker
```

## Prometheus Monitoring

We use Prometheus from the kube-prometheus-stack Helm chart to automatically collect metrics from the app and model services via ServiceMonitor resources defined in this chart.

1. Port-forward the Prometheus service:

```bash
kubectl port-forward svc/sms-checker-monitoring-prometheus 9090:9090
```

2. Open Prometheus in your browser:

```bash
http://localhost:9090
```

4. Go to Status → Target health and confirm that the targets created by the ServiceMonitors are UP (job names containing sms-checker).
5. In the Query tab, you can run queries for the custom metrics exposed by the app:

- `sms_requests_total` (Counter): Total number of SMS requests completed
- `sms_requests_inflight` (Gauge): Current number of SMS requests being processed
- `sms_request_latency_seconds` (Histogram): How long each SMS request took to complete

## Grafana Dashboards

After installation, access Grafana:

1. Port-forward to Grafana service:

```bash
kubectl port-forward svc/sms-checker-grafana 3000:80
```

1. Open browser to `http://localhost:3000`

2. Default credentials (from kube-prometheus-stack):
   - Username: `admin`
   - Password: Get it with:

```bash
kubectl get secret sms-checker-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

3. You can now check the pre-configured dashboards:

- SMS Checker - Custom Metrics Dashboard
