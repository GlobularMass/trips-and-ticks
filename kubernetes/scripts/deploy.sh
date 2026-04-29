#!/bin/bash

# Kubernetes Deployment Script for Trips and Ticks
# This script deploys the application stack to Kubernetes

set -e

# Configuration
NAMESPACE="trips-ticks"
DEPLOYMENT_NAME="trips-ticks"
MANIFEST_DIR="./kubernetes/manifests"
KUSTOMIZE_DIR="./kubernetes"

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

# Create namespace
create_namespace() {
    log_info "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespace for network policies
    kubectl label namespace $NAMESPACE name=$NAMESPACE --overwrite
    log_info "Namespace created successfully"
}

# Create storage class
create_storage_class() {
    log_info "Creating local storage class..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
    
    log_info "Storage class created"
}

# Deploy using Kustomize
deploy_kustomize() {
    log_info "Deploying using kubectl kustomize..."
    
    kubectl apply -k $KUSTOMIZE_DIR
    
    log_info "Kustomize deployment complete"
}

# Deploy using individual manifests
deploy_manifests() {
    log_info "Deploying individual manifests..."
    
    # Deploy RBAC first
    log_info "Deploying RBAC..."
    kubectl apply -f $MANIFEST_DIR/rbac/rbac.yaml
    
    # Deploy config (ConfigMaps and Secrets)
    log_info "Deploying ConfigMaps and Secrets..."
    kubectl apply -f $MANIFEST_DIR/config/configmaps.yaml
    kubectl apply -f $MANIFEST_DIR/config/secrets.yaml
    
    # Deploy storage
    log_info "Deploying storage volumes..."
    kubectl apply -f $MANIFEST_DIR/storage/volumes.yaml
    
    # Deploy services
    log_info "Deploying MongoDB..."
    kubectl apply -f $MANIFEST_DIR/services/mongodb.yaml
    
    log_info "Deploying PostgreSQL..."
    kubectl apply -f $MANIFEST_DIR/services/postgres.yaml
    
    log_info "Deploying Airflow..."
    kubectl apply -f $MANIFEST_DIR/services/airflow.yaml
    
    log_info "Manifest deployment complete"
}

# Wait for deployments to be ready
wait_for_deployments() {
    log_info "Waiting for deployments to be ready..."
    
    kubectl wait --for=condition=available --timeout=300s \
        deployment/airflow-webserver \
        deployment/airflow-scheduler \
        -n $NAMESPACE || log_warn "Some deployments may still be rolling out"
    
    kubectl wait --for=condition=ready --timeout=300s \
        statefulset/mongodb \
        statefulset/postgres \
        -n $NAMESPACE || log_warn "Some StatefulSets may still be rolling out"
    
    log_info "Deployments are ready"
}

# Get service URLs
get_service_urls() {
    log_info "Service URLs:"
    
    # Get Airflow WebUI URL
    log_info "Airflow WebUI:"
    kubectl get svc airflow-webserver -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "LoadBalancer IP pending (minikube: kubectl port-forward)"
    
    # Get MongoDB connection string
    log_info "MongoDB connection:"
    echo "mongodb://admin:change-me-in-production@mongodb:27017/admin?authSource=admin"
    
    # Get PostgreSQL connection string
    log_info "PostgreSQL connection:"
    echo "postgresql://postgres:change-me-in-production@postgres:5432/trips_ticks_analytics"
}

# Port forward (for local testing)
setup_port_forwarding() {
    log_info "Setting up port forwarding for local testing..."
    
    log_info "Airflow WebUI: http://localhost:8080"
    kubectl port-forward -n $NAMESPACE svc/airflow-webserver 8080:8080 &
    
    log_info "MongoDB: localhost:27017"
    kubectl port-forward -n $NAMESPACE svc/mongodb 27017:27017 &
    
    log_info "PostgreSQL: localhost:5432"
    kubectl port-forward -n $NAMESPACE svc/postgres-service 5432:5432 &
    
    log_info "Port forwarding setup complete"
}

# Main execution
main() {
    log_info "Starting deployment of Trips and Ticks..."
    
    check_prerequisites
    create_namespace
    create_storage_class
    
    # Choose deployment method
    if [ "$1" == "manifests" ]; then
        deploy_manifests
    else
        deploy_kustomize
    fi
    
    wait_for_deployments
    get_service_urls
    
    if [ "$1" == "--port-forward" ] || [ "$1" == "--pf" ]; then
        setup_port_forwarding
    fi
    
    log_info "Deployment complete!"
}

# Run main function
main "$@"
