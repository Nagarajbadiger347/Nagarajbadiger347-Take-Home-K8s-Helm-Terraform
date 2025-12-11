# Kubernetes + Helm + Terraform Take-Home Assignment

This project sets up a complete Kubernetes environment on AWS with MongoDB and a demo application, all managed through infrastructure-as-code.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Detailed Setup](#detailed-setup)
- [Testing](#testing)
- [Production Considerations](#production-considerations)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

What's included:
- **Infrastructure as Code**: Full EKS cluster setup with Terraform
- **Helm Charts**: MongoDB (using Bitnami) and a custom chart for the demo app
- **Best Practices**: Health checks, secrets management, resource limits, structured logs
- **Production Features**: Network policies, autoscaling, pod disruption budgets

### Tier A Requirements ✅

- ✅ Kubernetes cluster setup with Terraform (EKS on AWS)
- ✅ MongoDB Community deployment via Helm with:
  - Authentication enabled
  - Persistent storage (PVC with StorageClass)
  - Liveness/Readiness probes
  - Environment-specific values files
- ✅ Custom Helm chart for demo application
- ✅ Secure MongoDB connectivity (Kubernetes Secrets, DNS, probes)
- ✅ Repeatable integration tests

### Tier B Features ✅

- ✅ Basic network policies
- ✅ Structured JSON logging for observability
- ✅ HPA configuration for autoscaling
- ✅ Production-ready defaults and multiple environment configs

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                         AWS EKS                          │
│                                                          │
│  ┌─────────────┐         ┌──────────────┐              │
│  │  Demo App   │────────▶│   MongoDB    │              │
│  │  (3 pods)   │         │  (Bitnami)   │              │
│  │             │         │              │              │
│  │ - Health    │         │ - Auth: ✓    │              │
│  │ - /orders   │         │ - PVC: 10Gi  │              │
│  │ - Logging   │         │ - Probes: ✓  │              │
│  └─────────────┘         └──────────────┘              │
│       │                          │                      │
│       │                          │                      │
│  ┌────▼───────┐           ┌─────▼──────┐              │
│  │ ConfigMap  │           │   Secret   │              │
│  │ Service    │           │    PVC     │              │
│  │ Ingress    │           │            │              │
│  └────────────┘           └────────────┘              │
│                                                         │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
            ┌──────────────────────────┐
            │   Terraform-managed:     │
            │   - VPC & Subnets        │
            │   - IAM Roles            │
            │   - EKS Cluster          │
            │   - Node Groups          │
            │   - EBS CSI Driver       │
            └──────────────────────────┘
```

## 📦 Prerequisites

### Required Tools

- **Terraform** >= 1.0
- **kubectl** >= 1.28
- **Helm** >= 3.x
- **Docker** >= 20.x
- **AWS CLI** (configured with credentials)
- **bash** shell

### AWS Requirements

- AWS Account with appropriate permissions
- AWS credentials configured (`aws configure`)
- Sufficient quota for:
  - VPC (1)
  - EKS cluster (1)
  - EC2 instances (2-4)
  - EBS volumes (for PVCs)

## 🚀 Quick Start

### 1. Provision Infrastructure

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply (creates EKS cluster - takes ~15 minutes)
terraform apply -auto-approve

# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name demo-eks-cluster
```

### 2. Deploy Applications

```bash
# Return to project root
cd ..

# Scripts are already executable (chmod +x applied)

# Deploy MongoDB and demo app
./scripts/deploy.sh

# This script will:
# - Validate prerequisites
# - Create namespace
# - Deploy MongoDB via Helm
# - Build Docker image
# - Deploy demo app
# - Verify deployment
# - Display access instructions (credentials stored securely)
```

**Note:** MongoDB credentials are stored in Kubernetes secrets and not displayed in output. Retrieve them if needed:
```bash
kubectl get secret mongodb -n demo -o jsonpath='{.data.mongodb-passwords}' | base64 -d
```

### 3. Test the Deployment

```bash
# Run integration tests
./scripts/test-app.sh

# Or test manually
kubectl port-forward -n demo svc/demo-app 8080:80

# In another terminal:
curl http://localhost:8080/healthz
curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{"orderId":"ORDER-001"}'
curl http://localhost:8080/orders/count
```

## 📁 Project Structure

```
.
├── terraform/                 # Infrastructure as Code
│   ├── main.tf               # EKS cluster, VPC, networking
│   ├── variables.tf          # Input variables
│   ├── outputs.tf            # Output values
│   └── backend.tf.example    # Remote state configuration
│
├── helm/                      # Helm charts
│   └── demo-app/             # Custom application chart
│       ├── Chart.yaml        # Chart metadata
│       ├── values.yaml       # Default values
│       ├── values.dev.yaml   # Dev environment
│       ├── values.ci.yaml    # CI environment
│       ├── values.prod.yaml  # Production environment
│       └── templates/        # Kubernetes manifests
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── configmap.yaml
│           ├── ingress.yaml
│           ├── hpa.yaml
│           ├── networkpolicy.yaml
│           ├── pdb.yaml
│           └── _helpers.tpl
│
├── app/                       # Demo application
│   ├── server.js             # Node.js Express app
│   ├── package.json          # Dependencies
│   ├── Dockerfile            # Container image
│   └── README.md             # App documentation
│
├── mongodb/                   # MongoDB configuration
│   ├── values.dev.yaml       # Development values
│   ├── values.ci.yaml        # CI/Test values
│   ├── values.prod.yaml      # Production values
│   └── README.md             # MongoDB deployment guide
│
├── scripts/                   # Automation scripts
│   ├── deploy.sh             # Deployment automation
│   ├── test-app.sh           # Integration tests ⭐ REQUIRED
│   ├── cleanup.sh            # Resource cleanup
│   └── README.md             # Scripts documentation
│
└── README.md                  # This file
```

## 🔧 Detailed Setup

### Terraform Configuration

The Terraform configuration creates:

1. **VPC & Networking**
   - VPC with CIDR 10.0.0.0/16
   - 2 public subnets (for load balancers)
   - 2 private subnets (for worker nodes)
   - NAT gateways for private subnet internet access
   - Internet gateway and route tables

2. **IAM Roles & Policies**
   - EKS cluster role
   - Node group role
   - EBS CSI driver role
   - Necessary policy attachments

3. **EKS Cluster**
   - Kubernetes version 1.28
   - Control plane logging enabled
   - OIDC provider for IRSA
   - EBS CSI driver addon

4. **Node Group**
   - 2 t3.medium instances (configurable)
   - Auto-scaling 1-4 nodes
   - Private subnet placement

### MongoDB Deployment

Using **Bitnami MongoDB Helm Chart** because:
- Production-tested and widely adopted
- Regular security updates
- Comprehensive configuration options
- Built-in metrics exporter
- Excellent documentation

**Key configurations:**
- Authentication with auto-generated passwords
- Persistent storage with explicit StorageClass (gp2)
- Liveness/Readiness/Startup probes tuned for startup
- ClusterIP service for internal access
- Security contexts (runAsNonRoot)

### Demo Application

A minimal Node.js Express application that validates MongoDB connectivity.

**API Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | `/healthz` | Health check with MongoDB ping |
| POST | `/orders` | Create order with `{orderId: string}` |
| GET | `/orders/count` | Get total order count |
| GET | `/orders` | List all orders (max 100) |

**Features:**
- Structured JSON logging (single-line)
- Graceful shutdown handling
- MongoDB connection pooling
- Environment-based configuration
- Non-root container execution
- Health check built into Docker image

### Helm Chart

The custom Helm chart includes:

**Templates:**
- Deployment with probes and resource limits
- Service (ClusterIP)
- ConfigMap for non-sensitive config
- ServiceAccount
- Ingress (optional)
- HorizontalPodAutoscaler (optional)
- NetworkPolicy (optional)
- PodDisruptionBudget (optional)

**Helper Templates:**
- Name generation functions
- Label helpers
- MongoDB URI construction

**Environment Configurations:**
- `values.yaml` - Base values
- `values.dev.yaml` - Development (1 replica, reduced resources)
- `values.ci.yaml` - CI/Testing (fast probes)
- `values.prod.yaml` - Production (HA, autoscaling, network policies)

## 🧪 Testing

### Automated Integration Tests ⭐ ASSESSMENT REQUIREMENT

The `test-app.sh` script fulfills the assessment requirement: *"Provide a test that can be repeated to demonstrate that the application reads and inserts Mongo data."*

```bash
./scripts/test-app.sh
```

**Test coverage:**
- ✅ Namespace existence
- ✅ MongoDB pod health
- ✅ Demo app pod readiness
- ✅ Health endpoint (200 OK)
- ✅ Order creation (POST /orders) - **MongoDB WRITE**
- ✅ Order counting (GET /orders/count) - **MongoDB READ**
- ✅ Order retrieval (GET /orders) - **MongoDB READ**
- ✅ Error handling (400 for invalid requests)
- ✅ Structured logging verification

**Output:** The script provides detailed pass/fail status for each test and shows a summary at the end.

### Manual Testing

```bash
# Port-forward to the application
kubectl port-forward -n demo svc/demo-app 8080:80

# Test health
curl http://localhost:8080/healthz

# Create orders
curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{"orderId":"ORDER-001"}'

curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{"orderId":"ORDER-002"}'

# Check count
curl http://localhost:8080/orders/count

# Get all orders
curl http://localhost:8080/orders
```

### Verify Logs

```bash
# Check structured logging
kubectl logs -n demo -l app.kubernetes.io/name=demo-app -f

# Example log output:
# {"timestamp":"2025-12-11T10:30:00.000Z","method":"POST","path":"/orders","status":201,"latency_ms":45,"user_agent":"curl/7.79.1"}
```

## 🏭 Production Considerations

### What's Included

1. **Security**
   - Non-root containers (runAsUser: 1001)
   - Security contexts with dropped capabilities
   - Secure secret management (no passwords in logs)
   - Network policies (configurable)
   - Read-only root filesystem option
   - No privilege escalation allowed

2. **Reliability**
   - Multiple replicas
   - Liveness/Readiness/Startup probes
   - Resource requests and limits
   - Pod Disruption Budgets
   - Anti-affinity rules

3. **Scalability**
   - Horizontal Pod Autoscaler
   - Node group auto-scaling
   - Connection pooling

4. **Observability**
   - Structured JSON logging
   - Prometheus annotations
   - Health check endpoints
   - Kubernetes events

### Additional Production Steps

For a full production deployment, consider:

1. **TLS/HTTPS**
   - Enable Ingress with cert-manager
   - MongoDB TLS connections
   - Update values.prod.yaml with your domain

2. **Monitoring**
   - Deploy Prometheus + Grafana
   - Enable MongoDB metrics exporter
   - Set up alerting rules

3. **Backup & Recovery**
   - Regular MongoDB backups
   - PVC snapshots
   - Disaster recovery plan

4. **CI/CD Integration**
   - Automated testing pipeline
   - Image scanning
   - GitOps with ArgoCD/Flux

5. **Remote State**
   - Enable Terraform S3 backend
   - Configure state locking

## 🔍 Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl get pods -n demo

# Describe pod for events
kubectl describe pod <pod-name> -n demo

# Check logs
kubectl logs <pod-name> -n demo
```

### MongoDB connection issues

```bash
# Verify MongoDB is running
kubectl get pods -n demo -l app.kubernetes.io/name=mongodb

# Get MongoDB password
export MONGODB_PASSWORD=$(kubectl get secret mongodb -n demo -o jsonpath='{.data.mongodb-passwords}' | base64 -d)

# Test MongoDB connection
kubectl run mongodb-client --rm -it --restart='Never' \
  --namespace demo \
  --image docker.io/bitnami/mongodb:7.0 \
  --command -- bash

# Inside the pod:
mongosh mongodb://mongodb:27017 -u appuser -p $MONGODB_PASSWORD
```

### EKS cluster issues

```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# View cluster events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Check EBS CSI driver
kubectl get pods -n kube-system -l app=ebs-csi-controller
```

### Clean up everything

```bash
# Remove all Helm releases and resources
./scripts/cleanup.sh

# Destroy Terraform infrastructure
cd terraform
terraform destroy -auto-approve
```

## 📚 Additional Resources

- [Terraform AWS EKS Documentation](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [Bitnami MongoDB Helm Chart](https://github.com/bitnami/charts/tree/main/bitnami/mongodb)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)

## 📝 Notes

### Chart Selection Justification

**MongoDB - Bitnami Chart:**
- Industry standard, trusted by thousands of organizations
- Regular security patches and updates
- Extensive configuration options for production use
- Built-in observability with metrics exporter
- Well-documented and actively maintained
- Supports replication, authentication, and TLS

### Design Decisions

1. **EKS over other options**: Production-ready, managed control plane, good AWS integration
2. **Bitnami MongoDB**: Most mature and feature-complete MongoDB Helm chart
3. **Node.js for demo app**: Minimal dependencies, fast startup, good MongoDB driver
4. **Structured logging**: Single-line JSON for easy parsing by log aggregators
5. **Multiple values files**: Environment-specific configs without code duplication


**Author**: Nagaraj Badiger 
**Date**: December 2025  
**Version**: 1.0.0
