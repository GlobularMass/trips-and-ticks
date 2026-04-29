# 🚀 Trips and Ticks - Kubernetes Deployment (Cross-Platform)

Welcome! This comprehensive Kubernetes deployment supports **Windows, macOS, and Linux**.

## ⚡ Quick Start (Choose Your Platform)

### 🪟 Windows Users
```powershell
# Navigate to project directory
cd C:\Users\YourUsername\Documents\Development\trips-and-ticks

# Run deployment
.\kubernetes\scripts\deploy.ps1

# Access services (in separate PowerShell windows)
kubectl port-forward -n trips-ticks svc/airflow-webserver 8080:8080
# Visit: http://localhost:8080
```

**New to Windows deployment?** → Read [WINDOWS_QUICK_START.md](kubernetes/docs/WINDOWS_QUICK_START.md) (5 minutes)

### 🐧 Linux / 🍎 macOS Users
```bash
cd ~/Documents/Development/trips-and-ticks

# Run deployment
bash kubernetes/scripts/deploy.sh

# Access services
kubectl port-forward -n trips-ticks svc/airflow-webserver 8080:8080
# Visit: http://localhost:8080
```

**First time?** → Read [README.md](kubernetes/README.md) - Quick Start section

## 📖 Documentation Overview

### For Everyone
- **[INDEX.md](kubernetes/docs/INDEX.md)** - Navigation guide for all documentation
- **[QUICK_REFERENCE.md](kubernetes/docs/QUICK_REFERENCE.md)** - All commands for all platforms

### Windows-Specific
- **[WINDOWS_QUICK_START.md](kubernetes/docs/WINDOWS_QUICK_START.md)** ⭐ **START HERE**
  - 5-minute setup guide
  - Prerequisites checklist
  - Basic deployment

- **[WINDOWS_SETUP_GUIDE.md](kubernetes/docs/WINDOWS_SETUP_GUIDE.md)**
  - Complete installation guide
  - Docker Desktop setup
  - kubectl installation
  - Windows-specific troubleshooting

### Detailed Guides
- **[README.md](kubernetes/README.md)** - Complete deployment guide
- **[POSIX_SETUP_GUIDE.md](kubernetes/docs/POSIX_SETUP_GUIDE.md)** - Advanced configuration
- **[ARCHITECTURE.md](kubernetes/docs/ARCHITECTURE.md)** - Technical architecture

## 📂 What's Included

```
kubernetes/
├── 📋 Documentation (in docs/ subdirectory)
│   ├── INDEX.md                    ← Start here for navigation
│   ├── WINDOWS_QUICK_START.md     ← Windows 5-minute guide
│   ├── WINDOWS_SETUP_GUIDE.md       ← Windows detailed setup
│   └── ... (more guides)
│
├── 📄 README.md                    ← Main deployment guide
├── 🔧 Scripts (6 files)
│   └── scripts/
│       ├── deploy.ps1              ← Deploy (Windows)
│       ├── deploy.sh               ← Deploy (Linux/macOS)
│       ├── cleanup.ps1             ← Cleanup (Windows)
│       ├── cleanup.sh              ← Cleanup (Linux/macOS)
│       └── ... (more scripts)
│
└── 📦 Kubernetes Manifests
    ├── manifests/                  ← k8s resources
    ├── helm/                       ← Helm charts
    └── kustomization.yaml          ← Kustomize config (used with kubectl -k)
```

## 🎯 Choose Your Path

| I Want To... | Go To |
|--------------|-------|
| **Deploy in 5 minutes (Windows)** | [WINDOWS_QUICK_START.md](kubernetes/docs/WINDOWS_QUICK_START.md) |
| **Deploy in 5 minutes (Linux/Mac)** | [POSIX_QUICK_START.md](kubernetes/docs/POSIX_QUICK_START.md) |
| **Complete setup guide (Windows)** | [WINDOWS_SETUP_GUIDE.md](kubernetes/docs/WINDOWS_SETUP_GUIDE.md) |
| **Complete setup guide (Linux/Mac)** | [POSIX_SETUP_GUIDE.md](kubernetes/docs/POSIX_SETUP_GUIDE.md) |
| **All commands reference** | [QUICK_REFERENCE.md](kubernetes/docs/QUICK_REFERENCE.md) |
| **Technical architecture** | [ARCHITECTURE.md](kubernetes/docs/ARCHITECTURE.md) |
| **Advanced configuration** | [ADVANCED_CONFIGURATION.md](kubernetes/docs/ADVANCED_CONFIGURATION.md) |
| **Navigate all docs** | [INDEX.md](kubernetes/docs/INDEX.md) |

## ✨ Features

✅ **Cross-Platform**
- Windows PowerShell scripts
- Linux/macOS Bash scripts
- All platforms use same manifests

✅ **Complete Suite**
- MongoDB (data store)
- PostgreSQL (analytics)
- Apache Airflow (orchestration)

✅ **Production-Ready**
- RBAC security
- Network policies
- Persistent storage
- Health checks
- Resource limits

✅ **Well-Documented**
- 8 documentation files
- Platform-specific guides
- Troubleshooting sections
- Architecture details

## 🚦 Getting Started Checklist

### Prerequisites
- [ ] Windows 10/11 (Windows) OR macOS/Linux
- [ ] Docker Desktop installed and running
- [ ] kubectl installed and configured
- [ ] 4GB+ RAM available
- [ ] 50GB+ free disk space

