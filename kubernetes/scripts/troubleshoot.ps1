# Kubernetes Troubleshooting Script for Trips and Ticks (PowerShell)
# This script helps diagnose issues with the deployment

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('all', 'report', 'interactive', '')]
    [string]$Mode = 'interactive'
)

$ErrorActionPreference = "Continue"

# Configuration
$NAMESPACE = "trips-ticks"

# Colors for output
$ColorInfo = "Green"
$ColorWarn = "Yellow"
$ColorError = "Red"
$ColorSection = "Cyan"

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

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor $ColorSection
    Write-Host ""
}

# Check namespace
function Test-Namespace {
    Write-Section "Checking Namespace"
    
    try {
        $ns = kubectl get namespace $NAMESPACE 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-InfoLog "Namespace '$NAMESPACE' exists"
            kubectl get namespace $NAMESPACE
        }
    }
    catch {
        Write-ErrorLog "Namespace '$NAMESPACE' does not exist"
    }
}

# Check pod status
function Test-PodStatus {
    Write-Section "Checking Pod Status"
    
    Write-InfoLog "All pods in namespace:"
    kubectl get pods -n $NAMESPACE
    
    Write-InfoLog "Pod details:"
    kubectl describe pods -n $NAMESPACE
}

# Check deployment status
function Test-DeploymentStatus {
    Write-Section "Checking Deployment Status"
    
    Write-InfoLog "All deployments:"
    kubectl get deployments -n $NAMESPACE
    
    Write-InfoLog "Deployment details:"
    kubectl describe deployments -n $NAMESPACE
}

# Check statefulset status
function Test-StatefulSetStatus {
    Write-Section "Checking StatefulSet Status"
    
    Write-InfoLog "All statefulsets:"
    kubectl get statefulsets -n $NAMESPACE
    
    Write-InfoLog "StatefulSet details:"
    kubectl describe statefulsets -n $NAMESPACE
}

# Check service status
function Test-ServiceStatus {
    Write-Section "Checking Service Status"
    
    Write-InfoLog "All services:"
    kubectl get services -n $NAMESPACE
    
    Write-InfoLog "Service endpoints:"
    kubectl get endpoints -n $NAMESPACE
}

# Check storage
function Test-Storage {
    Write-Section "Checking Storage"
    
    Write-InfoLog "PersistentVolumes:"
    kubectl get pv
    
    Write-InfoLog "PersistentVolumeClaims:"
    kubectl get pvc -n $NAMESPACE
}

# Check pod logs
function Test-PodLogs {
    Write-Section "Checking Pod Logs"
    
    $pods = kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}' 2>$null
    
    if ($pods) {
        foreach ($pod in $pods.Split(' ')) {
            if ($pod) {
                Write-InfoLog "Logs for pod: $pod"
                kubectl logs -n $NAMESPACE $pod --tail=50 2>$null
                Write-Host ""
            }
        }
    }
    else {
        Write-WarnLog "No pods found"
    }
}

# Check events
function Test-Events {
    Write-Section "Checking Recent Events"
    
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'
}

# Check RBAC
function Test-RBAC {
    Write-Section "Checking RBAC"
    
    Write-InfoLog "ServiceAccounts:"
    kubectl get serviceaccounts -n $NAMESPACE
    
    Write-InfoLog "ClusterRoles (filtered):"
    kubectl get clusterrole 2>$null | Select-String "airflow" -ErrorAction SilentlyContinue
    
    Write-InfoLog "ClusterRoleBindings (filtered):"
    kubectl get clusterrolebinding 2>$null | Select-String "airflow" -ErrorAction SilentlyContinue
}

