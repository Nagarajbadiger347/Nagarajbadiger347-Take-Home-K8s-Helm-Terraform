#!/bin/bash
#
# Cleanup script - removes deployed resources
# Usage: ./cleanup.sh
#

set -e

NAMESPACE="${NAMESPACE:-demo}"

echo "Cleanup target: $NAMESPACE"
echo ""
echo "WARNING: This deletes all resources in the namespace!"
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

echo ""
echo "Removing Helm releases..."

# Remove demo-app
if helm list -n $NAMESPACE 2>/dev/null | grep -q "demo-app"; then
    echo "Removing demo-app..."
    helm uninstall demo-app -n $NAMESPACE
    echo "✓ demo-app removed"
fi

# Remove MongoDB
if helm list -n $NAMESPACE 2>/dev/null | grep -q "mongodb"; then
    echo "Removing mongodb..."
    helm uninstall mongodb -n $NAMESPACE
    echo "✓ mongodb removed"
fi

echo ""
echo "Waiting for termination..."
sleep 5

# Remove PVCs
echo ""
echo "Removing PersistentVolumeClaims..."
kubectl delete pvc --all -n $NAMESPACE 2>/dev/null || echo "No PVCs found"

# Optional namespace deletion
echo ""
read -p "Delete namespace '$NAMESPACE'? (yes/no): " DELETE_NS

if [ "$DELETE_NS" = "yes" ]; then
    kubectl delete namespace $NAMESPACE
    echo "✓ Namespace removed"
else
    echo "Namespace kept"
fi

echo ""
echo "Cleanup done!"
