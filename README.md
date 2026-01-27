# DODA 2025 - Team 15

**Team Members:** Emīls Dzintars (5776597), Frederik van der Els (5480922), Riya Gupta (6452272), Arjun Rajesh Nair (6327184), Jimmy Oei (6540031), Sneha Prashanth

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

The SMS Spam Checker application is meant to be deployed on a provisioned Kubernetes cluster running on VirtualBox VMs. However, one could also deploy it on a local Kubernetes cluster using a tool like MiniKube (See [./docs/MiniKube.md](./docs/minikube.md)).

### Prerequisites

- Vagrant (with VirtualBox provider)
- VirtualBox
- Ansible
- Helm (optional, for deployment from host)
- Kubectl (optional, for cluster management from host)

### 1. Provisioning Kubernetes Cluster using Vagrant and Ansible

This will provision a Kubernetes cluster on VirtualBox VMs using Vagrant and Ansible:

```bash
vagrant up
```

Verify cluster status in ctrl (all nodes should be Ready):
```bash
# From within ctrl VM:
vagrant ssh ctrl
kubectl get nodes

# Or directly from host machine:
kubectl --kubeconfig=./admin.conf get nodes
```

### 2. Helm Chart Deployment

```bash
helm --kubeconfig=./admin.conf install sms-checker ./helm_chart --dependency-update
```

Verify all pods are running:
```bash
kubectl --kubeconfig=./admin.conf get pods
```

### Halting the Cluster
To halt the cluster without destroying the VMs, run:
```bash
vagrant halt
```

### Uninstall
To uninstall the application, run:

```bash
vagrant destroy -f
```

## Application

To access the application, add an entry to your `/etc/hosts` file:

```bash
kubectl --kubeconfig=./admin.conf get svc -n istio-system istio-ingressgateway
```

```bash
echo "<external ip> sms-checker-app" | sudo tee -a /etc/hosts
```

See the `management.md` file for instructions on how to change the hostname.
Now you can open:

- Frontend Application: http://sms-checker-app:8080/sms
- Application Metrics: http://sms-checker-app:8080/metrics

### Prometheus Monitoring

We use Prometheus from the kube-prometheus-stack Helm chart to automatically collect metrics from the app and model services via ServiceMonitor resources defined in this chart.

1. Port-forward the Prometheus service:

   Using kubectl:
   ```bash
   kubectl port-forward svc/sms-checker-monitoring-prometheus 9090:9090
   ```

   Or using minikube:
   ```bash
   minikube service sms-checker-monitoring-prometheus --url
   ```

2. Open Prometheus in your browser http://localhost:9090

3. Go to Status → Target health and confirm that the targets created by the ServiceMonitors are UP (job names containing sms-checker).
4. In the Query tab, you can run queries for the custom metrics exposed by the app:

   - `sms_requests_total` (Counter): Total number of SMS requests completed
   - `sms_requests_inflight` (Gauge): Current number of SMS requests being processed
   - `sms_request_latency_seconds` (Histogram): How long each SMS request took to complete

### Grafana Dashboards

1. Port-forward the Grafana service:

   Using kubectl:
   ```bash
   kubectl port-forward svc/sms-checker-grafana 3000:80
   ```

   Or using minikube:
   ```bash
   minikube service sms-checker-grafana --url
   ```

2. Open Grafana in your browser at http://localhost:3000

3. Default credentials (from kube-prometheus-stack):
   - Username: `admin`
   - Password: Get it with:

     ```bash
     kubectl get secret sms-checker-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
     ```

4. You can now check the pre-configured dashboards:

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
helm install sms-checker . \
  --set secret.slackWorkflowUrl=https://hooks.slack.com/triggers/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
kubectl label namespace default istio-injection=enabled
kubectl rollout restart deployment
```

Wait for all pods to run:

```bash
kubectl get pods
```

Make sure app pods have sidecar:

Displays app istio-proxy
```bash
kubectl get pod <pod name> -o jsonpath='{.spec.containers[*].name}'
```

Connect to Istio load balancer with minikube tunnel

Make sure loadbalancer has external ip
```bash
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

To see if 90/10 split is definitely working, you can run check-traffic.sh

```bash
chmod +x check-traffic.sh
EXTERNAL_IP=<external ip> ./check-traffic.sh
EXTERNAL_IP=<external ip> REQUESTS=1000 ./check-traffic.sh
```

Open in browser

```bash
http://localhost:8080/sms/
```
There is 10% chance to see canary release for app. if you keep spamming curl command you will see "Hello World! testing canary" eventually, which means you 
are connected to the canary release pod.

### Test stickiness

Creates new session (new cookie) and displays it in the terminal:

```bash
curl -H "Host: sms-checker-app" -v http://<external ip>:80
```

It is possible to save this cookie and store in a txt file to use it:

```bash
curl -c cookies.txt -b cookies.txt -H "Host: sms-checker-app" -v http://<external ip>:80
```

The txt file is automatically generated and the cookie is placed there.

Can also send cookie without creating new files, but you will have to copy the cookie:

```bash
curl -H "Host: sms-checker-app" \
     -H 'Cookie: user-session="<cookie>"' \
     -v http://<external ip>
```

Check the app service pod IPs:

```bash
kubectl get pods -o wide -l app=sms-checker
```

Test routing behaviour by inspecting Istio proxy logs to verify that requests are routed to the same pod:

```bash
kubectl logs -l app=sms-checker -c istio-proxy
```

Repeated requests with the same cookies should show the same upstream pod (look the pod ID from the previous command) in the access logs.

### Test alerts
Alerts are sent to slack server (https://join.slack.com/t/doda25/shared_invite/zt-3nrdzmef8-faBbEdGbKsJ5hF~rNP_6dQ)
prometheus rule is applied to individual node and not summed together 

Port forward for prometheus UI
```bash
kubectl port-forward svc/sms-checker-monitoring-prometheus 9090:9090 -n default
```
Get external ip of istio gateway
```bash
minikube tunnel
kubectl get svc -n istio-system istio-ingressgateway
```

Generate traffic 
```bash
seq 1 60 | xargs -n1 -P20 -I{} \
  curl -s -H "Host: sms-checker-app" -X POST -H "Content-Type: application/json" \
  -d '{"sms":"test message"}' http://<EXTERNAL IP>/sms >/dev/null
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

Count model-service-deployment-v1 requests:
```bash
kubectl logs deploy/model-service-deployment-v1 | grep -c predict
```

Count model-service-deployment-canary requests:
```bash
kubectl logs deploy/model-service-deployment-canary-v2 | grep -c predict
```

Count model-shadow requests:
```bash
kubectl logs deploy/model-shadow-v3 | grep -c predict
```

### Kubernetes Dashboard

You can access the Kubernetes Dashboard by navigating to the following URL in your web browser:

```
http://dashboard.192.168.56.90.nip.io
```

Use the `admin-user` ServiceAccount token to log in. You can create one token by executing the following command when ssh'd into the `ctrl`:

ssh into ctrl:
```bash
vagrant ssh ctrl
```

Create token for admin-user:
```bash
kubectl -n kubernetes-dashboard create token admin-user
```
