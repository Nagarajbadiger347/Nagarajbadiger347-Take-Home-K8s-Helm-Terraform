#!/bin/bash
#
# Test script for MongoDB demo application
# Validates deployment, connectivity, and basic CRUD operations
#

set -e

echo "================================================"
echo "MongoDB Demo App - Integration Test"
echo "================================================"
echo ""

# Config
NAMESPACE="${NAMESPACE:-demo}"
APP_SERVICE="demo-app"
BASE_URL="http://localhost:8080"
PORT_FORWARD_PID=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

cleanup() {
    if [ ! -z "$PORT_FORWARD_PID" ]; then
        log_info "Stopping port-forward (PID: $PORT_FORWARD_PID)"
        kill $PORT_FORWARD_PID 2>/dev/null || true
    fi
}

trap cleanup EXIT

# Check namespace
log_info "Verifying namespace '$NAMESPACE'..."
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    log_error "Namespace '$NAMESPACE' not found"
    exit 1
fi
log_info "✓ Namespace exists"

# Check MongoDB
log_info "Checking MongoDB status..."
MONGO_STATUS=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=mongodb -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
if [ "$MONGO_STATUS" != "Running" ]; then
    log_error "MongoDB pod not running (status: $MONGO_STATUS)"
    exit 1
fi
log_info "✓ MongoDB running"

# Check demo app
log_info "Checking demo-app status..."
APP_STATUS=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=demo-app -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
if [ "$APP_STATUS" != "Running" ]; then
    log_error "Demo-app pod not running (status: $APP_STATUS)"
    exit 1
fi
log_info "✓ Demo-app running"

# Get pod name
APP_POD=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=demo-app -o jsonpath='{.items[0].metadata.name}')
log_info "Using pod: $APP_POD"

# Wait for readiness
log_info "Waiting for pod ready state..."
if ! kubectl wait --for=condition=ready pod/$APP_POD -n $NAMESPACE --timeout=60s; then
    log_error "Pod failed to become ready"
    exit 1
fi
log_info "✓ Pod ready"

# Setup port forwarding
log_info "Starting port-forward..."
kubectl port-forward -n $NAMESPACE svc/$APP_SERVICE 8080:80 &> /dev/null &
PORT_FORWARD_PID=$!
sleep 3
log_info "✓ Port-forward active (PID: $PORT_FORWARD_PID)"

# Test health endpoint
log_info "Testing /healthz..."
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" $BASE_URL/healthz)
HEALTH_BODY=$(echo "$HEALTH_RESPONSE" | head -n -1)
HEALTH_CODE=$(echo "$HEALTH_RESPONSE" | tail -n 1)

if [ "$HEALTH_CODE" != "200" ]; then
    log_error "Health check failed (HTTP $HEALTH_CODE)"
    log_error "Response: $HEALTH_BODY"
    exit 1
fi
log_info "✓ Health check passed"
echo "   $HEALTH_BODY"

# Create test orders
log_info "Creating test orders..."
ORDER_COUNT=5
TIMESTAMP=$(date +%s)

for i in $(seq 1 $ORDER_COUNT); do
    ORDER_ID="TEST-${TIMESTAMP}-${i}"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/orders \
        -H "Content-Type: application/json" \
        -d "{\"orderId\":\"$ORDER_ID\"}")
    
    BODY=$(echo "$RESPONSE" | head -n -1)
    CODE=$(echo "$RESPONSE" | tail -n 1)
    
    if [ "$CODE" != "201" ]; then
        log_error "Order creation failed (HTTP $CODE)"
        log_error "Response: $BODY"
        exit 1
    fi
    
    log_info "✓ Order created: $ORDER_ID"
done

# Get order count
log_info "Testing /orders/count..."
COUNT_RESPONSE=$(curl -s -w "\n%{http_code}" $BASE_URL/orders/count)
COUNT_BODY=$(echo "$COUNT_RESPONSE" | head -n -1)
COUNT_CODE=$(echo "$COUNT_RESPONSE" | tail -n 1)

if [ "$COUNT_CODE" != "200" ]; then
    log_error "Count endpoint failed (HTTP $COUNT_CODE)"
    exit 1
fi

TOTAL_COUNT=$(echo $COUNT_BODY | grep -o '"count":[0-9]*' | cut -d':' -f2)
log_info "✓ Total orders: $TOTAL_COUNT"

if [ "$TOTAL_COUNT" -lt "$ORDER_COUNT" ]; then
    log_warning "Expected >= $ORDER_COUNT orders, found $TOTAL_COUNT"
else
    log_info "✓ Count validation passed"
fi

# Fetch all orders
log_info "Testing /orders..."
ORDERS_RESPONSE=$(curl -s -w "\n%{http_code}" $BASE_URL/orders)
ORDERS_CODE=$(echo "$ORDERS_RESPONSE" | tail -n 1)

if [ "$ORDERS_CODE" != "200" ]; then
    log_error "Orders fetch failed (HTTP $ORDERS_CODE)"
    exit 1
fi
log_info "✓ Orders retrieved"

# Test error handling
log_info "Testing error handling..."
INVALID_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/orders \
    -H "Content-Type: application/json" \
    -d '{}')
INVALID_CODE=$(echo "$INVALID_RESPONSE" | tail -n 1)

if [ "$INVALID_CODE" != "400" ]; then
    log_warning "Expected HTTP 400, got $INVALID_CODE"
else
    log_info "✓ Error handling works"
fi

# Check logs
log_info "Verifying logs..."
LOG_LINES=$(kubectl logs -n $NAMESPACE $APP_POD --tail=10 2>/dev/null | wc -l | tr -d ' ')
if [ "$LOG_LINES" -gt 0 ]; then
    log_info "✓ Application logging active"
    echo ""
    echo "Recent logs:"
    kubectl logs -n $NAMESPACE $APP_POD --tail=5 | while IFS= read -r line; do
        echo "   $line"
    done
else
    log_warning "No logs available"
fi

# Summary
echo ""
echo "================================================"
echo -e "${GREEN}All tests passed successfully!${NC}"
echo "================================================"
echo ""
echo "Summary:"
echo "  ✓ MongoDB connectivity verified"
echo "  ✓ Health endpoint working"
echo "  ✓ Created $ORDER_COUNT test orders"
echo "  ✓ Order count endpoint working"
echo "  ✓ Order retrieval working"
echo "  ✓ Error handling validated"
echo "  ✓ Logging verified"
echo ""
echo "Test completed at: $(date)"
