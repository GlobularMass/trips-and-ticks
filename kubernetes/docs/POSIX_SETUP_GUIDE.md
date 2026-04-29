# Linux/macOS Setup Guide

This document provides setup instructions specific to Linux and macOS environments for the Trips and Ticks Kubernetes deployment.

For cross-platform advanced configuration topics (customizing deployments, production hardening, backup/recovery), see [ADVANCED_CONFIGURATION.md](ADVANCED_CONFIGURATION.md).
For Windows-specific setup, see [WINDOWS_SETUP_GUIDE.md](WINDOWS_SETUP_GUIDE.md).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Steps](#installation-steps)
3. [Cluster Verification](#cluster-verification)
4. [Troubleshooting on Linux/macOS](#troubleshooting-on-linux-macos)

**For Advanced Topics:** See [ADVANCED_CONFIGURATION.md](ADVANCED_CONFIGURATION.md)
- Customizing deployments
- Post-deployment configuration
- Production hardening
- Backup and recovery

## Pre-Deployment Checklist

Before deploying, ensure you have:

- [ ] Kubernetes cluster running (1.20+)
- [ ] kubectl configured and authenticated
- [ ] Sufficient cluster resources (4GB RAM minimum, 50GB storage recommended)
- [ ] RBAC enabled in cluster
- [ ] Network policies supported (optional but recommended)
- [ ] Persistent storage configured or available
- [ ] DNS working properly in cluster
- [ ] Access to container registries (if using private images)

### Verify Cluster Status

```bash
# Check cluster info
kubectl cluster-info

# Check node status
kubectl get nodes

# Check storage classes
kubectl get storageclass

# Check API extensions
kubectl api-resources | grep -E "ingress|networkpolicy|storageclasses"
```

## Cluster Preparation

### 1. Create Storage Directories (Local Storage)

If using local persistent volumes (Minikube or local cluster):

```bash
# SSH into cluster node
minikube ssh  # or ssh into your node

# Create storage directories
sudo mkdir -p /var/data/{mongodb,postgres,airflow/{dags,logs}}
sudo chown -R 1000:1000 /var/data
sudo chmod -R 755 /var/data

# Verify directories
ls -la /var/data/
```

### 2. Create Storage Class

```bash
# For local storage (development/testing)
kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

# For cloud providers (recommended for production)
# AWS EBS
cat <<'EOF' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
allowVolumeExpansion: true
EOF

# GCP PD
cat <<'EOF' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: pd-standard
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-standard
allowVolumeExpansion: true
EOF

# Azure Disk
cat <<'EOF' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-csi
provisioner: disk.csi.azure.com
EOF
```

### 3. Configure RBAC

The deployment includes RBAC configuration. To verify:

```bash
# Check if RBAC is enabled
kubectl api-versions | grep rbac

# Check ClusterRole for Airflow
kubectl get clusterrole | grep airflow
```

### 4. Prepare Container Registries (if needed)

For private registries:

```bash
# Create image pull secret
kubectl create secret docker-registry regcred \
  --docker-server=<registry-url> \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  -n trips-ticks

# Add to ServiceAccount
kubectl patch serviceaccount default \
  -p '{"imagePullSecrets": [{"name": "regcred"}]}' \
  -n trips-ticks
```


## Troubleshooting on Linux/macOS

### Common Issues

**kubectl: command not found**
- Verify installation: `which kubectl`
- Add to PATH if needed
- Check the installation steps above

**Permission denied when accessing docker socket**
- Add your user to docker group: `sudo usermod -aG docker $USER`
- Log out and log back in for changes to take effect

**Minikube not starting**
- Check Docker is running
- Check available system resources
- Try `minikube delete` and restart

**Cannot connect to Kubernetes cluster**
- Verify cluster is running
- Check kubeconfig: `kubectl config current-context`
- Verify credentials: `kubectl auth can-i get pods`

## Next Steps

For advanced configuration topics (customizing deployments, production hardening, backup/recovery procedures), refer to:

**→ [ADVANCED_CONFIGURATION.md](ADVANCED_CONFIGURATION.md)**

---

For more information, see the main [README.md](../README.md).
