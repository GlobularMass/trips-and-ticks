# Kubernetes Deployment Script for Trips and Ticks (PowerShell)
# This script deploys the application stack to Kubernetes on Windows

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('manifests', 'kustomize', '--port-forward', '--pf')]
    [string]$DeploymentMethod = 'kustomize',
    
    [Parameter(Mandatory = $false)]
    [switch]$PortForward
)

$ErrorActionPreference = "Stop"

# Configuration
$NAMESPACE = "trips-ticks"
$DEPLOYMENT_NAME = "trips-ticks"
$MANIFEST_DIR = "./kubernetes/manifests"
$KUSTOMIZE_DIR = "./kubernetes"

# Colors for output
$ColorInfo = "Green"
$ColorWarn = "Yellow"
$ColorError = "Red"

# Functions
function Write-InfoLog {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $ColorInfo
}

function Write-WarnLog {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor $ColorWarn
}

function Write-ErrorLog {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $ColorError
}

# Check prerequisites
function Invoke-PrerequisiteCheck {
    Write-InfoLog "Checking prerequisites..."
    
    # Check kubectl
    try {
        $null = kubectl version --client 2>$null
    }
    catch {
        Write-ErrorLog "kubectl is not installed or not in PATH"
        Write-Host "Install kubectl from: https://kubernetes.io/docs/tasks/tools/#kubectl"
        exit 1
    }
    
    Write-InfoLog "Prerequisites check passed"
}

# Create namespace
function New-Namespace {
    Write-InfoLog "Creating namespace: $NAMESPACE"
    
    $namespaceExists = kubectl get namespace $NAMESPACE 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-InfoLog "Namespace already exists"
    }
    else {
        kubectl create namespace $NAMESPACE
        Write-InfoLog "Namespace created successfully"
    }
    
    # Label namespace for network policies
    kubectl label namespace $NAMESPACE name=$NAMESPACE --overwrite
}

# Create storage class
function New-StorageClass {
    Write-InfoLog "Creating local storage class..."
    
    $storageClassYaml = @"
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
"@

    $storageClassYaml | kubectl apply -f -
    Write-InfoLog "Storage class created"
}

# Deploy using Kustomize
function Deploy-Kustomize {
    Write-InfoLog "Deploying using kubectl kustomize..."
    
    # Generate secrets from environment variables
    Write-InfoLog "Generating secrets from environment variables..."
    try {
        & ".\scripts\generate-secrets.ps1"
    } catch {
        Write-ErrorLog "Failed to generate secrets: $_"
        Write-ErrorLog "Make sure you have a .env file or environment variables set"
        Write-ErrorLog "Run .\scripts\generate-env.ps1 to create a .env file"
        exit 1
    }
    
    kubectl apply -k $KUSTOMIZE_DIR
    
    Write-InfoLog "Kustomize deployment complete"
}

# Deploy using individual manifests
function Deploy-Manifests {
    Write-InfoLog "Deploying individual manifests..."
    
    # Deploy RBAC first
    Write-InfoLog "Deploying RBAC..."
    kubectl apply -f "$MANIFEST_DIR/rbac/rbac.yaml"
    
    # Deploy config
    Write-InfoLog "Deploying ConfigMaps and Secrets..."
    kubectl apply -f "$MANIFEST_DIR/config/configmaps.yaml"
    kubectl apply -f "$MANIFEST_DIR/config/secrets.yaml"
    
    # Deploy storage
    Write-InfoLog "Deploying storage volumes..."
    kubectl apply -f "$MANIFEST_DIR/storage/volumes.yaml"
    
    # Deploy services
    Write-InfoLog "Deploying MongoDB..."
    kubectl apply -f "$MANIFEST_DIR/services/mongodb.yaml"
    
    Write-InfoLog "Deploying PostgreSQL..."
    kubectl apply -f "$MANIFEST_DIR/services/postgres.yaml"
    
    Write-InfoLog "Deploying Airflow..."
    kubectl apply -f "$MANIFEST_DIR/services/airflow.yaml"
    
    Write-InfoLog "Manifest deployment complete"
}

# Wait for deployments to be ready
function Wait-ForDeployments {
    Write-InfoLog "Waiting for deployments to be ready... (this may take 3-5 minutes)"
    
    # Wait for Airflow deployments
    try {
        kubectl wait --for=condition=available --timeout=300s `
            -n $NAMESPACE `
            deployment/airflow-webserver `
            deployment/airflow-scheduler 2>$null
    }
    catch {
        Write-WarnLog "Some Airflow deployments may still be rolling out"
    }
    
    # Wait for StatefulSets
    try {
        kubectl wait --for=condition=ready --timeout=300s `
            -n $NAMESPACE `
            statefulset/mongodb `
            statefulset/postgres 2>$null
    }
    catch {
        Write-WarnLog "Some StatefulSets may still be rolling out"
    }
    
    Write-InfoLog "Deployments ready check complete"
}

# Get service URLs
function Show-ServiceURLs {
    Write-InfoLog "Service URLs:"
    
    # Get Airflow WebUI URL
    Write-Host ""
    Write-Host "Airflow WebUI:" -ForegroundColor $ColorInfo
    Write-Host "  - Local: http://localhost:8080 (after port-forward)"
    Write-Host "  - In-cluster: http://airflow-webserver.trips-ticks.svc.cluster.local:8080"
    
    # Get MongoDB connection string
    Write-Host ""
    Write-Host "MongoDB connection:" -ForegroundColor $ColorInfo
    Write-Host "  - mongodb://admin:change-me-in-production@mongodb:27017/admin?authSource=admin"
    
    # Get PostgreSQL connection string
    Write-Host ""
    Write-Host "PostgreSQL connection:" -ForegroundColor $ColorInfo
    Write-Host "  - postgresql://postgres:change-me-in-production@postgres:5432/trips_ticks_analytics"
    
    Write-Host ""
    Write-Host "To set up port forwarding, run:" -ForegroundColor $ColorWarn
    Write-Host "  kubectl port-forward -n $NAMESPACE svc/airflow-webserver 8080:8080"
}

# Setup port forwarding
function Setup-PortForwarding {
    Write-InfoLog "Setting up port forwarding for local testing..."
    
    Write-Host ""
    Write-Host "Starting port forwards:" -ForegroundColor $ColorInfo
    Write-Host "  - Airflow WebUI: http://localhost:8080" -ForegroundColor $ColorInfo
    Write-Host "  - MongoDB: localhost:27017" -ForegroundColor $ColorInfo
    Write-Host "  - PostgreSQL: localhost:5432" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "Note: Keep this terminal window open for port forwarding" -ForegroundColor $ColorWarn
    Write-Host ""
    
    # Run port forwards in sequence (they will be interactive)
    kubectl port-forward -n $NAMESPACE svc/airflow-webserver 8080:8080
}

# Main execution
function Main {
    Write-InfoLog "Starting deployment of Trips and Ticks..."
    Write-Host ""
    
    Invoke-PrerequisiteCheck
    New-Namespace
    New-StorageClass
    
    # Choose deployment method
    if ($DeploymentMethod -eq 'manifests') {
        Deploy-Manifests
    }
    else {
        Deploy-Kustomize
    }
    
    Wait-ForDeployments
    Show-ServiceURLs
    
    if ($PortForward -or $DeploymentMethod -in @('--port-forward', '--pf')) {
        Setup-PortForwarding
    }
    
    Write-Host ""
    Write-InfoLog "Deployment complete!"
}

# Run main function
Main
