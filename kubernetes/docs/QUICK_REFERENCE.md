# Quick Reference Guide

## Platform-Specific Commands

### Linux / macOS
- **Deploy:** `bash kubernetes/scripts/deploy.sh`
- **Cleanup:** `bash kubernetes/scripts/cleanup.sh`
- **Troubleshoot:** `bash kubernetes/scripts/troubleshoot.sh`

### Windows (PowerShell)
- **Deploy:** `.\kubernetes\scripts\deploy.ps1`
- **Cleanup:** `.\kubernetes\scripts\cleanup.ps1`
- **Troubleshoot:** `.\kubernetes\scripts\troubleshoot.ps1`

For detailed Windows setup, see [WINDOWS_SETUP_GUIDE.md](WINDOWS_SETUP_GUIDE.md)

## One-Line Commands

### Deploy Everything

**Linux / macOS:**
```bash
bash kubernetes/scripts/deploy.sh
```

**Windows (PowerShell):**
```powershell
.\kubernetes\scripts\deploy.ps1
```

### Access Services
```bash
# Airflow WebUI (port forward)
kubectl port-forward -n trips-ticks svc/airflow-webserver 8080:8080

# MongoDB (port forward)
kubectl port-forward -n trips-ticks svc/mongodb 27017:27017

# PostgreSQL (port forward)
kubectl port-forward -n trips-ticks svc/postgres-service 5432:5432
```

### Check Status
```bash
# All pods
kubectl get pods -n trips-ticks

# All services with IPs
kubectl get svc -n trips-ticks

# Any errors or events
kubectl get events -n trips-ticks --sort-by='.lastTimestamp'

# Detailed status of a specific pod
kubectl describe pod <pod-name> -n trips-ticks

# Logs from a pod
kubectl logs <pod-name> -n trips-ticks --tail=100
```

### Connection Strings

**MongoDB:**
```
mongodb://admin:change-me-in-production@mongodb:27017/admin?authSource=admin
```

**PostgreSQL:**
```
postgresql://postgres:change-me-in-production@postgres:5432/trips_ticks_analytics
```

**Airflow Webserver:**
```
http://localhost:8080  (after port forward)
```

### Cleanup
```bash
bash kubernetes/scripts/cleanup.sh
```

```powershell
# Windows (PowerShell)
.\kubernetes\scripts\cleanup.ps1
```

### Troubleshooting
```bash
# Interactive troubleshooting menu
bash kubernetes/scripts/troubleshoot.sh

# Generate diagnostic report
bash kubernetes/scripts/troubleshoot.sh report

# Run all checks
bash kubernetes/scripts/troubleshoot.sh all
```

```powershell
# Windows (PowerShell) - Interactive menu
.\kubernetes\scripts\troubleshoot.ps1

# Generate diagnostic report
.\kubernetes\scripts\troubleshoot.ps1 -Mode report

# Run all checks
.\kubernetes\scripts\troubleshoot.ps1 -Mode all
```

## File Structure

```
trips-and-ticks/kubernetes/
├── README.md                          # Main documentation
├── POSIX_SETUP_GUIDE.md              # Detailed setup instructions
├── ARCHITECTURE.md                    # Technical architecture
├── kustomization.yaml                 # Kubernetes orchestration
├── helm/values.yaml                   # Helm chart configuration
├── manifests/
│   ├── config/
│   │   ├── configmaps.yaml           # App configuration
│   │   └── secrets.yaml              # Credentials
│   ├── rbac/
│   │   └── rbac.yaml                 # Security & permissions
│   ├── services/
│   │   ├── mongodb.yaml              # MongoDB setup
│   │   ├── postgres.yaml             # PostgreSQL setup
│   │   └── airflow.yaml              # Airflow setup
│   └── storage/
│       └── volumes.yaml              # Data storage
└── scripts/
    ├── deploy.sh                     # Deploy all components (Linux/macOS)
    ├── deploy.ps1                    # Deploy all components (Windows)
    ├── cleanup.sh                    # Remove all resources (Linux/macOS)
    ├── cleanup.ps1                   # Remove all resources (Windows)
    ├── troubleshoot.sh               # Diagnostic tool (Linux/macOS)
    └── troubleshoot.ps1              # Diagnostic tool (Windows)
```

