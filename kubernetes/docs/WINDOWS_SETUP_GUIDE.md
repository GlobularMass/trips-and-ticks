# Windows Installation & Setup Guide

This guide provides step-by-step instructions for setting up and deploying Trips and Ticks on Windows using PowerShell.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Steps](#installation-steps)
3. [Using PowerShell Scripts](#using-powershell-scripts)
4. [Windows-Specific Considerations](#windows-specific-considerations)
5. [Troubleshooting on Windows](#troubleshooting-on-windows)
6. [Quick Start Commands](#quick-start-commands)

## Prerequisites

### Software Requirements

Before you begin, ensure you have the following installed on your Windows machine:

1. **PowerShell 5.1 or Later**
   - Check your version: Open PowerShell and run `$PSVersionTable.PSVersion`
   - Windows 10/11 comes with PowerShell 5.1 by default
   - For PowerShell 7+: Download from https://github.com/PowerShell/PowerShell

2. **Kubernetes (kubectl)**
   - Download: https://kubernetes.io/docs/tasks/tools/#kubectl
   - After installation, verify: `kubectl version --client`

3. **Docker Desktop (for local Kubernetes)**
   - Download: https://www.docker.com/products/docker-desktop
   - During installation, **enable Kubernetes**
   - After installation, verify: `kubectl cluster-info`

4. **Kustomize (Built-in with kubectl)**
   - No separate installation needed - kubectl includes kustomize functionality

5. **Git (Recommended)**
   - Download: https://git-scm.com/download/win
   - For cloning the repository

### Hardware Requirements

- **Minimum:** 4GB RAM, 30GB free disk space
- **Recommended:** 8GB RAM, 50GB free disk space
- **Production:** 16GB+ RAM, 100GB+ disk space

## Installation Steps

### Step 1: Install Docker Desktop

1. Download Docker Desktop from https://www.docker.com/products/docker-desktop
2. Run the installer and follow the setup wizard
3. During installation, **make sure to enable Kubernetes**
4. Restart your computer when prompted
5. Verify installation:
   ```powershell
   docker version
   kubectl cluster-info
   ```

### Step 2: Install kubectl

1. Download the latest kubectl release from:
   https://kubernetes.io/docs/tasks/tools/#kubectl

2. Extract the executable to a folder
3. Add the folder to your Windows PATH:
   - Press `Win + X` → System
   - Click "Advanced system settings"
   - Click "Environment Variables"
   - Under "User variables", click "New"
   - Variable name: `PATH`
   - Variable value: Path to your kubectl folder
   - Click OK and restart PowerShell

4. Verify installation:
   ```powershell
   kubectl version --client
   kubectl cluster-info
   ```

### Step 3: Prepare Your Project

Navigate to your project directory in PowerShell:

```powershell
cd C:\Users\YourUsername\Documents\Development\trips-and-ticks
```

### Step 5: Configure Execution Policy (If Needed)

PowerShell may prevent running scripts. Set the execution policy:

```powershell
# Check current policy
Get-ExecutionPolicy

# Set to allow scripts (current user only)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or for a single session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Step 4: Generate Environment Configuration

Generate secure credentials for your deployment:

```powershell
# Navigate to kubernetes directory
cd C:\Users\YourUsername\Documents\Development\trips-and-ticks\kubernetes

# Generate .env file with secure random credentials
.\scripts\generate-env.ps1

# Review the generated credentials
Get-Content .env
```

**Security Note:** The `.env` file contains sensitive information. **DO NOT commit it to version control!**

## Using PowerShell Scripts

### Running the Deployment Script

```powershell
# Navigate to project directory
cd C:\Users\YourUsername\Documents\Development\trips-and-ticks

# Run deployment with default settings (uses kubectl kustomize)
.\kubernetes\scripts\deploy.ps1

# Run deployment with manifest files
.\kubernetes\scripts\deploy.ps1 -DeploymentMethod manifests

# Run deployment and set up port forwarding
.\kubernetes\scripts\deploy.ps1 -PortForward
```

### Running the Cleanup Script

```powershell
# Remove all resources with confirmation prompt
.\kubernetes\scripts\cleanup.ps1

# Force remove without confirmation
.\kubernetes\scripts\cleanup.ps1 -Force
```

### Running the Troubleshooting Script

```powershell
# Interactive menu mode (default)
.\kubernetes\scripts\troubleshoot.ps1

# Run all checks
.\kubernetes\scripts\troubleshoot.ps1 -Mode all

# Generate diagnostic report
.\kubernetes\scripts\troubleshoot.ps1 -Mode report
```

## Windows-Specific Considerations

### 1. Line Endings

Windows uses CRLF (`\r\n`) line endings while Linux uses LF (`\n`). When working with YAML files:

```powershell
# PowerShell will handle this automatically, but if you need to convert:
# Use notepad++ or Visual Studio Code with settings:
# "files.eol": "\n"
```

### 2. Path Separators

PowerShell accepts both `/` and `\` in paths:

```powershell
# Both are valid:
.\kubernetes\scripts\deploy.ps1
.\kubernetes/scripts/deploy.ps1
```

### 3. Environment Variables

Setting environment variables in PowerShell for this session:

```powershell
# Set variable
$env:KUBECONFIG = "C:\path\to\config"

# View variable
$env:KUBECONFIG

# Temporary path modification
$env:PATH += ";C:\path\to\kubectl"
```

Permanent environment variables:
- Right-click "This PC" → "Properties"
- Click "Advanced system settings"
- Click "Environment Variables"
- Add your variables under "User variables"

### 4. Copy/Paste in PowerShell

Paste multi-line content:
- Right-click to paste
- Or use `Shift + Insert`
- Or use `Ctrl + Shift + V` (Windows Terminal)

### 5. Port Forwarding

PowerShell will block until port forwarding is running. To run it in the background:

```powershell
# Start port forwarding in new window
Start-Process powershell -ArgumentList "kubectl port-forward -n trips-ticks svc/airflow-webserver 8080:8080"

# Or run in separate terminal tab
# Ctrl+Shift+T in Windows Terminal creates new tab
```

### 6. Running Commands as Administrator

If you encounter permission errors:

1. Right-click PowerShell → "Run as administrator"
2. Or use Docker Desktop's Kubernetes, which typically doesn't need elevated privileges

### 7. Timeout Issues

Windows may have different timeout defaults. If deployments are slow:

```powershell
# PowerShell equivalent of Linux timeout
$timeout = (Get-Date).AddSeconds(300)
while ((Get-Date) -lt $timeout) {
    kubectl get pods -n trips-ticks
    Start-Sleep -Seconds 5
}
```

## Troubleshooting on Windows

### PowerShell Scripts Won't Run

**Problem:** "cannot be loaded because running scripts is disabled"

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### kubectl Command Not Found

**Problem:** PowerShell doesn't recognize `kubectl` command

**Solutions:**
1. Restart PowerShell after installation
2. Add kubectl to PATH and restart
3. Use full path: `C:\path\to\kubectl.exe version`

Check where kubectl is installed:
```powershell
where.exe kubectl
Get-Command kubectl
```

### Docker Desktop Not Starting Kubernetes

**Problem:** Kubernetes cluster not available in Docker Desktop

**Solutions:**
1. Reinstall Docker Desktop with Kubernetes enabled
2. Check Docker Desktop settings:
   - Right-click Docker icon → Settings
   - Navigate to Kubernetes tab
   - Ensure "Enable Kubernetes" is checked

### Port Forwarding Not Working

**Problem:** Can't access services locally despite port forwarding

**Solutions:**
```powershell
# Kill existing port-forward processes
Get-Process | Where-Object { $_.ProcessName -like "*kubectl*" } | Stop-Process -Force

# Restart port forwarding
kubectl port-forward -n trips-ticks svc/airflow-webserver 8080:8080

# Verify port is listening
netstat -ano | findstr ":8080"
```

### Firewall Issues

Windows Firewall may block Docker or Kubernetes:

1. Open Windows Defender Firewall → Advanced Settings
2. Click "Inbound Rules" → "New Rule"
3. Select "Port" and click "Next"
4. Select "TCP" and enter port (e.g., 8080)
5. Allow the connection through

### Storage Issues on Windows

Windows Docker Desktop stores data in:
```
C:\Users\YourUsername\AppData\Local\Docker\wsl2-data
```

If running low on space:
1. Clean up Docker: `docker system prune -a`
2. Expand Docker disk space in Docker Desktop settings
3. Consider using WSL2 backend (already default in recent versions)

### Performance on Windows

Docker Desktop on Windows using WSL2 should perform well, but:

1. WSL2 may use significant disk space (~100GB virtual)
2. First-time setup is slower
3. Large dataset operations may be slower than native Linux

To improve performance:
```powershell
# Enable WSL2 integration in Docker Desktop settings
# Use local path for volumes instead of mounted directories
# Keep Docker components updated
```

## Quick Start Commands

### Complete Deployment (One Command)

```powershell
cd C:\Users\YourUsername\Documents\Development\trips-and-ticks
.\kubernetes\scripts\deploy.ps1
```

### Access Services

```powershell
# Port forward Airflow (keep terminal open)
kubectl port-forward -n trips-ticks svc/airflow-webserver 8080:8080
# Then visit http://localhost:8080

# In another terminal, port forward MongoDB
kubectl port-forward -n trips-ticks svc/mongodb 27017:27017

# In another terminal, port forward PostgreSQL
kubectl port-forward -n trips-ticks svc/postgres-service 5432:5432
```

### Check Status

```powershell
# View all pods
kubectl get pods -n trips-ticks

# View all services
kubectl get svc -n trips-ticks

# View detailed pod status
kubectl describe pods -n trips-ticks
```

### View Logs

```powershell
# Airflow webserver logs
kubectl logs -n trips-ticks deployment/airflow-webserver --tail=50 -f

# MongoDB logs
kubectl logs -n trips-ticks statefulset/mongodb --tail=50 -f

# PostgreSQL logs
kubectl logs -n trips-ticks statefulset/postgres --tail=50 -f
```

### Connect to Databases

```powershell
# MongoDB shell
kubectl exec -it mongodb-0 -n trips-ticks -- mongosh

# PostgreSQL shell
kubectl exec -it postgres-0 -n trips-ticks -- psql -U postgres
```

### Cleanup

```powershell
.\kubernetes\scripts\cleanup.ps1
```

### Troubleshoot

```powershell
# Interactive mode
.\kubernetes\scripts\troubleshoot.ps1

# Run all checks at once
.\kubernetes\scripts\troubleshoot.ps1 -Mode all

# Generate report
.\kubernetes\scripts\troubleshoot.ps1 -Mode report
```

## Using Windows Terminal

Windows Terminal provides a better PowerShell experience:

1. Install from Microsoft Store: https://www.microsoft.com/store/apps/9N0DX20HK701
2. Set PowerShell as default profile in settings
3. Benefits:
   - Better rendering
   - Multiple tabs
   - Customizable appearance
   - Pane splitting

## Troubleshooting Commands Reference

```powershell
# Check Kubernetes cluster
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check all namespaces
kubectl get namespaces

# Check resources in namespace
kubectl get all -n trips-ticks

# Check specific resource type
kubectl get pods -n trips-ticks
kubectl get svc -n trips-ticks
kubectl get pvc -n trips-ticks

# Get detailed information
kubectl describe pod <pod-name> -n trips-ticks

# View pod logs
kubectl logs <pod-name> -n trips-ticks

# Execute command in pod
kubectl exec -it <pod-name> -n trips-ticks -- bash

# Port forward service
kubectl port-forward -n trips-ticks svc/<service-name> <local-port>:<remote-port>

# Watch resources in real-time
kubectl get pods -n trips-ticks --watch

# Delete resources
kubectl delete pod <pod-name> -n trips-ticks
kubectl delete namespace trips-ticks
```

## Next Steps

1. Run the deployment script
2. Wait for all pods to be running (3-5 minutes)
3. Access services via port forwarding
4. Check logs if there are any issues
5. Run troubleshooting script if needed
6. See [README.md](../README.md) for more information

For more detailed information, see:
- [README.md](../README.md) - Main deployment guide
- [POSIX_SETUP_GUIDE.md](POSIX_SETUP_GUIDE.md) - Detailed configuration
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical architecture
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Command reference