# Check network connectivity
function Test-NetworkConnectivity {
    Write-Section "Checking Network Connectivity"
    
    Write-InfoLog "Running network test from a pod..."
    
    $pod = kubectl get pods -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}' 2>$null
    
    if ($pod) {
        Write-InfoLog "Testing DNS resolution from pod: $pod"
        kubectl exec -n $NAMESPACE $pod -- nslookup mongodb 2>$null
        kubectl exec -n $NAMESPACE $pod -- nslookup postgres 2>$null
    }
    else {
        Write-WarnLog "No running pods found to test network connectivity"
    }
}

# Check node status
function Test-NodeStatus {
    Write-Section "Checking Node Status"
    
    kubectl get nodes
    
    Write-InfoLog "Node details:"
    kubectl describe nodes
}

# Generate diagnostic report
function New-DiagnosticReport {
    Write-Section "Generating Diagnostic Report"
    
    $reportFile = "trips-ticks-diagnostics-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    
    "Trips and Ticks Kubernetes Diagnostics Report" | Out-File -FilePath $reportFile
    "Generated: $(Get-Date)" | Out-File -FilePath $reportFile -Append
    "" | Out-File -FilePath $reportFile -Append
    
    "=== Cluster Info ===" | Out-File -FilePath $reportFile -Append
    kubectl cluster-info | Out-File -FilePath $reportFile -Append
    "" | Out-File -FilePath $reportFile -Append
    
    "=== Namespaces ===" | Out-File -FilePath $reportFile -Append
    kubectl get namespaces | Out-File -FilePath $reportFile -Append
    "" | Out-File -FilePath $reportFile -Append
    
    "=== Resources in $NAMESPACE ===" | Out-File -FilePath $reportFile -Append
    kubectl get all -n $NAMESPACE | Out-File -FilePath $reportFile -Append
    
    Write-InfoLog "Diagnostic report saved to: $reportFile"
}

# Show menu
function Show-Menu {
    Write-Host ""
    Write-Host "=== Troubleshooting Menu ===" -ForegroundColor $ColorSection
    Write-Host ""
    Write-Host "1. Check namespace"
    Write-Host "2. Check pod status"
    Write-Host "3. Check deployment status"
    Write-Host "4. Check statefulset status"
    Write-Host "5. Check service status"
    Write-Host "6. Check storage"
    Write-Host "7. Check pod logs"
    Write-Host "8. Check recent events"
    Write-Host "9. Check RBAC"
    Write-Host "10. Check network connectivity"
    Write-Host "11. Check node status"
    Write-Host "12. Generate diagnostic report"
    Write-Host "13. Run all checks"
    Write-Host "0. Exit"
    Write-Host ""
}

# Run all checks
function Invoke-AllChecks {
    Test-Namespace
    Test-PodStatus
    Test-DeploymentStatus
    Test-StatefulSetStatus
    Test-ServiceStatus
    Test-Storage
    Test-PodLogs
    Test-Events
    Test-RBAC
    Test-NodeStatus
    New-DiagnosticReport
}

# Interactive mode
function Invoke-InteractiveMode {
    while ($true) {
        Show-Menu
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            "1" { Test-Namespace }
            "2" { Test-PodStatus }
            "3" { Test-DeploymentStatus }
            "4" { Test-StatefulSetStatus }
            "5" { Test-ServiceStatus }
            "6" { Test-Storage }
            "7" { Test-PodLogs }
            "8" { Test-Events }
            "9" { Test-RBAC }
            "10" { Test-NetworkConnectivity }
            "11" { Test-NodeStatus }
            "12" { New-DiagnosticReport }
            "13" { Invoke-AllChecks }
            "0" { 
                Write-InfoLog "Exiting..."
                exit 0 
            }
            default {
                Write-ErrorLog "Invalid option"
            }
        }
    }
}

# Main execution
function Main {
    Write-InfoLog "Trips and Ticks Kubernetes Troubleshooting Tool"
    
    switch ($Mode) {
        'all' {
            Invoke-AllChecks
        }
        'report' {
            New-DiagnosticReport
        }
        default {
            Invoke-InteractiveMode
        }
    }
}

# Run main function
Main