## Common Tasks

### Deploy

**Linux / macOS:**
```bash
cd kubernetes
bash scripts/deploy.sh
```

**Windows (PowerShell):**
```powershell
cd kubernetes
.\scripts\deploy.ps1
```

### Check Deployment Status
```bash
kubectl get pods -n trips-ticks
kubectl get svc -n trips-ticks
```

### View Logs
```bash
# Airflow webserver
kubectl logs -n trips-ticks deployment/airflow-webserver --tail=50 -f

# Airflow scheduler
kubectl logs -n trips-ticks deployment/airflow-scheduler --tail=50 -f

# PostgreSQL
kubectl logs -n trips-ticks statefulset/postgres --tail=50 -f

# MongoDB
kubectl logs -n trips-ticks statefulset/mongodb --tail=50 -f
```

### Access Databases
```bash
# MongoDB shell
kubectl exec -it mongodb-0 -n trips-ticks -- mongosh

# PostgreSQL shell
kubectl exec -it postgres-0 -n trips-ticks -- psql -U postgres
```

### Update Configuration
```bash
# Edit ConfigMap
kubectl edit configmap app-config -n trips-ticks

# Edit Secret
kubectl edit secret postgres-credentials -n trips-ticks
```

### Scale Deployments
```bash
# Scale Airflow webserver to 3 replicas
kubectl scale deployment airflow-webserver --replicas=3 -n trips-ticks

# Scale StatefulSet (careful with databases)
kubectl scale statefulset mongodb --replicas=3 -n trips-ticks
```

### Restart Components
```bash
# Restart Airflow webserver
kubectl rollout restart deployment/airflow-webserver -n trips-ticks

# Restart Airflow scheduler
kubectl rollout restart deployment/airflow-scheduler -n trips-ticks
```

### Monitor Resources
```bash
# Watch resources in real-time
kubectl top nodes
kubectl top pods -n trips-ticks

# Watch pod status changes
watch kubectl get pods -n trips-ticks
```

### Cleanup and Remove Everything
```bash
bash scripts/cleanup.sh
```

## Service Discovery (DNS)

Within the cluster, services can be accessed via DNS:

```
<service-name>.<namespace>.svc.cluster.local:<port>
```

Examples:
- `mongodb.trips-ticks.svc.cluster.local:27017` for MongoDB
- `postgres.trips-ticks.svc.cluster.local:5432` for PostgreSQL
- `airflow-webserver.trips-ticks.svc.cluster.local:8080` for Airflow UI

## Performance Tips

- **MongoDB:** Keep data indexed, use aggregation pipeline for analytics
- **PostgreSQL:** Enable query planning, maintain indexes, monitor query performance
- **Airflow:** Limit DAG parsing frequency, optimize task dependencies, use task concurrency limits

## Security Best Practices

1. Change default credentials before production use
2. Enable TLS/SSL for external connections
3. Set up network policies for pod-to-pod communication
4. Enable RBAC and pod security policies
5. Regularly backup database contents
6. Monitor logs for suspicious activity
7. Implement access control for Airflow UI

## Resources Needed

- **Minimum:** 4GB RAM, 50GB storage
- **Recommended:** 8GB RAM, 100GB storage
- **Production:** 16GB+ RAM, 500GB+ storage

## Documentation Links

- [Main README](../README.md) - Overview and usage guide
- [Setup Guide](POSIX_SETUP_GUIDE.md) - Detailed configuration instructions
- [Architecture](ARCHITECTURE.md) - Technical architecture details
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Airflow Docs](https://airflow.apache.org/docs/)
- [MongoDB Docs](https://docs.mongodb.com/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)

## Support

For issues or questions:
1. Check the logs: `kubectl logs <pod-name> -n trips-ticks`
2. Run diagnostics: `bash scripts/troubleshoot.sh`
3. Review the architecture guide: [ARCHITECTURE.md](ARCHITECTURE.md)
4. Check the setup guide: [POSIX_SETUP_GUIDE.md](POSIX_SETUP_GUIDE.md)
