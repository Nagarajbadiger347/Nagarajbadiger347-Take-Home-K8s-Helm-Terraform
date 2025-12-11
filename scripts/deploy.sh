#!/bin/bash
#
# Deployment script for MongoDB and demo application
# Usage: ENVIRONMENT=dev ./deploy.sh
#

set -e

# Config
NAMESPACE="${NAMESPACE:-demo}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Check prerequisites
log_step "Step 1: Checking Prerequisites"

log "Verifying kubectl..."
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl not installed"
    exit 1
fi
KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null || kubectl version --client 2>&1 | head -1)
log "✓ kubectl: $KUBECTL_VERSION"

log "Verifying helm..."
if ! command -v helm &> /dev/null; then
    echo "Error: helm not installed"
    exit 1
fi
log "✓ helm: $(helm version --short)"

log "Testing cluster connection..."
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot reach Kubernetes cluster"
    exit 1
fi
log "✓ Cluster connected"

# Create namespace
log_step "Step 2: Namespace Setup"
if kubectl get namespace $NAMESPACE &> /dev/null; then
    log "Namespace '$NAMESPACE' exists"
else
    kubectl create namespace $NAMESPACE
    log "✓ Namespace created: $NAMESPACE"
fi

# Setup Helm repos
log_step "Step 3: Helm Repository Setup"
log "Adding Bitnami repo..."
helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
helm repo update
log "✓ Repos updated"

# Deploy MongoDB
log_step "Step 4: MongoDB Deployment"
MONGODB_VALUES="mongodb/values.${ENVIRONMENT}.yaml"

if [ ! -f "$MONGODB_VALUES" ]; then
    echo "Error: Values file not found: $MONGODB_VALUES"
    exit 1
fi

log "Installing MongoDB ($ENVIRONMENT)..."
helm upgrade --install mongodb bitnami/mongodb \
    --namespace $NAMESPACE \
    --values $MONGODB_VALUES \
    --wait \
    --timeout 5m

log "✓ MongoDB deployed"

# Retrieve credentials
log "Fetching MongoDB credentials..."
MONGODB_ROOT_PASSWORD=$(kubectl get secret --namespace $NAMESPACE mongodb -o jsonpath="{.data.mongodb-root-password}" 2>/dev/null | base64 -d || echo "")
MONGODB_PASSWORD=$(kubectl get secret --namespace $NAMESPACE mongodb -o jsonpath="{.data.mongodb-passwords}" 2>/dev/null | base64 -d || echo "")

if [ -n "$MONGODB_PASSWORD" ]; then
    log "✓ Credentials retrieved and stored in K8s secret"
fi

# Build Docker image
log_step "Step 5: Building Application Image"

cd app
if [ -n "$DOCKER_REGISTRY" ]; then
    IMAGE_NAME="$DOCKER_REGISTRY/demo-app:$IMAGE_TAG"
else
    IMAGE_NAME="demo-app:$IMAGE_TAG"
fi

log "Building image: $IMAGE_NAME"
docker build -t $IMAGE_NAME .
log "✓ Image built"

if [ -n "$DOCKER_REGISTRY" ]; then
    log "Pushing to registry..."
    docker push $IMAGE_NAME
    log "✓ Image pushed"
fi
cd ..

# Deploy app
log_step "Step 6: Application Deployment"
APP_VALUES="helm/demo-app/values.${ENVIRONMENT}.yaml"

if [ ! -f "$APP_VALUES" ]; then
    echo "Error: Values file not found: $APP_VALUES"
    exit 1
fi

IMAGE_REPO=$(echo $IMAGE_NAME | cut -d':' -f1)
log "Installing demo-app ($ENVIRONMENT)..."
helm upgrade --install demo-app helm/demo-app \
    --namespace $NAMESPACE \
    --values $APP_VALUES \
    --set image.repository=$IMAGE_REPO \
    --set image.tag=$IMAGE_TAG \
    --wait \
    --timeout 5m

log "✓ Application deployed"

# Verify
log_step "Step 7: Verification"
log "MongoDB pods:"
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=mongodb

log "Demo-app pods:"
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=demo-app

log "Services:"
kubectl get svc -n $NAMESPACE

# Display info
log_step "Deployment Complete!"
echo ""
echo "Access the application:"
echo ""
echo "  # Port forward"
echo "  kubectl port-forward -n $NAMESPACE svc/demo-app 8080:80"
echo ""
echo "  # Health check"
echo "  curl http://localhost:8080/healthz"
echo ""
echo "  # Create order"
echo "  curl -X POST http://localhost:8080/orders \\"
echo "       -H 'Content-Type: application/json' \\"
echo "       -d '{\"orderId\":\"ORDER-001\"}'"
echo ""
echo "  # Get count"
echo "  curl http://localhost:8080/orders/count"
echo ""
echo "Run tests:"
echo "  ./scripts/test-app.sh"
echo ""
echo "MongoDB info:"
echo "  Host: mongodb.$NAMESPACE.svc.cluster.local"
echo "  Port: 27017"
echo "  Database: app"
echo "  Secret: mongodb (in namespace $NAMESPACE)"
echo ""
echo "To retrieve password:"
echo "  kubectl get secret mongodb -n $NAMESPACE -o jsonpath='{.data.mongodb-passwords}' | base64 -d"
echo ""
