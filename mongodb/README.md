# MongoDB Deployment

## Prerequisites
- EKS cluster running
- kubectl configured
- Helm 3.x installed

## Chart Selection

Using **Bitnami MongoDB chart** - it's production-ready, well-maintained, and includes metrics support.

Repository: https://github.com/bitnami/charts/tree/main/bitnami/mongodb

## Setup

Add the Bitnami repo:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

## Deployment

### Development

```bash
kubectl create namespace demo

helm install mongodb bitnami/mongodb \
  --namespace demo \
  --values values.dev.yaml \
  --wait

# Get auto-generated passwords
export MONGODB_PASSWORD=$(kubectl get secret mongodb -n demo -o jsonpath="{.data.mongodb-passwords}" | base64 -d)
echo "App Password: $MONGODB_PASSWORD"
```

### CI

```bash
helm install mongodb bitnami/mongodb \
  --namespace demo \
  --values values.ci.yaml \
  --wait

# Passwords: testpassword123 / apppassword123
```

### Production

```bash
# Generate secure passwords
export MONGODB_ROOT_PASSWORD=$(openssl rand -base64 32)
export MONGODB_APP_PASSWORD=$(openssl rand -base64 32)
export MONGODB_REPLICA_SET_KEY=$(openssl rand -base64 756)

# Deploy
helm install mongodb bitnami/mongodb \
  --namespace demo \
  --values values.prod.yaml \
  --set auth.rootPassword="$MONGODB_ROOT_PASSWORD" \
  --set auth.password="$MONGODB_APP_PASSWORD" \
  --set auth.replicaSetKey="$MONGODB_REPLICA_SET_KEY" \
  --wait

# Save these somewhere secure!
echo "Root: $MONGODB_ROOT_PASSWORD"
echo "App: $MONGODB_APP_PASSWORD"
```

## Verify

```bash
kubectl get pods -n demo -l app.kubernetes.io/name=mongodb
kubectl get pvc -n demo

# Test connection
export MONGODB_PASSWORD=$(kubectl get secret mongodb -n demo -o jsonpath="{.data.mongodb-passwords}" | base64 -d)
kubectl run mongodb-client --rm -i --tty --restart='Never' -n demo \
  --image docker.io/bitnami/mongodb:7.0 \
  --command -- mongosh app --host mongodb --authenticationDatabase app -u appuser -p $MONGODB_PASSWORD
```

## Upgrade / Uninstall

```bash
# Upgrade
helm upgrade mongodb bitnami/mongodb -n demo -f values.dev.yaml --wait

# Uninstall (PVCs remain)
helm uninstall mongodb -n demo
```

## Troubleshooting

```bash
# Check pods
kubectl get pods -n demo -l app.kubernetes.io/name=mongodb
kubectl logs -n demo -l app.kubernetes.io/name=mongodb

# Verify secret
kubectl get secret mongodb -n demo
kubectl get secret mongodb -n demo -o jsonpath='{.data.mongodb-passwords}' | base64 -d

# Check resources
kubectl top pod -n demo -l app.kubernetes.io/name=mongodb
```

## Configuration Overview

| Environment | Architecture | Storage | Resources | Passwords |
|------------|--------------|---------|-----------|-----------|
| Dev | Standalone | 10Gi GP2 | 250m/512Mi | Auto-generated |
| CI | Standalone | 5Gi GP2 | 100m/256Mi | Fixed (test only) |
| Prod | Replica Set (3+1) | 50Gi GP3 | 1000m/2Gi | Must be provided |

### Production Features
- Network policy (restricts to demo-app)
- Pod disruption budget (min 2 replicas)
- Anti-affinity (spread across nodes)
- Metrics with ServiceMonitor