### First Time
- [ ] Read platform-specific quick start guide
- [ ] Check prerequisites are installed
- [ ] Run deployment script
- [ ] Wait 3-5 minutes for pods to start
- [ ] Test access to services

### Verification
- [ ] All pods showing "Running"
- [ ] Services accessible via port forwarding
- [ ] Airflow UI loads in browser
- [ ] No errors in logs

## 🆘 Common Tasks

### View Pod Status
```bash
kubectl get pods -n trips-ticks
```

### View Logs
```bash
kubectl logs -n trips-ticks deployment/airflow-webserver --tail=50 -f
```

### Connect to Database
```bash
# MongoDB
kubectl exec -it mongodb-0 -n trips-ticks -- mongosh

# PostgreSQL
kubectl exec -it postgres-0 -n trips-ticks -- psql -U postgres
```

### Cleanup Everything
```powershell
# Windows
.\kubernetes\scripts\cleanup.ps1
```
```bash
# Linux/macOS
bash kubernetes/scripts/cleanup.sh
```

## 🔧 Troubleshooting

### Run Diagnostics
```powershell
# Windows - Interactive menu
.\kubernetes\scripts\troubleshoot.ps1

# Windows - All checks
.\kubernetes\scripts\troubleshoot.ps1 -Mode all
```

```bash
# Linux/macOS - Interactive menu
bash kubernetes/scripts/troubleshoot.sh

# Linux/macOS - All checks
bash kubernetes/scripts/troubleshoot.sh all
```

### Common Issues
1. **PowerShell Scripts Won't Run (Windows)**
   - See [WINDOWS_SETUP_GUIDE.md](kubernetes/docs/WINDOWS_SETUP_GUIDE.md) → PowerShell Scripts Won't Run

2. **kubectl Not Found**
   - See [WINDOWS_SETUP_GUIDE.md](kubernetes/docs/WINDOWS_SETUP_GUIDE.md) → kubectl Command Not Found
   - OR [README.md](kubernetes/README.md) → Prerequisites

3. **Pods Stuck in Pending**
   - Run troubleshooting script
   - Check node resources: `kubectl top nodes`
   - Review [ARCHITECTURE.md](kubernetes/ARCHITECTURE.md) → Resource Management

4. **Can't Access Services**
   - Verify port-forward is running
   - Check Windows Firewall if on Windows
   - See platform-specific troubleshooting guide

## 📱 Need Help?

1. **For Windows:** Start with [WINDOWS_QUICK_START.md](kubernetes/WINDOWS_QUICK_START.md)
2. **For Linux/macOS:** Start with [README.md](kubernetes/README.md)
3. **For Any Platform:** Check [INDEX.md](kubernetes/INDEX.md) for complete navigation
4. **For Specific Commands:** See [QUICK_REFERENCE.md](kubernetes/QUICK_REFERENCE.md)

## 🔗 Documentation Map

```
Start Here
    ├─ Windows User?
    │   ├─ Quick start? → WINDOWS_QUICK_START.md
    │   └─ Full setup? → WINDOWS_SETUP_GUIDE.md
    │
    ├─ Linux/macOS User?
    │   ├─ Quick start? → README.md
    │   └─ Full setup? → SETUP_GUIDE.md
    │
    └─ Need Navigation?
        └─ INDEX.md
```

## 📊 Architecture Overview

```
┌─────────────────────────────────────┐
│    Kubernetes Cluster               │
│   (trips-ticks namespace)           │
├─────────────────────────────────────┤
│  ┌─────────┐  ┌──────────┐        │
│  │ MongoDB │  │PostgreSQL│        │
│  │   10GB  │  │   20GB   │        │
│  └─────────┘  └──────────┘        │
│                                    │
│  ┌─────────────────────────────┐  │
│  │   Apache Airflow            │  │
│  │  ├─ Webserver (UI)          │  │
│  │  └─ Scheduler (Orchestrate) │  │
│  └─────────────────────────────┘  │
│                                    │
└─────────────────────────────────────┘
```

## 📈 Next Steps

### After Successful Deployment

1. **Access Airflow UI**
   ```
   http://localhost:8080
   ```

2. **Explore Sample DAGs**
   - Trips processing workflow
   - Analytics pipeline
   - Data cleanup tasks

3. **Configure Connections**
   - MongoDB connection
   - PostgreSQL connection
   - Custom APIs

4. **Deploy Custom DAGs**
   - Create your workflows
   - Upload to shared volume
   - Monitor execution

5. **Set Up Monitoring** (Optional)
   - Prometheus metrics
   - Grafana dashboards
   - Alert rules

## 🎯 Key Directories

| Directory | Purpose |
|-----------|---------|
| `scripts/` | Deployment scripts (both platforms) |
| `manifests/` | Kubernetes resource definitions |
| `helm/` | Helm chart configuration |
| Root | Documentation and guides |

## 📞 Support Resources

- **Kubernetes Docs:** https://kubernetes.io/docs/
- **Apache Airflow:** https://airflow.apache.org/docs/
- **MongoDB:** https://docs.mongodb.com/
- **PostgreSQL:** https://www.postgresql.org/docs/
- **Docker:** https://docs.docker.com/

## 🎉 Ready to Deploy?

### Windows
```powershell
.\kubernetes\scripts\deploy.ps1
```

### Linux/macOS
```bash
bash kubernetes/scripts/deploy.sh
```

---


**Last updated:** April 27, 2026

**Questions?** See [INDEX.md](kubernetes/INDEX.md) for complete navigation.
