# Scripts Directory

This directory contains automation scripts for deploying and testing the MongoDB demo application.

## Scripts Overview

### `deploy.sh` - Deployment Automation
Automates the complete deployment process including:
- Prerequisites validation (kubectl, helm, docker)
- Namespace creation
- Helm repository setup
- MongoDB deployment with Bitnami chart
- Docker image build and push
- Demo application deployment
- Deployment verification
- Secure credential handling (no passwords in logs)

**Usage:**
```bash
# Deploy to dev environment (default)
./scripts/deploy.sh

# Deploy to production
ENVIRONMENT=prod ./scripts/deploy.sh

# Deploy with custom registry
DOCKER_REGISTRY=myregistry.io ENVIRONMENT=prod ./scripts/deploy.sh
```

**Environment Variables:**
- `NAMESPACE` - Kubernetes namespace (default: demo)
- `ENVIRONMENT` - Environment name: dev/ci/prod (default: dev)
- `DOCKER_REGISTRY` - Docker registry URL (default: local)
- `IMAGE_TAG` - Docker image tag (default: latest)

**Security Note:**
MongoDB credentials are stored securely in Kubernetes secrets and are NOT displayed in script output. To retrieve credentials if needed:
```bash
kubectl get secret mongodb -n demo -o jsonpath='{.data.mongodb-passwords}' | base64 -d
```

---

### `test-app.sh` - Integration Tests ⭐ REQUIRED
Validates the deployment with end-to-end tests as required by the assessment.

**Tests performed:**
- Health endpoint verification (`/healthz`)
- Order creation (`POST /orders`)
- Order count retrieval (`GET /orders/count`)
- Order listing (`GET /orders`)
- Error handling validation
- Application logging verification

**Usage:**
```bash
# Run tests against default namespace
./scripts/test-app.sh

# Run tests against custom namespace
NAMESPACE=demo ./scripts/test-app.sh
```

**Requirements:**
- kubectl configured and connected to cluster
- MongoDB and demo-app deployed
- curl installed

---

### `cleanup.sh` - Resource Cleanup
Removes all deployed resources including Helm releases, PVCs, and optionally the namespace.

**Usage:**
```bash
# Clean up default namespace
./scripts/cleanup.sh

# Clean up custom namespace
NAMESPACE=demo ./scripts/cleanup.sh
```

**What it removes:**
- demo-app Helm release
- mongodb Helm release
- All PersistentVolumeClaims
- Namespace (optional, prompts user)

---

## Quick Start

```bash
# 1. Deploy everything
make deploy

# 2. Run tests (required by assessment)
make test

# 3. Clean up
make clean
```

Or without Make:

```bash
# Deploy
./scripts/deploy.sh

# Test
./scripts/test-app.sh

# Cleanup
./scripts/cleanup.sh
```

---

## Script Requirements

All scripts require:
- `kubectl` - Kubernetes CLI
- `helm` - Helm package manager
- `bash` - Shell environment
- `curl` - HTTP client (for testing)
- `docker` - Container runtime (for deploy.sh)

Check prerequisites:
```bash
command -v kubectl && echo "kubectl: OK"
command -v helm && echo "helm: OK"
command -v docker && echo "docker: OK"
command -v curl && echo "curl: OK"
```
