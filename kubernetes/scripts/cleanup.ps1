# Kubernetes Cleanup Script for Trips and Ticks (PowerShell)
# This script removes all deployed resources from the cluster

param(
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Configuration
$NAMESPACE = "trips-ticks"

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

# Confirm deletion
function Confirm-Deletion {
    if ($Force) {
        return $true
    }
    
    Write-Host ""
    Write-WarnLog "Are you sure you want to DELETE all resources in namespace '$NAMESPACE'?"
    Write-Host ""
    $confirmation = Read-Host "Type 'yes' to confirm deletion"
    
    if ($confirmation -eq 'yes') {
        return $true
    }
    else {
        Write-InfoLog "Deletion cancelled"
        return $false
    }
}

# Delete all resources
function Remove-AllResources {
    Write-InfoLog "Deleting all resources in namespace: $NAMESPACE"
    
    # Delete deployments
    Write-InfoLog "Deleting deployments..."
    kubectl delete deployment --all -n $NAMESPACE --ignore-not-found=true 2>$null
    
    # Delete statefulsets
    Write-InfoLog "Deleting statefulsets..."
    kubectl delete statefulset --all -n $NAMESPACE --ignore-not-found=true 2>$null
    
    # Delete services
    Write-InfoLog "Deleting services..."
    kubectl delete svc --all -n $NAMESPACE --ignore-not-found=true 2>$null
    
    # Delete PVCs
    Write-InfoLog "Deleting PersistentVolumeClaims..."
    kubectl delete pvc --all -n $NAMESPACE --ignore-not-found=true 2>$null
    
    # Delete PVs
    Write-InfoLog "Deleting PersistentVolumes..."
    kubectl delete pv -l namespace=$NAMESPACE --ignore-not-found=true 2>$null
    
    # Delete ConfigMaps and Secrets
    Write-InfoLog "Deleting ConfigMaps and Secrets..."
    kubectl delete configmap,secret --all -n $NAMESPACE --ignore-not-found=true 2>$null
    
    # Delete RBAC resources
    Write-InfoLog "Deleting RBAC resources..."
    kubectl delete serviceaccount -n $NAMESPACE --ignore-not-found=true 2>$null
    kubectl delete clusterrole -l namespace=$NAMESPACE --ignore-not-found=true 2>$null
    kubectl delete clusterrolebinding -l namespace=$NAMESPACE --ignore-not-found=true 2>$null
    
    # Delete network policies
    Write-InfoLog "Deleting network policies..."
    kubectl delete networkpolicy --all -n $NAMESPACE --ignore-not-found=true 2>$null
    
    Write-InfoLog "Resources deleted"
}

# Delete namespace
function Remove-Namespace {
    Write-InfoLog "Deleting namespace: $NAMESPACE"
    kubectl delete namespace $NAMESPACE --ignore-not-found=true 2>$null
    Write-InfoLog "Namespace deleted"
}

# Show remaining resources
function Show-RemainingResources {
    Write-InfoLog "Checking for remaining resources..."
    
    try {
        $resources = kubectl get all -n $NAMESPACE --no-headers 2>$null
        if ($resources) {
            Write-WarnLog "Some resources may still exist:"
            kubectl get all -n $NAMESPACE 2>$null
        }
        else {
            Write-InfoLog "All resources have been deleted"
        }
    }
    catch {
        Write-InfoLog "Namespace has been cleaned up"
    }
}

# Main execution
function Main {
    Write-InfoLog "Trips and Ticks Kubernetes Cleanup Script"
    Write-Host ""
    
    if (-not (Confirm-Deletion)) {
        exit 0
    }
    
    Remove-AllResources
    Remove-Namespace
    Show-RemainingResources
    
    Write-Host ""
    Write-InfoLog "Cleanup complete!"
}

# Run main function
Main
