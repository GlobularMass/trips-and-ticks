# Trips and Ticks - Kubernetes Deployment Guide

This directory contains the Kubernetes manifests and deployment scripts for the Trips and Ticks application, which includes MongoDB, PostgreSQL, and Apache Airflow.

## Cross-Platform Support

This deployment supports **Linux, macOS, and Windows**:
- **Linux/macOS:** Use provided Bash scripts - See [POSIX_QUICK_START.md](docs/POSIX_QUICK_START.md)
- **Windows:** Use PowerShell scripts (`.ps1` files) - See [WINDOWS_QUICK_START.md](docs/WINDOWS_QUICK_START.md)
- **All platforms:** Use `kubectl` commands directly (kustomize is built-in)

For platform-specific setup and detailed instructions, see the quick start guides linked above.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [Getting Started](#getting-started)
- [Detailed Deployment](#detailed-deployment)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Advanced Topics](#advanced-topics)

## Architecture Overview

The Kubernetes deployment includes:

### Components

1. **MongoDB StatefulSet**
   - Primary data store for application data
   - Persistent volume mount for data durability
   - Authentication enabled
   - Replica set support (configured for single replica)

2. **PostgreSQL StatefulSet**
   - Relational database for analytics and metadata
   - Persistent volume mount
   - Multiple databases: `trips_ticks_analytics`
   - Support for Airflow metadata

3. **Apache Airflow**
   - **Webserver Deployment**: Web UI for DAG management (port 8080)
   - **Scheduler Deployment**: Schedules and monitors DAG execution
   - LocalExecutor for task execution
   - Persistent volumes for DAGs and logs
   - PostgreSQL as metadata database

4. **Supporting Services**
   - Namespace isolation (`trips-ticks`)
   - RBAC for security
   - Network policies for internal communication
   - ConfigMaps for application configuration
   - Secrets for sensitive credentials
   - Persistent volumes for data durability

### Data Flow

```
External Application
     ↓
MongoDB (Primary data store)
     ↓
Airflow DAGs (Data processing) ← PostgreSQL (Analytics/Metadata)
     ↓
Processed Results & Reports
```

## Prerequisites

### System Requirements

- Kubernetes cluster (1.20+)
- kubectl CLI (1.20+) - includes built-in kustomize support
- Helm (optional, for templated deployments)
- At least 4GB RAM available in cluster
- 50GB storage for databases

### Tools Installation

**kubectl** (Kubernetes CLI):
```bash
# macOS
brew install kubectl

# Ubuntu/Debian
sudo apt-get install -y kubectl

# Windows
choco install kubernetes-cli
# Or download from: https://kubernetes.io/docs/tasks/tools/#kubectl
```

**Docker Desktop (Required for local Kubernetes on Windows/macOS):**
```bash
# macOS
brew install docker

# Windows & macOS
# Download from: https://www.docker.com/products/docker-desktop
# Make sure to enable Kubernetes during installation
```

**Helm** (optional):
```bash
# macOS
brew install helm

# Ubuntu/Debian
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Windows
choco install kubernetes-helm
```

### Kubernetes Cluster Setup

**For Windows users:** See [WINDOWS_SETUP_GUIDE.md](docs/WINDOWS_SETUP_GUIDE.md) for detailed Windows setup instructions.

**For local development using Minikube:**

```bash
# Install Minikube
brew install minikube

# Start cluster with sufficient resources
minikube start --cpus 4 --memory 8192 --disk-size 50g

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

**For Docker Desktop (Windows/macOS):**
- Download and install Docker Desktop
- Enable Kubernetes in Docker Desktop settings
- Verify: `kubectl cluster-info`

**For managed Kubernetes (AWS EKS, GCP GKE, Azure AKS):**
- Follow provider-specific setup documentation
- Ensure kubectl is configured with proper context
- Verify cluster access: `kubectl cluster-info`

## Environment Setup

Before deploying, you need to set up environment variables for database credentials and Airflow configuration.

### Option 1: Generate .env file automatically

**Windows (PowerShell):**
```powershell
# Generate secure random credentials
.\scripts\generate-env.ps1

# Review the generated .env file
Get-Content .env
```

**Linux/macOS (Bash):**
```bash
# Generate secure random credentials
./scripts/generate-env.sh

# Review the generated .env file
cat .env
```

### Option 2: Create .env file manually

Copy the example file and edit the values:
```bash
cp .env.example .env
# Edit .env with your preferred credentials
```

### Security Notes

- **DO NOT commit the `.env` file to version control!**
- The deployment scripts will automatically generate Kubernetes secrets from your `.env` file
- For production, use strong, unique passwords
- Consider using Kubernetes secrets management solutions like Sealed Secrets

## Directory Structure

```
kubernetes/
├── README.md                          # This file
├── kustomization.yaml                 # Kustomize config (used with kubectl -k)
├── manifests/
│   ├── config/
│   │   ├── configmaps.yaml           # Application configuration
│   │   └── secrets.yaml              # Sensitive credentials (generated)
│   ├── rbac/
│   │   └── rbac.yaml                 # ServiceAccounts, Roles, RoleBindings
│   ├── services/
│   │   ├── mongodb.yaml              # MongoDB StatefulSet & Service
│   │   ├── postgres.yaml             # PostgreSQL StatefulSet & Service
│   │   └── airflow.yaml              # Airflow Webserver & Scheduler
│   └── storage/
│       └── volumes.yaml              # PersistentVolumes & PersistentVolumeClaims
├── helm/
│   └── values.yaml                   # Helm chart values
└── scripts/
    ├── deploy.sh                     # Deployment script
    ├── cleanup.sh                    # Resource cleanup script
    └── troubleshoot.sh               # Troubleshooting tool
```

## Getting Started

Choose your platform for quick start instructions:

### 🪟 Windows Users

For complete Windows setup and quick deployment, see:
- **Quick Start (5 minutes):** [WINDOWS_QUICK_START.md](docs/WINDOWS_QUICK_START.md)
- **Detailed Setup:** [WINDOWS_SETUP_GUIDE.md](docs/WINDOWS_SETUP_GUIDE.md)

Run deployment with PowerShell:
```powershell
cd kubernetes
.\scripts\deploy.ps1
```

### 🐧 Linux / 🍎 macOS Users

For quick start instructions and deployment, see:
- **Quick Start (5 minutes):** [POSIX_QUICK_START.md](docs/POSIX_QUICK_START.md)
- **Advanced Setup:** [POSIX_SETUP_GUIDE.md](docs/POSIX_SETUP_GUIDE.md)

Run deployment with Bash:
```bash
cd kubernetes
bash scripts/deploy.sh
```

### 📖 All Users

For command reference covering all platforms, see:
- **Quick Reference:** [QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)
- **Documentation Index:** [INDEX.md](docs/INDEX.md)

## Accessing Services

After deployment, services are accessible via port forwarding. For platform-specific instructions:

- **Windows:** See [WINDOWS_QUICK_START.md](docs/WINDOWS_QUICK_START.md) → Accessing Services
- **Linux/macOS:** See [POSIX_QUICK_START.md](docs/POSIX_QUICK_START.md) → Accessing Services
- **All Platforms:** See [QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md) → Service Access

Default service endpoints:
- **Airflow WebUI:** Port 8080
- **MongoDB:** Port 27017
- **PostgreSQL:** Port 5432

## Detailed Deployment

### Step 1: Create Namespace and Storage Class

```bash
# Manually create namespace
kubectl create namespace trips-ticks
kubectl label namespace trips-ticks name=trips-ticks

# Create local storage class (required for PersistentVolumes)
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
```

### Step 2: Deploy Configuration

```bash
# Deploy ConfigMaps
kubectl apply -f manifests/config/configmaps.yaml

# Note: secrets.yaml is generated automatically by deployment scripts
# from your .env file and should not be applied manually
```

### Step 3: Deploy Storage

```bash
# Create PersistentVolumes and PersistentVolumeClaims
kubectl apply -f manifests/storage/volumes.yaml

# Verify storage is created
kubectl get pv -n trips-ticks
kubectl get pvc -n trips-ticks
```

### Step 4: Deploy RBAC

```bash
# Create ServiceAccounts and RoleBindings
kubectl apply -f manifests/rbac/rbac.yaml
```

### Step 5: Deploy Services

```bash
# Deploy MongoDB
kubectl apply -f manifests/services/mongodb.yaml

# Deploy PostgreSQL
kubectl apply -f manifests/services/postgres.yaml

# Deploy Airflow
kubectl apply -f manifests/services/airflow.yaml

# Wait for deployments (2-5 minutes typical)
kubectl wait --for=condition=available --timeout=300s \
  deployment/airflow-webserver -n trips-ticks
```

### Step 6: Verify Deployment

```bash
# Check pods
kubectl get pods -n trips-ticks

# Check services
kubectl get svc -n trips-ticks

# Check events for errors
kubectl get events -n trips-ticks --sort-by='.lastTimestamp'
```

## Configuration

### Environment Variables

Key environment variables in `manifests/config/configmaps.yaml`:

| Variable | Default | Description |
|----------|---------|-------------|
| ENVIRONMENT | production | Deployment environment |
| LOG_LEVEL | INFO | Application logging level |
| MONGODB_HOST | mongodb | MongoDB service hostname |
| MONGODB_PORT | 27017 | MongoDB service port |
| MONGODB_DB | trips_ticks_db | MongoDB database name |
| POSTGRES_HOST | postgres | PostgreSQL service hostname |
| POSTGRES_PORT | 5432 | PostgreSQL service port |
| POSTGRES_DB | trips_ticks_analytics | PostgreSQL database name |
| AIRFLOW_WEBSERVER_URL | http://airflow-webserver:8080 | Airflow webserver endpoint |

### Credentials

Credentials are managed through environment variables and automatically generated into `manifests/config/secrets.yaml` by the deployment scripts. 

**Default values (can be overridden in .env file):**

**MongoDB:**
- Username: `admin`
- Password: Auto-generated secure password

**PostgreSQL:**
- Admin Username: `postgres`
- Admin Password: Auto-generated secure password
- Airflow Username: `airflow`
- Airflow Password: `airflow`

**Airflow:**
- Admin Username: `admin`
- Admin Password: Auto-generated secure password
- Database Connection: Auto-constructed from PostgreSQL Airflow credentials
- Fernet Key: Auto-generated secure key

⚠️ **IMPORTANT**: For production environments:

1. **Use strong passwords** in your `.env` file before deployment
2. **Backup your `.env` file** securely (password manager recommended)
3. **Never commit `.env` files** to version control
4. **Rotate credentials** regularly for security

The deployment scripts will automatically create secure Kubernetes secrets from your `.env` file.
kubectl edit secret airflow-credentials -n trips-ticks

# Or create new secrets with custom values
kubectl create secret generic postgres-credentials \
  --from-literal=admin-user=postgres \
  --from-literal=admin-password=your-secure-password \
  --from-literal=airflow-user=airflow \
  --from-literal=airflow-password=your-airflow-password \
  -n trips-ticks --dry-run=client -o yaml | kubectl apply -f -
```

### Resource Limits

Default resource requests/limits in manifests:

**MongoDB:**
- Requests: 512Mi RAM, 250m CPU
- Limits: 1Gi RAM, 500m CPU

**PostgreSQL:**
- Requests: 512Mi RAM, 250m CPU
- Limits: 1Gi RAM, 500m CPU

**Airflow Webserver:**
- Requests: 1Gi RAM, 500m CPU
- Limits: 2Gi RAM, 1000m CPU

**Airflow Scheduler:**
- Requests: 512Mi RAM, 250m CPU
- Limits: 1Gi RAM, 500m CPU

Adjust in manifests as needed for your infrastructure.

### Storage Sizes

Default storage allocations:

| Component | Size | Purpose |
|-----------|------|---------|
| MongoDB | 10Gi | Primary application data |
| PostgreSQL | 20Gi | Analytics and reporting data |
| Airflow DAGs | 5Gi | Workflow definitions |
| Airflow Logs | 10Gi | Task execution logs |

Update in `manifests/storage/volumes.yaml` as needed.

## Troubleshooting

### Using the Troubleshooting Tool

The interactive troubleshooting script provides comprehensive diagnostics.

For platform-specific instructions on running the troubleshooting script:
- **Windows:** See [WINDOWS_QUICK_START.md](docs/WINDOWS_QUICK_START.md) or [QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)
- **Linux/macOS:** See [POSIX_QUICK_START.md](docs/POSIX_QUICK_START.md) or [QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)

### Common Issues

#### 1. Pods Stay in Pending State

**Symptom:** `kubectl get pods -n trips-ticks` shows pods in "Pending" state

**Causes:**
- Insufficient cluster resources
- PersistentVolume not available
- Node affinity mismatch

**Solutions:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n trips-ticks

# Check node resources
kubectl top nodes

# Verify PVs are bound
kubectl get pv,pvc -n trips-ticks

# For Minikube, check available space
minikube ssh -- df -h /var/data
```

#### 2. CrashLoopBackOff Errors

**Symptom:** Pods restart repeatedly (CrashLoopBackOff status)

**Solutions:**
```bash
# Check pod logs
kubectl logs <pod-name> -n trips-ticks --tail=100

# Check previous logs if container crashed
kubectl logs <pod-name> -n trips-ticks --previous

# Describe pod for detailed status
kubectl describe pod <pod-name> -n trips-ticks
```

#### 3. Service Connectivity Issues

**Symptom:** Can't connect between pods or to services

**Solutions:**
```bash
# Test DNS from within cluster
kubectl run -it --image=busybox:1.28 debug -n trips-ticks -- sh
# Inside pod: nslookup mongodb

# Check service endpoints
kubectl get endpoints -n trips-ticks

# Test connectivity from pod
kubectl exec <pod-name> -n trips-ticks -- ping mongodb
```

#### 4. Storage Issues

**Symptom:** Pods fail with storage-related errors

**Solutions:**
```bash
# Check storage class
kubectl get storageclass

# Check PV and PVC status
kubectl get pv,pvc -n trips-ticks

# Check node storage
kubectl describe nodes

# For Minikube, create storage directories
minikube ssh -- mkdir -p /var/data/{mongodb,postgres,airflow/{dags,logs}}
```

#### 5. Airflow Connection Errors

**Symptom:** Airflow can't connect to PostgreSQL or MongoDB

**Solutions:**
```bash
# Verify database pods are running
kubectl get pods -n trips-ticks -l app=postgres
kubectl get pods -n trips-ticks -l app=mongodb

# Check service DNS resolution
kubectl exec -n trips-ticks <airflow-pod> -- nslookup postgres
kubectl exec -n trips-ticks <airflow-pod> -- nslookup mongodb

# Test direct connectivity
kubectl port-forward -n trips-ticks svc/postgres 5432:5432 &
psql -h localhost -U airflow -d airflow

# Check Airflow logs
kubectl logs -n trips-ticks deployment/airflow-webserver --tail=100
```

## Cleanup

### Remove All Resources

Run the cleanup script for your platform:
- **Windows:** `.\scripts\cleanup.ps1`
- **Linux/macOS:** `bash scripts/cleanup.sh`

For detailed instructions, see:
- **Windows:** [WINDOWS_QUICK_START.md](docs/WINDOWS_QUICK_START.md) → Cleanup
- **Linux/macOS:** [POSIX_QUICK_START.md](docs/POSIX_QUICK_START.md) → Cleanup

### Partial Cleanup

```bash
# Delete only deployments
kubectl delete deployment --all -n trips-ticks

# Delete only services
kubectl delete svc --all -n trips-ticks

# Delete only PVCs (keeps PVs)
kubectl delete pvc --all -n trips-ticks
```

## Advanced Topics

### High Availability Setup

For production environments, consider:

1. **Multiple Replicas:**
   - MongoDB: Enable replica sets with 3+ nodes
   - PostgreSQL: Add read replicas or failover standby
   - Airflow: Multiple scheduler instances

2. **Update manifests:**
   ```yaml
   spec:
     replicas: 3  # For deployments
   spec:
     serviceName: mongodb
     replicas: 3  # For StatefulSets
   ```

3. **Network policies:** Enable strict ingress/egress rules

### Load Balancing

#### External Access with Ingress

```bash
# Enable ingress addon (Minikube)
minikube addons enable ingress

# Create Ingress resource
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: trips-ticks-ingress
  namespace: trips-ticks
spec:
  ingressClassName: nginx
  rules:
  - host: trips-ticks.local
    http:
      paths:
      - path: /airflow
        pathType: Prefix
        backend:
          service:
            name: airflow-webserver
            port:
              number: 8080
EOF
```

### Monitoring and Logging

#### Prometheus Metrics

```bash
# Deploy Prometheus Operator (separate guide)
# Mount Prometheus scrape configs in ConfigMaps
# Configure service monitors for each component
```

#### ELK Stack Integration

```bash
# Ship logs to Elasticsearch
# Configure Kibana dashboards
# Set up Logstash for log processing
```

### GitOps Workflow

Use tools like ArgoCD for continuous synchronization:

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Create Application CR
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: trips-ticks
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo
    targetRevision: main
    path: kubernetes
  destination:
    server: https://kubernetes.default.svc
    namespace: trips-ticks
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

## Support and Resources

- **Windows Setup:** [WINDOWS_SETUP_GUIDE.md](docs/WINDOWS_SETUP_GUIDE.md) - Detailed Windows setup instructions
- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Apache Airflow on Kubernetes](https://airflow.apache.org/docs/apache-airflow/stable/kubernetes.html)
- [MongoDB Kubernetes Operator](https://www.mongodb.com/kubernetes)
- [PostgreSQL in Kubernetes](https://www.postgresql.org/wiki)

## License

See LICENSE file in the project root.
