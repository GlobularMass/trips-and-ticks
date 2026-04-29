# Windows Quick Start Guide

Getting Trips and Ticks up and running on Windows in 5 minutes.

## Prerequisites Checklist

- [ ] Windows 10 or later
- [ ] PowerShell (already installed)
- [ ] Docker Desktop installed
- [ ] Kubernetes enabled in Docker Desktop

## Setup (One-Time)

### 1. Install Docker Desktop (5 min)
```
Download: https://www.docker.com/products/docker-desktop
Install and let it restart
During setup, enable Kubernetes ✓
```

### 2. Install kubectl (2 min)
```
Download: https://kubernetes.io/docs/tasks/tools/#kubectl
Extract to folder
Add to PATH (instructions in WINDOWS_SETUP_GUIDE.md)
Restart PowerShell
```

**Verify:**
```powershell
kubectl version --client
kubectl cluster-info
```

## Deployment (2 min)

### Open PowerShell as Administrator

```powershell
cd C:\Users\YourUsername\Documents\Development\trips-and-ticks
.\kubernetes\scripts\deploy.ps1
```

**Wait 3-5 minutes for services to start**

## Access Services

### Airflow WebUI (Browser)

**Open new PowerShell:**
```powershell
kubectl port-forward -n trips-ticks svc/airflow-webserver 8080:8080
```

**Then visit:** http://localhost:8080

### MongoDB (Connection)

**Open new PowerShell:**
```powershell
kubectl port-forward -n trips-ticks svc/mongodb 27017:27017
```

**Connection string:**
```
mongodb://admin:change-me-in-production@localhost:27017/admin?authSource=admin
```

### PostgreSQL (Connection)

**Open new PowerShell:**
```powershell
kubectl port-forward -n trips-ticks svc/postgres-service 5432:5432
```

**Connection string:**
```
postgresql://postgres:change-me-in-production@localhost:5432/trips_ticks_analytics
```

## Check Everything Works

```powershell
# View all pods
kubectl get pods -n trips-ticks

# Should show - all with "Running" status:
# - mongodb-0
# - postgres-0
# - airflow-webserver-xxx
# - airflow-scheduler-xxx
```

## Cleanup (Optional)

```powershell
.\kubernetes\scripts\cleanup.ps1
```

## Troubleshooting

### "PowerShell scripts are disabled"
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "kubectl: command not found"
- Restart PowerShell after installing kubectl
- Or use full path: `C:\path\to\kubectl version`

### Pods stuck in "Pending"
```powershell
# Check what's wrong
kubectl describe pod <pod-name> -n trips-ticks

# Run diagnostics
.\kubernetes\scripts\troubleshoot.ps1
```

### Can't access http://localhost:8080
- Check port-forward is running (terminal should show ongoing process)
- Try: `curl localhost:8080` in PowerShell
- If blocked, check Windows Firewall

## More Help

- Full Windows setup: [WINDOWS_SETUP_GUIDE.md](WINDOWS_SETUP_GUIDE.md)
- All commands: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- Technical details: [README.md](../README.md)

## Pro Tips

1. **Use multiple PowerShell windows** for port forwarding
   - One for Airflow
   - One for MongoDB
   - One for PostgreSQL

2. **Keep things running**
   - Port-forward windows must stay open
   - Close with `Ctrl + C` when done

3. **View logs anytime**
   ```powershell
   kubectl logs -n trips-ticks deployment/airflow-webserver --tail=50 -f
   kubectl logs -n trips-ticks statefulset/mongodb --tail=50 -f
   ```

4. **Windows Terminal**
   - Better than PowerShell ISE
   - Multiple tabs/panes
   - Install from Microsoft Store

## What's Running

```
Kubernetes Namespace: trips-ticks
├── MongoDB (database for trip data)
├── PostgreSQL (database for analytics)
└── Apache Airflow
    ├── Webserver (UI: http://localhost:8080)
    └── Scheduler (runs workflows)
```

## Next Steps

1. Access the Airflow UI
2. Check out the sample workflows
3. Read the main [README.md](../README.md)
4. Explore [ARCHITECTURE.md](ARCHITECTURE.md) for technical details

---

**Stuck?** 
- Run: `.\kubernetes\scripts\troubleshoot.ps1`
- Check [WINDOWS_SETUP_GUIDE.md](WINDOWS_SETUP_GUIDE.md) troubleshooting section
- See QUICK_REFERENCE.md for all commands

**Happy deploying!** 🎉
