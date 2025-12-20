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

There are multiple ways to run the SMS Spam Checker application:

1. [Helm Chart Deployment (Recommended)](#helm-chart-deployment-recommended)
2. [Kubernetes Manifests Deployment](#kubernetes-manifests-deployment)
3. [Docker Compose](#docker-compose-deployment)
4. [Vagrant and Ansible Provisioning](#vagrant-and-ansible-provisioning)

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

```bash
# 2. Copy model files
minikube cp ./model/model.joblib /mnt/shared/output/model.joblib
minikube cp ./model/preprocessor.joblib /mnt/shared/output/preprocessor.joblib
```

```bash
# 3. Verify the files are copied
minikube ssh "ls -lh /mnt/shared/output/"
```

### 3. Deploy with Helm

```bash
helm dependency build ./helm_chart
helm install sms-checker ./helm_chart
```

```bash
# Verify all pods are running and ready before proceeding with next steps
kubectl get pods
```

### 4. Access

### Application

To access the application, add an entry to your `/etc/hosts` file:

```bash
kubectl get svc -n istio-system istio-ingressgateway
```

```bash
echo "<external ip> sms-checker-app" | sudo tee -a /etc/hosts
```

See the `management.md` file for instructions on how to change the hostname.

If the external IP is pending, you have to Port-forward the Istio Ingress Controller:

```bash
# Using kubectl
kubectl port-forward -n istio-system \
  service/istio-ingressgateway 8080:80

# Or using minikube
minikube service istio-ingressgateway -n istio-system --url
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

1. Open Prometheus in your browser http://localhost:9090

2. Go to Status → Target health and confirm that the targets created by the ServiceMonitors are UP (job names containing sms-checker).
3. In the Query tab, you can run queries for the custom metrics exposed by the app:

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

1. Open Grafana in your browser at http://localhost:3000

2. Default credentials (from kube-prometheus-stack):
   - Username: `admin`
   - Password: Get it with:

```bash
kubectl get secret sms-checker-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

3. You can now check the pre-configured dashboards:

- SMS Checker - Custom Metrics Dashboard

### Traffic Management using Istio

```bash
minikube delete
minikube start --memory=8192 --cpus=4
minikube addons enable istio-provisioner
minikube addons enable istio
minikube addons enable ingress


kubectl label namespace default istio-injection-
helm uninstall sms-checker
helm install sms-checker .
kubectl label namespace default istio-injection=enabled
kubectl rollout restart deployment
```

Wait for all pods to run

```bash
kubectl get pods
```

Make sure app pods have sidecar

```bash
# Displays app istio-proxy
kubectl get pod <pod name> -o jsonpath='{.spec.containers[*].name}'
```

Connect to Istio load balancer with minikube tunnel

```bash
# Make sure loadbalancer has external ip
kubectl get svc -n istio-system istio-ingressgateway
```

After running the previous command, check the value of **EXTERNAL-IP** for the Istio Ingress Gateway.
Based on its value, follow **only one** of the options below.

**Option 1:** External-IP Is Available (Not Empty and Not `<pending>`)

Test istio using curl:

```bash
curl -H "Host: sms-checker-app" http://<external ip>:80
```

Open in browser at http://\<external ip\>:80

```bash
echo "<external ip> sms-checker-app" | sudo tee -a /etc/hosts
```

**Option 2:** External-IP Is Not Available (Empty or `<pending>`)

Port-forward the Istio Ingress-Gateway

```bash
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80
```

Open in browser

```bash
http://localhost:8080/sms/
```

### Test stickiness

Creates new session (new cookie) and displays it in the terminal:

```bash
curl -H "Host: sms-checker-app" -v http://<external ip>:80
```

It is possible to save this cookie and store in a txt file to use it:

```bash
curl -c cookies.txt -b cookies.txt -H "Host: sms-checker-app" -v http://<external ip>:80
```

txt is automatically generated and the cookie is placed there.

Can also send cookie without creating new files, but you will have to copy the cookie:

```bash
curl -H "Host: sms-checker-app" \
     -H 'Cookie: user-session="<cookie>"' \
     -v http://<external ip>
```

### Additional Istio Use Case: Shadow Launch

#### Prerequisite

Istio installed in the Kubernetes cluster.

#### Shadow Launch Setup

Verify Shadow Pod Running

```bash
kubectl get pods
```

Port-forward the Istio Ingress-Gateway

```bash
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80
```

#### Testing

Send test requests

```bash
for i in {1..10}; do
  curl -X POST http://127.0.0.1:8080/sms \
    -H "Content-Type: application/json" \
    -d '{"sms":"Hello world, test message"}'
done
```

#### Check Shadow Launch

The count of model-shadow logs will be equal to model-service-deployment-v1 + model-service-deployment-canary logs count if the traffic is split at model service otherwise model-shadow log count equals the model-service-deployment-v1 log count.

```bash
# Count model-service-deployment-v1 requests
kubectl logs deploy/model-service-deployment-v1 | grep -c predict

# Count model-service-deployment-canary requests
kubectl logs deploy/model-service-deployment-canary | grep -c predict

# Count model-shadow requests
kubectl logs deploy/model-shadow | grep -c predict
```

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

### Vagrant and Ansible Provisioning

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
ansible-playbook -u vagrant -i 192.168.56.100, ./ansible/finalization.yml
```

### 3. Deployment on the Provisioned Cluster

Now that the cluster is ready, you can deploy the SMS Checker application using either the Helm chart or the Kubernetes manifests.

```bash
# Go to the operation directory on the ctrl VM
vagrant ssh ctrl
cd /vagrant
```

Now you can follow the instructions from either:

- [Helm Chart Deployment](#helm-chart-deployment-recommended) (from Step 3)
- [Kubernetes Manifests Deployment](#kubernetes-manifests-deployment) (from Step 3)

_Note:_ Step 1 and 2 are not needed, since the cluster is already provisioned and we automatically copy the model files from `/model` on the host machine to the shared volumes on the VMs in the Ansible playbooks.

### 4. Access

### Cluster

You can access the Kubernetes cluster also from the host machine (instead of via ssh into the ctrl VM):

```bash
# Using the exported kubeconfig
export KUBECONFIG=./admin.conf
kubectl get nodes

# or directly:
kubectl --kubeconfig=./admin.conf get nodes
```

This can for example help you with the port-forwarding for accessing Prometheus and Grafana.

### Application

To access the application, you have to add an entry to your `/etc/hosts` file on your host machine:

```bash
echo "192.168.56.90 sms-checker-app" | sudo tee -a /etc/hosts
```

Now you can open:

- Frontend Application: http://sms-checker-app/sms
- Application Metrics: http://sms-checker-app/metrics

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

#### Grafana and Prometheus

See:

- [Prometheus Monitoring](#prometheus-monitoring)
- [Grafana Dashboards](#grafana-dashboards)

_Note:_ You have to run the port-forward commands in the `ctrl` VM or using the exported kubeconfig from the host machine.
