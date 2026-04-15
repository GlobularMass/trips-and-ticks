# Kubernetes Overview

> A developer's guide to understanding Kubernetes, how it compares to Docker, cost structures, local development setup, and security considerations.

---

## Table of Contents

1. [What is Kubernetes?](#what-is-kubernetes)
2. [Kubernetes vs. Docker](#kubernetes-vs-docker)
3. [Core Concepts](#core-concepts)
4. [Cost Structure](#cost-structure)
5. [Free Local Development Options](#free-local-development-options)
6. [Setting Up a Local Development Instance](#setting-up-a-local-development-instance)
7. [Security & Privacy Considerations](#security--privacy-considerations)
8. [Additional Resources](#additional-resources)

---

## What is Kubernetes?

Kubernetes (often abbreviated **K8s**) is an open-source container orchestration platform originally developed by Google and now maintained by the Cloud Native Computing Foundation (CNCF). It automates the deployment, scaling, and management of containerized applications across clusters of machines.

Where Docker packages and runs individual containers, Kubernetes answers the question: *"How do I run and manage hundreds or thousands of containers reliably in production?"*

**Key capabilities:**

- Automated rollouts and rollbacks
- Self-healing (restarts failed containers, replaces unresponsive nodes)
- Horizontal scaling (scale up/down based on load)
- Service discovery and load balancing
- Secret and configuration management
- Storage orchestration

---

## Kubernetes vs. Docker

These tools are complementary, not competitive. Docker is typically used *inside* a Kubernetes cluster.

| Feature | Docker (standalone) | Kubernetes |
|---|---|---|
| **Primary purpose** | Build & run individual containers | Orchestrate many containers across many machines |
| **Scope** | Single host | Multi-node cluster |
| **Scaling** | Manual (`docker run` again) | Automatic horizontal scaling |
| **Self-healing** | None (containers stay down if they crash) | Restarts failed containers automatically |
| **Load balancing** | Manual / external | Built-in Service abstraction |
| **Networking** | Simple bridge networking | Sophisticated overlay networking (CNI plugins) |
| **Storage** | Docker volumes (local) | Persistent Volumes across cloud/on-prem storage |
| **Configuration management** | `.env` files, Compose overrides | ConfigMaps & Secrets (with RBAC) |
| **Learning curve** | Low–Medium | Medium–High |
| **Best for** | Local dev, single-server deployments | Production workloads, microservices at scale |

### How they work together

A typical workflow looks like this:

```
Developer writes code
       ↓
Docker builds a container image
       ↓
Image is pushed to a container registry (Docker Hub, ECR, GCR, etc.)
       ↓
Kubernetes pulls the image and runs it across the cluster
       ↓
Kubernetes manages scaling, restarts, and routing
```

Docker Compose is often used for local multi-container development, while Kubernetes handles the equivalent workload in staging and production.

---

## Core Concepts

Understanding these terms is essential before working with Kubernetes.

### Cluster
A set of machines (nodes) that Kubernetes manages. Every cluster has at least one **control plane** (master) node and one or more **worker** nodes.

### Pod
The smallest deployable unit. A pod wraps one or more containers that share network and storage. Pods are ephemeral — they are created and destroyed frequently.

### Deployment
A higher-level object that manages a set of identical Pods. You declare *desired state* (e.g., "run 3 replicas of my API"), and Kubernetes reconciles actual state to match.

### Service
An abstraction that exposes a set of Pods as a stable network endpoint. Handles load balancing and DNS resolution within the cluster.

### Namespace
A virtual partition within a cluster, used to isolate resources between teams, environments (dev/staging/prod), or projects.

### ConfigMap & Secret
Objects for injecting configuration and sensitive values (passwords, API keys) into Pods without baking them into container images.

### Ingress
Manages external HTTP/HTTPS access to services within a cluster, including TLS termination and path-based routing.

### Helm
A package manager for Kubernetes. Helm **Charts** are pre-packaged Kubernetes applications that can be installed and configured with a single command.

---

## Cost Structure

Kubernetes itself is **free and open-source**. Costs arise from the infrastructure you run it on and the managed services you choose.

### Self-Managed (On-Premises or DIY Cloud)

You provision and maintain your own VMs or bare-metal servers.

- **Software cost:** $0
- **Infrastructure cost:** Depends entirely on your VM/hardware choices
- **Operational cost:** Significant engineering time for setup, upgrades, and maintenance
- **Best for:** Organizations with existing infrastructure and Kubernetes expertise

### Managed Kubernetes Services (Cloud Providers)

Cloud providers handle the control plane for you. You pay for worker nodes and optionally for the control plane.

| Provider | Service | Control Plane Cost | Notes |
|---|---|---|---|
| Google Cloud | GKE (Google Kubernetes Engine) | Free (1 Autopilot cluster free) | Mature, excellent tooling |
| AWS | EKS (Elastic Kubernetes Service) | ~$0.10/hour per cluster (~$73/month) | Most popular for AWS shops |
| Microsoft Azure | AKS (Azure Kubernetes Service) | Free | Good Azure integration |
| DigitalOcean | DOKS | $12/month per cluster | Simple, affordable for smaller teams |
| Linode/Akamai | LKE | Free control plane | Budget-friendly option |

> **Note:** Worker node costs (the VMs that actually run your workloads) are charged on top of any control plane fees and typically represent the majority of your bill. Budget at minimum $30–100+/month for a small 2–3 node cluster.

### Additional Cost Factors

- **Storage:** Persistent volumes, object storage for logs and backups
- **Networking:** Load balancers ($10–20+/month each on most clouds), egress bandwidth
- **Registry:** Container image storage (Docker Hub free tier, or cloud registries)
- **Monitoring:** Prometheus/Grafana (self-hosted, free) vs. managed observability tools
- **Support:** Enterprise support contracts from vendors (e.g., Red Hat OpenShift)

---

## Free Local Development Options

All of the following are free and allow you to run a fully functional Kubernetes cluster on your laptop.

### 1. minikube *(Recommended for Beginners)*

The official Kubernetes local development tool. Runs a single-node cluster in a VM, container, or on bare metal.

- **Platforms:** macOS, Linux, Windows
- **Drivers:** Docker, VirtualBox, Hyper-V, KVM, and more
- **Pros:** Official, well-documented, supports most Kubernetes features, addons system
- **Cons:** Can be resource-heavy; single-node only
- **URL:** https://minikube.sigs.k8s.io

### 2. kind (Kubernetes IN Docker)

Runs Kubernetes nodes as Docker containers. Excellent for CI pipelines and multi-node testing.

- **Platforms:** macOS, Linux, Windows (WSL2)
- **Pros:** Very fast startup, supports multi-node clusters, lightweight
- **Cons:** Requires Docker; networking can feel less realistic
- **URL:** https://kind.sigs.k8s.io

### 3. k3d

A lightweight wrapper that runs **k3s** (a minimal Kubernetes distribution) inside Docker containers.

- **Platforms:** macOS, Linux, Windows (WSL2)
- **Pros:** Extremely fast; k3s is production-grade and used on edge/IoT devices; low memory footprint
- **Cons:** k3s removes some non-essential components (e.g., default storage class differs)
- **URL:** https://k3d.io

### 4. Docker Desktop (Built-in Kubernetes)

Docker Desktop for Mac and Windows includes a built-in single-node Kubernetes cluster you can enable with a checkbox.

- **Platforms:** macOS, Windows
- **Pros:** Zero additional install; integrates with Docker workflows seamlessly
- **Cons:** Docker Desktop requires a paid license for companies over 250 employees or $10M revenue; single-node only
- **URL:** https://www.docker.com/products/docker-desktop

### 5. Rancher Desktop

An open-source alternative to Docker Desktop. Includes container management and a built-in k3s Kubernetes cluster.

- **Platforms:** macOS, Linux, Windows
- **Pros:** Fully free and open-source; supports both containerd and dockerd runtimes
- **Cons:** Newer, less mature than Docker Desktop
- **URL:** https://rancherdesktop.io

---

## Setting Up a Local Development Instance

The following guide walks through setting up a local cluster using **minikube**, the most common starting point.

### Prerequisites

- A machine with at least 2 CPUs, 4 GB RAM (8 GB recommended), and 20 GB disk space
- Docker installed and running (recommended driver)
- `kubectl` installed (the Kubernetes CLI)

### Step 1: Install kubectl

```bash
# macOS (Homebrew)
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify installation
kubectl version --client
```

**Windows** — `winget` (Windows Package Manager) is built into Windows 10 (version 1809+) and Windows 11. Open **PowerShell** or **Command Prompt** and run:

```powershell
winget install -e --id Kubernetes.kubectl
```

After installation, restart your terminal and verify:

```powershell
kubectl version --client
```

> **If `winget` is unavailable** (older Windows 10 builds): Download the kubectl binary directly from https://dl.k8s.io/release/v1.30.0/bin/windows/amd64/kubectl.exe, place it in a folder of your choice (e.g., `C:\kubectl\`), and [add that folder to your PATH](https://learn.microsoft.com/en-us/previous-versions/office/developer/sharepoint-2010/ee537574(v=office.14)).

### Step 2: Install minikube

```bash
# macOS (Homebrew)
brew install minikube

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verify installation
minikube version
```

**Windows** — Using `winget` (built into Windows 10 1809+ and Windows 11):

```powershell
winget install -e --id Kubernetes.minikube
```

Restart your terminal, then verify:

```powershell
minikube version
```

> **If `winget` is unavailable:** Download the minikube installer directly from https://storage.googleapis.com/minikube/releases/latest/minikube-installer.exe and run it. The installer adds minikube to your PATH automatically.

### Step 3: Start Your Cluster

```bash
# Start with Docker driver (recommended)
minikube start --driver=docker

# Start with more resources (adjust to your machine)
minikube start --driver=docker --cpus=4 --memory=8192

# Verify the cluster is running
kubectl get nodes
# Expected output:
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   30s   v1.xx.x
```

### Step 4: Deploy a Sample Application

```bash
# Create a simple deployment
kubectl create deployment hello-world --image=nginx

# Expose it as a service
kubectl expose deployment hello-world --type=NodePort --port=80

# Open it in your browser
minikube service hello-world

# Check what's running
kubectl get pods
kubectl get services
```

### Step 5: Explore the Dashboard (Optional)

```bash
# Enable and open the Kubernetes dashboard
minikube addons enable dashboard
minikube dashboard
```

### Step 6: Clean Up

```bash
# Delete specific resources
kubectl delete service hello-world
kubectl delete deployment hello-world

# Stop the cluster (preserves state)
minikube stop

# Delete the cluster entirely
minikube delete
```

### Working with YAML Manifests

In real projects, you'll define resources as YAML files rather than using imperative `kubectl create` commands.

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

```bash
# Start minikube
minikube start --driver=docker

# Apply the manifest
kubectl apply -f kubernetes-overview/deployment.yaml

# View the result
kubectl get deployments
kubectl describe deployment my-app
```

---

## Security & Privacy Considerations

Kubernetes is powerful, but its default configuration prioritizes ease of use over security. The following areas require deliberate attention.

### Authentication & Authorization

- **Enable RBAC (Role-Based Access Control):** RBAC is enabled by default in modern clusters but must be configured properly. Grant the minimum permissions necessary — never use `cluster-admin` for application service accounts.
- **Avoid anonymous access:** Ensure the API server does not allow unauthenticated requests (`--anonymous-auth=false`).
- **Use short-lived credentials:** Prefer OIDC tokens or service account tokens with expiry over static credentials.
- **Audit API server access:** Enable audit logging to track who is calling the Kubernetes API and what they are doing.

### Secrets Management

- Kubernetes Secrets are **base64-encoded, not encrypted by default**. Anyone with read access to the namespace can decode them.
- **Enable encryption at rest** for etcd (the cluster's data store) using `EncryptionConfiguration`.
- For production, consider external secret managers: **HashiCorp Vault**, **AWS Secrets Manager**, **Azure Key Vault**, or **GCP Secret Manager** — integrated via operators like the External Secrets Operator.
- Never commit Secrets to source control, even in base64 form.

### Network Security

- **Apply NetworkPolicies:** By default, all pods can communicate with all other pods. Use NetworkPolicy resources to restrict traffic between namespaces and services.
- **Use TLS everywhere:** Encrypt traffic between services using mutual TLS (mTLS). Service meshes like **Istio** or **Linkerd** can automate this.
- **Restrict Ingress exposure:** Only expose services to the internet that need to be. Use Ingress controllers with TLS termination.
- **Disable the Kubernetes dashboard in production** or protect it with strong authentication — it has been exploited in the wild.

### Container & Pod Security

- **Run containers as non-root:** Set `runAsNonRoot: true` and a specific `runAsUser` in your pod's security context.
- **Use read-only root filesystems:** Set `readOnlyRootFilesystem: true` where possible.
- **Drop Linux capabilities:** Drop `ALL` capabilities and add back only what is needed.
- **Avoid `privileged: true`:** Privileged containers have full access to the host kernel. Avoid unless absolutely required.
- **Use Pod Security Admission (PSA):** Kubernetes 1.25+ replaces the deprecated PodSecurityPolicy with built-in admission control enforcing `Baseline` or `Restricted` pod security standards.

```yaml
# Example: Hardened security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
```

### Image Security

- **Use minimal base images:** Alpine or distroless images reduce attack surface.
- **Scan images for vulnerabilities:** Use tools like **Trivy**, **Snyk**, or **Grype** in your CI pipeline.
- **Pin image tags:** Avoid `latest` — use specific digest-pinned tags (e.g., `nginx@sha256:abc123...`) for reproducible, tamper-evident deployments.
- **Use a private registry:** Avoid pulling untrusted images from public registries in production.

### etcd Security

etcd stores all cluster state, including Secrets. Treat it as your most sensitive component.

- Restrict access to etcd to the control plane only.
- Enable TLS for all etcd communication.
- Enable encryption at rest for etcd data.
- Back up etcd regularly and store backups securely.

### Supply Chain Security

- **Sign images with Cosign** (part of the Sigstore project) and verify signatures at admission time using **Policy Controller** or **Kyverno**.
- **Use Software Bill of Materials (SBOMs)** to track what dependencies are in your container images.
- **Audit Helm charts** before deploying community charts — they may request excessive permissions.

### Local Development Considerations

Even for local clusters, good habits matter:

- Do not store real credentials or production data in local development clusters.
- Be cautious when applying manifests downloaded from the internet — review them before running `kubectl apply`.
- minikube/kind clusters are not isolated from your host network — be aware of ports that get exposed.
- Rotate any kubeconfig credentials before sharing your machine or committing config files to version control.

### Security Hardening Checklist

- [ ] RBAC enabled and least-privilege roles defined
- [ ] Secrets encrypted at rest
- [ ] External secrets manager integrated (production)
- [ ] NetworkPolicies applied to all namespaces
- [ ] TLS on all Ingress endpoints
- [ ] Pod security contexts configured (non-root, read-only FS)
- [ ] Image vulnerability scanning in CI pipeline
- [ ] Image tags pinned (no `latest`)
- [ ] etcd access restricted and encrypted
- [ ] Audit logging enabled
- [ ] Kubernetes version kept up to date

---

## Additional Resources

| Resource | URL |
|---|---|
| Official Kubernetes Docs | https://kubernetes.io/docs |
| Interactive Tutorial (official) | https://kubernetes.io/docs/tutorials |
| Kubernetes the Hard Way (Kelsey Hightower) | https://github.com/kelseyhightower/kubernetes-the-hard-way |
| CNCF Landscape | https://landscape.cncf.io |
| CIS Kubernetes Benchmark | https://www.cisecurity.org/benchmark/kubernetes |
| NSA/CISA Kubernetes Hardening Guide | https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF |
| Helm (Package Manager) | https://helm.sh |
| Kyverno (Policy Engine) | https://kyverno.io |
| Trivy (Image Scanner) | https://trivy.dev |

---

*Last updated: April 2026. Kubernetes evolves quickly — always check the official docs for the version you are running.*

<small>
<b>Commits To This Document:</b></br>
1. Initial generation with Claude Sonnet 4.6 Prompt: Help me understand Kubernetes.  How does it compare to Docker?  What is the cost structure to use it and is there a free local development version?  How might I set up a local development instance?  What security and privacy considerations should I have when installing or using it? Present it in a format which can be used in a GitHub project wiki.

* After reviewing first version the followup prompt was given: In the steps explaining how to set up a local development environment I notice the windows commands use "choco" which is not a default terminal command in windows.  Use only standard environment commands if possible, if not possible then provide relevant instructions on how to install and set up the non-standard/built-in command. Initial version not commited for reasons.
</small>