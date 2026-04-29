# Quick Start - Linux / macOS

This guide provides a quick start for deploying the Trips and Ticks Kubernetes deployment on Linux and macOS systems.

## Prerequisites

Before starting, ensure you have:

- [ ] Kubernetes cluster running (1.20+)
- [ ] kubectl installed and configured
- [ ] At least 4GB RAM available in cluster
- [ ] 50GB storage for databases

For detailed prerequisite information, see [README.md](../README.md) → Prerequisites section.

## Quick Deployment

### 1. Navigate to Kubernetes Directory

```bash
cd kubernetes
```

### 2. Run Deployment Script

```bash
bash scripts/deploy.sh
```

This will:
- Create the namespace
- Deploy all services (MongoDB, PostgreSQL, Airflow)
- Wait for services to be ready
- Display connection information

### 3. Verify Deployment

```bash
# Check pods are running
kubectl get pods -n trips-ticks

# Check services
kubectl get svc -n trips-ticks
```

## Accessing Services

### Airflow WebUI

```bash
# For Minikube
minikube service airflow-webserver -n trips-ticks

# Or use port forwarding
kubectl port-forward -n trips-ticks svc/airflow-webserver 8080:8080
# Access at http://localhost:8080
```

**Default Credentials:**
- Username: `airflow`
- Password: `airflow`

### MongoDB

```bash
# Connection string
mongodb://admin:change-me-in-production@mongodb:27017/admin?authSource=admin

# Port forward for external access
kubectl port-forward -n trips-ticks svc/mongodb 27017:27017
```

Port forwarded connection string: `mongodb://admin:change-me-in-production@localhost:27017/admin?authSource=admin`

### PostgreSQL

```bash
# Connection string
postgresql://postgres:change-me-in-production@postgres:5432/trips_ticks_analytics

# Port forward for external access
kubectl port-forward -n trips-ticks svc/postgres-service 5432:5432
```

Port forwarded connection string: `postgresql://postgres:change-me-in-production@localhost:5432/trips_ticks_analytics`

## Common Commands

```bash
# View pod logs
kubectl logs -n trips-ticks <pod-name>

# Execute command in pod
kubectl exec -n trips-ticks <pod-name> -- <command>

# Watch pod status
kubectl get pods -n trips-ticks --watch

# Delete a pod (will auto-restart)
kubectl delete pod -n trips-ticks <pod-name>

# Check resource usage
kubectl top pods -n trips-ticks

# View events
kubectl get events -n trips-ticks --sort-by='.lastTimestamp'
```

## Troubleshooting

### Pod Fails to Start

```bash
# Check pod status
kubectl describe pod -n trips-ticks <pod-name>

# View logs
kubectl logs -n trips-ticks <pod-name>

# Check for node issues
kubectl get nodes
kubectl describe node <node-name>
```

### Storage Issues

```bash
# Check persistent volumes
kubectl get pv -n trips-ticks

# Check persistent volume claims
kubectl get pvc -n trips-ticks

# Describe volume for details
kubectl describe pvc -n trips-ticks <pvc-name>
```

### Service Connectivity

```bash
# Test DNS
kubectl exec -n trips-ticks <pod-name> -- nslookup mongodb

# Test connectivity
kubectl exec -n trips-ticks <pod-name> -- nc -zv mongodb 27017
```

## Next Steps

- **Advanced Configuration:** See [POSIX_SETUP_GUIDE.md](POSIX_SETUP_GUIDE.md)
- **All Commands:** See [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Architecture Details:** See [ARCHITECTURE.md](ARCHITECTURE.md)
- **For Windows:** See [WINDOWS_QUICK_START.md](WINDOWS_QUICK_START.md)

## Cleanup

To remove the deployment:

```bash
bash scripts/cleanup.sh
```

Or manually:

```bash
kubectl delete namespace trips-ticks
```
