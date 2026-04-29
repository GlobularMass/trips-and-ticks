#!/bin/bash

# Kubernetes Troubleshooting Script for Trips and Ticks
# This script helps diagnose issues with the deployment

set -e

# Configuration
NAMESPACE="trips-ticks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Check namespace
check_namespace() {
    log_section "Checking Namespace"
    
    if kubectl get namespace $NAMESPACE &>/dev/null; then
        log_info "Namespace '$NAMESPACE' exists"
        kubectl get namespace $NAMESPACE
    else
        log_error "Namespace '$NAMESPACE' does not exist"
    fi
}

# Check pod status
check_pod_status() {
    log_section "Checking Pod Status"
    
    log_info "All pods in namespace:"
    kubectl get pods -n $NAMESPACE
    
    log_info "\nPod details:"
    kubectl describe pods -n $NAMESPACE
}

# Check deployment status
check_deployment_status() {
    log_section "Checking Deployment Status"
    
    log_info "All deployments:"
    kubectl get deployments -n $NAMESPACE
    
    log_info "\nDeployment details:"
    kubectl describe deployments -n $NAMESPACE
}

# Check statefulset status
check_statefulset_status() {
    log_section "Checking StatefulSet Status"
    
    log_info "All statefulsets:"
    kubectl get statefulsets -n $NAMESPACE
    
    log_info "\nStatefulSet details:"
    kubectl describe statefulsets -n $NAMESPACE
}

# Check service status
check_service_status() {
    log_section "Checking Service Status"
    
    log_info "All services:"
    kubectl get services -n $NAMESPACE
    
    log_info "\nService endpoints:"
    kubectl get endpoints -n $NAMESPACE
}

# Check storage
check_storage() {
    log_section "Checking Storage"
    
    log_info "PersistentVolumes:"
    kubectl get pv -n $NAMESPACE
    
    log_info "\nPersistentVolumeClaims:"
    kubectl get pvc -n $NAMESPACE
}

# Check pod logs
check_pod_logs() {
    log_section "Checking Pod Logs"
    
    local pods=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
    
    for pod in $pods; do
        log_info "Logs for pod: $pod"
        kubectl logs -n $NAMESPACE $pod --tail=50 || log_warn "Could not retrieve logs for $pod"
        echo ""
    done
}

# Check events
check_events() {
    log_section "Checking Recent Events"
    
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'
}

# Check RBAC
check_rbac() {
    log_section "Checking RBAC"
    
    log_info "ServiceAccounts:"
    kubectl get serviceaccounts -n $NAMESPACE
    
    log_info "\nClusterRoles (filtered):"
    kubectl get clusterrole | grep airflow || log_info "No airflow ClusterRoles found"
    
    log_info "\nClusterRoleBindings (filtered):"
    kubectl get clusterrolebinding | grep airflow || log_info "No airflow ClusterRoleBindings found"
}

# Check network connectivity
check_network_connectivity() {
    log_section "Checking Network Connectivity"
    
    log_info "Running network test from a pod..."
    
    # Get first running pod
    local pod=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod" ]; then
        log_warn "No running pods found to test network connectivity"
        return
    fi
    
    log_info "Testing DNS resolution from pod: $pod"
    kubectl exec -n $NAMESPACE $pod -- nslookup mongodb || log_warn "DNS resolution failed for MongoDB"
    kubectl exec -n $NAMESPACE $pod -- nslookup postgres || log_warn "DNS resolution failed for PostgreSQL"
}

# Check node status
check_node_status() {
    log_section "Checking Node Status"
    
    kubectl get nodes
    
    log_info "\nNode details:"
    kubectl describe nodes
}

# Generate diagnostic report
generate_report() {
    log_section "Generating Diagnostic Report"
    
    local report_file="trips-ticks-diagnostics-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Trips and Ticks Kubernetes Diagnostics Report"
        echo "Generated: $(date)"
        echo ""
        echo "=== Cluster Info ==="
        kubectl cluster-info
        echo ""
        echo "=== Namespaces ==="
        kubectl get namespaces
        echo ""
        echo "=== Resources in $NAMESPACE ==="
        kubectl get all -n $NAMESPACE
    } > "$report_file"
    
    log_info "Diagnostic report saved to: $report_file"
}

# Interactive troubleshooting menu
show_menu() {
    echo -e "\n${BLUE}=== Troubleshooting Menu ===${NC}\n"
    echo "1. Check namespace"
    echo "2. Check pod status"
    echo "3. Check deployment status"
    echo "4. Check statefulset status"
    echo "5. Check service status"
    echo "6. Check storage"
    echo "7. Check pod logs"
    echo "8. Check recent events"
    echo "9. Check RBAC"
    echo "10. Check network connectivity"
    echo "11. Check node status"
    echo "12. Generate diagnostic report"
    echo "13. Run all checks"
    echo "0. Exit"
    echo ""
}

run_all_checks() {
    check_namespace
    check_pod_status
    check_deployment_status
    check_statefulset_status
    check_service_status
    check_storage
    check_pod_logs
    check_events
    check_rbac
    check_network_connectivity
    check_node_status
    generate_report
}

# Interactive mode
interactive_mode() {
    while true; do
        show_menu
        read -p "Select an option: " choice
        
        case $choice in
            1) check_namespace ;;
            2) check_pod_status ;;
            3) check_deployment_status ;;
            4) check_statefulset_status ;;
            5) check_service_status ;;
            6) check_storage ;;
            7) check_pod_logs ;;
            8) check_events ;;
            9) check_rbac ;;
            10) check_network_connectivity ;;
            11) check_node_status ;;
            12) generate_report ;;
            13) run_all_checks ;;
            0) log_info "Exiting..."; exit 0 ;;
            *) log_error "Invalid option" ;;
        esac
    done
}

# Main execution
main() {
    log_info "Trips and Ticks Kubernetes Troubleshooting Tool"
    
    if [ "$1" == "all" ]; then
        run_all_checks
    elif [ "$1" == "report" ]; then
        generate_report
    else
        interactive_mode
    fi
}

# Run main function
main "$@"
