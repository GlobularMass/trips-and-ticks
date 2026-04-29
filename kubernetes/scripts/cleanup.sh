#!/bin/bash

# Kubernetes Cleanup Script for Trips and Ticks
# This script removes all deployed resources from the cluster

set -e

# Configuration
NAMESPACE="trips-ticks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Confirm deletion
confirm_deletion() {
    read -p "Are you sure you want to delete all resources in namespace '$NAMESPACE'? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Deletion cancelled"
        exit 0
    fi
}

# Delete all resources
delete_resources() {
    log_info "Deleting all resources in namespace: $NAMESPACE"
    
    # Delete deployments
    log_info "Deleting deployments..."
    kubectl delete deployment --all -n $NAMESPACE --ignore-not-found=true
    
    # Delete statefulsets
    log_info "Deleting statefulsets..."
    kubectl delete statefulset --all -n $NAMESPACE --ignore-not-found=true
    
    # Delete services
    log_info "Deleting services..."
    kubectl delete svc --all -n $NAMESPACE --ignore-not-found=true
    
    # Delete PVCs
    log_info "Deleting PersistentVolumeClaims..."
    kubectl delete pvc --all -n $NAMESPACE --ignore-not-found=true
    
    # Delete PVs (may need manual cleanup if using local storage)
    log_info "Deleting PersistentVolumes..."
    kubectl delete pv -l namespace=$NAMESPACE --ignore-not-found=true 2>/dev/null || true
    
    # Delete ConfigMaps and Secrets
    log_info "Deleting ConfigMaps and Secrets..."
    kubectl delete configmap,secret --all -n $NAMESPACE --ignore-not-found=true
    
    # Delete RBAC resources
    log_info "Deleting RBAC resources..."
    kubectl delete serviceaccount,clusterrole,clusterrolebinding -n $NAMESPACE --ignore-not-found=true 2>/dev/null || true
    
    # Delete network policies
    log_info "Deleting network policies..."
    kubectl delete networkpolicy --all -n $NAMESPACE --ignore-not-found=true
    
    log_info "Resources deleted"
}

# Delete namespace
delete_namespace() {
    log_info "Deleting namespace: $NAMESPACE"
    kubectl delete namespace $NAMESPACE --ignore-not-found=true
    log_info "Namespace deleted"
}

# Show remaining resources
show_remaining_resources() {
    log_info "Checking for remaining resources..."
    
    local count=$(kubectl get all -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
    if [ $count -eq 0 ]; then
        log_info "All resources have been deleted"
    else
        log_warn "Some resources may still exist:"
        kubectl get all -n $NAMESPACE 2>/dev/null || true
    fi
}

# Clean up port forwards (if running in background)
cleanup_port_forwards() {
    log_info "Cleaning up port forwards..."
    pkill -f "kubectl port-forward" || true
    log_info "Port forwards stopped"
}

# Main execution
main() {
    log_info "Starting cleanup of Trips and Ticks Kubernetes deployment..."
    
    confirm_deletion
    cleanup_port_forwards
    delete_resources
    delete_namespace
    show_remaining_resources
    
    log_info "Cleanup complete!"
}

# Run main function
main "$@"
