# Team 15

Emīls Dzintars, Frederik van der Els, Riya Gupta, Arjun Rajesh Nair, Jimmy Oei, Sneha Prashanth

## Operation Repository

https://github.com/doda25-team15/operation/tree/a2


## Model Service (Backend) Repository

https://github.com/doda25-team15/model-service/tree/a2

**Workflows**:

- Release workflow: workflow consisting of two jobs: training the model and releasing the Docker image for the model-service.

**Configuration (Dockerfile env variables):**

- `PORT`: Server port (default: 8081)

**Notes**:

- The service expects the model to be mounted at `/output`, but if not found there, it will download it from GitHub Releases.

## App (Frontend) Repository

https://github.com/doda25-team15/app/tree/a2

**Workflows**:

- Release workflow: releases Docker image for the app service on

**Configuration (Dockerfile env variables):**

- `PORT`: Server port (default: 8080)
- `MODEL_SERVICE_URL`: URL to the model-service endpoint (default: http://localhost:8081)

**Notes**:

- We used Gradle to build the app instead of Maven.

## Lib Repository

https://github.com/doda25-team15/lib-version/tree/a2

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
