# Deployment Architecture

## Table of Contents

- [Deployment Architecture](#deployment-architecture)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Provisioning Infrastructure](#provisioning-infrastructure)
  - [Deployment Architecture](#deployment-architecture-1)
    - [App (Frontend)](#app-frontend)
    - [Model Service (Backend)](#model-service-backend)
    - [Istio](#istio)
    - [MetalLB](#metallb)
    - [Prometheus](#prometheus)
    - [Grafana](#grafana)
    - [Kubernetes Dashboard](#kubernetes-dashboard)

---

## Overview

This document describes the deployment architecture for the SMS Spam Checker application, which uses a provisioned multi-node Kubernetes cluster running on VirtualBox VMs. The deployment uses two strategies:

1. Canary Release Strategy
2. Shadow Deployment Strategy

## Provisioning Infrastructure

The VirtualBox VMs on which the Kubernetes cluster is deployed, are provisioned using Vagrant and Ansible. This provisioning architecture is illustrated in the diagram below:

![Provisioning Architecture](./attachments/provisioning-architecture.drawio.png)

We have one control node and multiple worker nodes. The control node is responsible for managing the Kubernetes cluster, while the worker nodes run the workloads. Kubeadm is used to set up the Kubernetes cluster and join the nodes together.

## Deployment Architecture

The SMS Spam Checker application is deployed on the Kubernetes cluster with Istio service mesh. The diagram below illustrates the deployment architecture:

![Deployment Architecture](./attachments/deployment-architecture.drawio.png)

The SMS Spam Checker's exposed endpoint is `http://sms-checker-app/sms`, which can be access through the browser or using API clients. The API request format is as follows:

- URL: `http://sms-checker-app/sms`
- Method: POST
- Body: `{"message": "Your SMS text here"}`
- Response: `{"result": "spam" | "ham", "confidence": 0.0-1.0}`

As shown in the diagram, the deployment routing strategies are:

- **90/10 Split**: The App service has a stable deployment (v1) that handles 90% of the traffic, and a canary deployment (v2) that handles 10% of the traffic. This allows for a canary release strategy.
- **Shadow Deployment**: The Model Service has a shadow deployment (v3) that receives a copy of the traffic from the stable deployment (v1). This allows for testing new versions of the Model Service without affecting the live traffic.

Below are the details of each component in the deployment architecture.

### App (Frontend)

The App exposes the user interface for the SMS Spam Checker Application at `/sms`, where it forwards requests to the model service for predictions. And it exposes Prometheus metrics at the `/metrics` endpoint. It has two deployments: a stable deployment (v1) and a canary deployment (v2). The stable deployment handles 90% of the traffic, while the canary deployment receives 10% of the traffic for testing purposes.

**Technology**: Java Spring Boot 3.5.7 (Java 25)
**Repository**: https://github.com/doda25-team15/app

**Deployments:**

- **app-deployment-v1** (Stable)

  - Replicas: 2
  - Image: `ghcr.io/doda25-team15/app:v1.0.8`
  - Label: `version=v1`
  - Port: 8080

- **app-deployment-canary-v2** (Canary)
  - Replicas: 2
  - Image: `ghcr.io/doda25-team15/app:v1.0.8`
  - Label: `version=v2`
  - Port: 8080

### Model Service (Backend)

The Model Service exposes a REST API for predicting whether an SMS message is spam or not. It has three deployments: a stable deployment (v1), a canary deployment (v2), and a shadow deployment (v3). The stable deployment handles traffic from the stable deployment of the App service, the canary deployment receives the traffic from the canary deployment of the App service, and the shadow deployment receives a copy of the stable traffic for testing purposes.

**Technology:** Python 3.12.9 + Flask + scikit-learn
**Repository:** https://github.com/doda25-team15/model-service

**Deployments:**

- **model-deployment-v1** (Stable)

  - Replicas: 2
  - Image: `ghcr.io/doda25-team15/model-service:v1.0.2`
  - Label: `version=v1`
  - Port: 8081
  - Volume: `/mnt/shared/output` → `/app/output`

- **model-deployment-v2** (Canary)

  - Replicas: 2
  - Image: `ghcr.io/doda25-team15/model-service:v1.0.2`
  - Label: `version=v2`
  - Port: 8081
  - Volume: `/mnt/shared/output-canary` → `/app/output`

- **model-shadow-v3** (Shadow)
  - Replicas: 1
  - Image: `ghcr.io/doda25-team15/model-service:v1.0.2`
  - Label: `version=v3`
  - Port: 8081
  - Volume: `/mnt/shared/output-shadow` → `/app/output`

### Istio

Istio is used as a service mesh to manage the traffic between the App and Model Service deployments. It has an Ingress Gateway that exposes the App Service for external traffic into the service mesh. There are two Virtual Services defined, one for traffic routing between the App and Model Service deployments, and another for the traffic routing to the App Service via the Ingress Gateway. The first one is responsible for mirroring the traffic from the stable Model Service deployment to the shadow deployment for testing purposes. The second Virtual Service is responsible for routing 90% of the traffic to the stable App deployment and 10% to the canary deployment, allowing for a canary release strategy.

**Ingress Gateway:**

- Port: 80

**Virtual Services for App Service:**

- If header contains `testing = true`, routes 100% to canary App deployment.
- Otherwise, routes 90% to stable App deployment and 10% to canary App deployment.

**Virtual Services for Model Service:**

- Routes 100% of traffic from canary App deployment to canary Model Service deployment.
- Routes 100% of traffic from stable App deployment to stable Model Service deployment.
- Mirrors 100% of traffic from stable Model Service deployment to shadow Model Service deployment.

**Destination Rules:**

- Ensures users consistently route to the same version during their session.

### MetalLB

MetalLB is used as a load balancer for the Kubernetes cluster, providing external access to the Istio Ingress Gateway. It assigns a static IP address to the Ingress Gateway service, allowing users to access the SMS Spam Checker application via a consistent endpoint.

### Prometheus

Prometheus is used for monitoring and alerting. It scrapes metrics from the App service at the `/metrics` endpoint. Prometheus runs on port 9090 and can be accessed by port forwarding the prometheus service from the host machine.

**Collected Metrics:**

- `sms_requests_total` (Counter): Total completed requests
- `sms_requests_inflight` (Gauge): Current in-flight requests
- `sms_request_latency_seconds` (Histogram): Request latency distribution

**Additional Monitoring:**

- Pod metrics (CPU, memory)
- Kubernetes cluster metrics
- Istio telemetry (traffic, latency, errors)

### Grafana

Grafana is used for visualizing the metrics collected by Prometheus. It provides dashboards for monitoring the performance and health of the SMS Spam Checker application and the Kubernetes cluster. Grafana runs on port 3000 and can be accessed by port forwarding the grafana service from the host machine.

**Custom Dashboards:**

- SMS Spam Checker Application Dashboard

### Kubernetes Dashboard

Kubernetes Dashboard is a web-based UI for managing and monitoring the Kubernetes cluster. It provides an overview of the cluster's resources, workloads, and namespaces. The dashboard can be accessed at `http://dashboard.192.168.56.90.nip.io`.
