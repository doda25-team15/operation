# DODA 2025 - Team 15

**Team Members:** Emīls Dzintars, Frederik van der Els, Riya Gupta, Arjun Rajesh Nair, Jimmy Oei, Sneha Prashanth

### Repositories

- **[Operation](https://github.com/doda25-team15/operation)** - Kubernetes deployment & infrastructure
- **[App (Frontend)](https://github.com/doda25-team15/app)** - Java Spring Boot application that communicates with the model-service for predictions on SMS spam detection
- **[Model Service](https://github.com/doda25-team15/model-service)** - Python Flask ML service that serves the trained spam detection model
- **[Library](https://github.com/doda25-team15/lib-version)** - A lightweight library for managing and retrieving the application version

---

## Operation Repository Structure

- `/ansible` - Ansible playbooks for Vagrant cluster provisioning
- `/helm_chart` - Helm chart for Helm deployment
- `/k8s` - Raw Kubernetes manifests for raw Kubernetes deployment
- `/model` - Example model to provide/mount to deployments
- `.env` - Environment variables for Vagrant/Ansible and Docker Compose deployments
- `docker-compose.yml` - Docker Compose configuration for docker local deployment
- `ACTIVITY.md` - Team activity log
- `management.md` - Useful management and troubleshooting commands
- `README.md` - This file
- `vagrantfile` - Vagrant configuration for VM provisioning

## Run the application

There are multiple deployment strategies available to run the SMS Spam Checker application:

1. [Helm Chart Deployment (Recommended)](#helm-chart-deployment-recommended)
2. [Kubernetes Manifests Deployment](#kubernetes-manifests-deployment)
3. [Docker Compose Deployment](#docker-compose-deployment)
4. [Vagrant and Ansible Deployment](#vagrant-and-ansible-deployment)

_Note:_ For the Kubernetes deployments we are using minikube as the local Kubernetes cluster. If you use some other Kubernetes cluster, make sure to adapt the instructions according to your setup.

## Helm Chart Deployment (Recommended)

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

```bash
# 1. Create directory in minikube
minikube ssh "sudo mkdir -p /mnt/shared/output"
```

````bash
# 2. Copy model files
minikube cp ./model/model.joblib /mnt/shared/output/model.joblib
minikube cp ./model/preprocessor.joblib /mnt/shared/output/preprocessor.joblib

```bash
# 3. Verify the files are copied
minikube ssh "ls -lh /mnt/shared/output/"
````

### 3. Deploy with Helm

```bash
helm dependency build
helm install sms-checker ./helm_chart
```

### 4. Access

### Application

To access the application, add an entry to your `/etc/hosts` file:

```bash
echo "127.0.0.1 sms-checker-app" | sudo tee -a /etc/hosts
```

Port-forward the Nginx Ingress Controller:

```bash
# Using kubectl
kubectl port-forward -n ingress-nginx \
  service/ingress-nginx-controller 8080:80

# Or using minikube
minikube service ingress-nginx-controller -n ingress-nginx --url
```

Now you can open:

- Frontend Application: http://sms-checker-app:8080/sms
- Application Metrics: http://sms-checker-app:8080/metrics

### Prometheus Monitoring

We use Prometheus from the kube-prometheus-stack Helm chart to automatically collect metrics from the app and model services via ServiceMonitor resources defined in this chart.

1. Port-forward the Prometheus service:

```bash
# Using kubectl
kubectl port-forward svc/sms-checker-monitoring-prometheus 9090:9090

# Or using minikube
minikube service sms-checker-monitoring-prometheus --url
```

2. Open Prometheus in your browser:

- http://localhost:9090

1. Go to Status → Target health and confirm that the targets created by the ServiceMonitors are UP (job names containing sms-checker).
2. In the Query tab, you can run queries for the custom metrics exposed by the app:

- `sms_requests_total` (Counter): Total number of SMS requests completed
- `sms_requests_inflight` (Gauge): Current number of SMS requests being processed
- `sms_request_latency_seconds` (Histogram): How long each SMS request took to complete

### Grafana Dashboards

1. Port-forward the Grafana service:

```bash
# Using kubectl
kubectl port-forward svc/sms-checker-grafana 3000:80

# Or using minikube
minikube service sms-checker-grafana --url
```

1. Open Grafana in your browser at `http://localhost:3000`

2. Default credentials (from kube-prometheus-stack):
   - Username: `admin`
   - Password: Get it with:

```bash
kubectl get secret sms-checker-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

3. You can now check the pre-configured dashboards:

- SMS Checker - Custom Metrics Dashboard

## Kubernetes Manifests Deployment

### Prerequisites

- Docker
- Kubectl
- Minikube

### 1. Start Minikube Cluster

See [Helm Chart Deployment -> Step 1](#1-start-minikube-cluster)

### 2. Setup Model Files

See [Helm Chart Deployment -> Step 2](#2-setup-model-files)

### 3. Deploy using Kubernetes Manifests

```bash
kubectl apply -f k8s/ -R
```

### 4. Access

### Application

See [Helm Chart Deployment -> Access -> Application](#application).

_Note:_ Prometheus and Grafana are not included when deploying using Kubernetes manifests.

## Docker Compose Deployment

This will run a local development deployment, without a Kubernetes cluster.

_Note:_ This will use the model files in the `model/` directory. If you want to use default model files or test this logic, then you can clear the `model/` directory before starting the deployment. When there are no model files, the model service will download them from the latest release on GitHub.

### Prerequisites

- Docker

### 1. Docker Compose

```bash
docker compose up
```

### Vagrant and Ansible Deployment

This will provision a Kubernetes cluster on VirtualBox VMs using Vagrant and Ansible.

### Prerequisites

- Vagrant
- VirtualBox
- Ansible

### 1. Provision VMs and Initialize Cluster

```bash
vagrant up
```

```bash
# Verify cluster status in ctrl (all nodes should be Ready)
vagrant ssh ctrl
kubectl get nodes
```

### 2. Finalize Cluster Setup

After the VMs are provisioned and the cluster is initialized, run the `finalization.yml` playbook to install MetalLB, Nginx Ingress Controller and Kubernetes Dashboard. Make sure you don't run this command from within the `ctrl` VM, but from your host machine:

```bash
ansible-playbook -u vagrant -i 192.168.56.100, finalization.yml
```

### 3. Access

### Cluster

You can now access the Kubernetes cluster from the host machine:

```bash
# Using the exported kubeconfig
export KUBECONFIG=./admin.conf
kubectl get nodes

# or directly:
kubectl --kubeconfig=./admin.conf get nodes
```

### Application

TODO: How to access the application when deployed using Vagrant and Ansible?

### Kubernetes Dashboard

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
