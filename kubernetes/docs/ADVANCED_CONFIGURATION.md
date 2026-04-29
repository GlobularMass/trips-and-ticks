# Advanced Kubernetes Configuration

This document provides advanced configuration options for the Trips and Ticks Kubernetes deployment. These topics are **platform-agnostic** and apply to all operating systems (Windows, Linux, macOS).

For platform-specific setup instructions, see:
- **Windows:** [WINDOWS_SETUP_GUIDE.md](WINDOWS_SETUP_GUIDE.md)
- **Linux/macOS:** [POSIX_SETUP_GUIDE.md](POSIX_SETUP_GUIDE.md)

## Table of Contents

1. [Customizing the Deployment](#customizing-the-deployment)
2. [Post-Deployment Configuration](#post-deployment-configuration)
3. [Production Hardening](#production-hardening)
4. [Backup and Recovery](#backup-and-recovery)

## Customizing the Deployment

### 1. Modify Pod Replicas

Edit the deployment files to change the number of replicas:

**MongoDB (StatefulSet):**
```yaml
spec:
  replicas: 3  # Change from 1
  serviceName: mongodb
```

**PostgreSQL (StatefulSet):**
```yaml
spec:
  replicas: 2  # Change from 1
  serviceName: postgres
```

**Airflow Webserver:**
```yaml
spec:
  replicas: 2  # Change from 1 for HA
```

### 2. Adjust Resource Limits

Modify CPU and memory requests/limits:

```yaml
resources:
  requests:
    memory: "2Gi"      # Increase if needed
    cpu: "1000m"       # Increase for more processing power
  limits:
    memory: "4Gi"      # Set appropriate ceiling
    cpu: "2000m"
```

### 3. Change Storage Sizes

Edit `manifests/storage/volumes.yaml`:

```yaml
spec:
  capacity:
    storage: 50Gi  # Increase from 10Gi for MongoDB
```

Also update PersistentVolumeClaims:

```yaml
resources:
  requests:
    storage: 50Gi
```

### 4. Modify Environment Variables

Edit `manifests/config/configmaps.yaml`:

```yaml
data:
  environment: staging  # Change deployment environment
  log_level: DEBUG      # Change for verbose logging
  mongodb_db: custom_db # Change database name
```

### 5. Update Credentials

Create new secrets with custom values:

```bash
# Create new MongoDB credentials
kubectl create secret generic mongodb-credentials \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=$(openssl rand -base64 32) \
  -n trips-ticks --dry-run=client -o yaml | kubectl apply -f -

# Create new PostgreSQL credentials
kubectl create secret generic postgres-credentials \
  --from-literal=admin-user=postgres \
  --from-literal=admin-password=$(openssl rand -base64 32) \
  --from-literal=airflow-user=airflow \
  --from-literal=airflow-password=$(openssl rand -base64 32) \
  -n trips-ticks --dry-run=client -o yaml | kubectl apply -f -

# Generate secure Airflow Fernet key
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# Create Airflow credentials
kubectl create secret generic airflow-credentials \
  --from-literal=fernet-key=<generated-key> \
  --from-literal=webserver-secret-key=$(openssl rand -base64 32) \
  --from-literal=airflow-user=airflow \
  --from-literal=airflow-password=$(openssl rand -base64 32) \
  -n trips-ticks --dry-run=client -o yaml | kubectl apply -f -
```

### 6. Configure Service Types

Modify service exposure in manifests:

```yaml
# For local development (NodePort)
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30080

# For production (LoadBalancer with cloud provider)
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080

# For Ingress-based routing
spec:
  type: ClusterIP
  ports:
  - port: 8080
    targetPort: 8080
```

## Post-Deployment Configuration

### 1. Initialize PostgreSQL Databases

```bash
# Connect to PostgreSQL pod
kubectl exec -it postgres-0 -n trips-ticks -- psql -U postgres

# Inside PostgreSQL:
CREATE DATABASE trips_ticks_analytics;
CREATE USER airflow WITH PASSWORD 'airflow';
GRANT ALL PRIVILEGES ON DATABASE trips_ticks_analytics TO airflow;
```

Or using SQL script:

```bash
# Create SQL file
cat > init.sql <<EOF
CREATE DATABASE trips_ticks_analytics;
CREATE USER airflow WITH PASSWORD 'airflow';
GRANT ALL PRIVILEGES ON DATABASE trips_ticks_analytics TO airflow;
CREATE TABLE audit_log (
  id SERIAL PRIMARY KEY,
  action VARCHAR(255),
  timestamp TIMESTAMP DEFAULT NOW()
);
EOF

# Execute in pod
kubectl cp init.sql trips-ticks/postgres-0:/tmp/
kubectl exec postgres-0 -n trips-ticks -- psql -U postgres -f /tmp/init.sql
```

### 2. Initialize MongoDB

```bash
# Connect to MongoDB pod
kubectl exec -it mongodb-0 -n trips-ticks -- mongosh

# Inside MongoDB:
use admin
db.auth('admin', 'change-me-in-production')
use trips_ticks_db
db.createCollection('trips')
db.createCollection('ticks')
```

### 3. Configure Airflow

```bash
# Create Airflow admin user
kubectl exec -it deployment/airflow-webserver -n trips-ticks -- \
  airflow users create \
  --username admin \
  --firstname Admin \
  --lastname User \
  --role Admin \
  --email admin@example.com \
  --password admin123

# Create database connections in Airflow UI:
# 1. Go to Admin → Connections
# 2. Create MongoDB connection:
#    - Conn Id: mongodb_default
#    - Conn Type: mongo
#    - Host: mongodb
#    - Port: 27017
#    - Login: admin
#    - Password: your-password
# 3. Create PostgreSQL connection:
#    - Conn Id: postgres_default
#    - Conn Type: postgres
#    - Host: postgres
#    - Database: trips_ticks_analytics
#    - Login: airflow
#    - Password: your-password
```

### 4. Deploy Sample DAGs

```bash
# Copy sample DAGs to persistent volume
kubectl cp sample_dags/ trips-ticks/airflow-webserver-pod:/home/airflow/dags/

# Or create DAGs through Airflow UI:
# 1. Navigate to the DAGs folder in the WebUI
# 2. Create new DAG files
# 3. Restart Airflow webserver to load new DAGs
```

## Production Hardening

### 1. Enable Network Policies

The deployment includes basic network policies. For stricter security:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: trips-ticks
spec:
  podSelector: {}
  policyTypes:
  - Ingress

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress
  namespace: trips-ticks
spec:
  podSelector:
    matchLabels:
      app: airflow-webserver
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
```

### 2. Set Pod Security Policies

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'MustRunAs'
  fsGroup:
    rule: 'MustRunAs'
  readOnlyRootFilesystem: false
```

### 3. Configure TLS/SSL

```bash
# Create self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=trips-ticks.example.com"

# Create TLS secret
kubectl create secret tls trips-ticks-tls \
  --cert=tls.crt \
  --key=tls.key \
  -n trips-ticks
```

Enable in Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: trips-ticks-ingress
  namespace: trips-ticks
spec:
  tls:
  - hosts:
    - trips-ticks.example.com
    secretName: trips-ticks-tls
  rules:
  - host: trips-ticks.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: airflow-webserver
            port:
              number: 8080
```

### 4. Enable Resource Quotas

```bash
# Create namespace resource quota
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: trips-ticks-quota
  namespace: trips-ticks
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "50"
EOF
```

### 5. Set Namespace Limits

```bash
# Default resource limits for all pods
kubectl apply -f - <<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: trips-ticks-limits
  namespace: trips-ticks
spec:
  limits:
  - max:
      memory: "2Gi"
      cpu: "2000m"
    min:
      memory: "128Mi"
      cpu: "100m"
    default:
      memory: "512Mi"
      cpu: "500m"
    defaultRequest:
      memory: "256Mi"
      cpu: "250m"
    type: Container
EOF
```

## Backup and Recovery

### 1. Backup MongoDB

```bash
# Create backup pod
kubectl exec -it mongodb-0 -n trips-ticks -- mongodump \
  --out /data/db/backup \
  --username admin \
  --password 'change-me-in-production' \
  --authenticationDatabase admin

# Copy backup locally
kubectl cp trips-ticks/mongodb-0:/data/db/backup ./mongo-backup
```

### 2. Backup PostgreSQL

```bash
# Create backup
kubectl exec -it postgres-0 -n trips-ticks -- pg_dump \
  -U postgres \
  trips_ticks_analytics > postgresql-backup.sql

# Or use binary format for faster restore
kubectl exec -it postgres-0 -n trips-ticks -- pg_dump \
  -U postgres \
  -Fc trips_ticks_analytics > postgresql-backup.dump
```

### 3. Backup Persistent Volumes

```bash
# Create snapshot (cloud provider dependent)
# For AWS EBS:
aws ec2 create-snapshot --volume-id vol-xxxxx --description "Trips-Ticks backup"

# For GCP Persistent Disks:
gcloud compute disks snapshot <disk-name> --snapshot-names=<snapshot-name> --zone=<zone>
```

### 4. Restore from Backup

**MongoDB:**
```bash
# Copy backup back to pod
kubectl cp ./mongo-backup trips-ticks/mongodb-0:/tmp/

# Restore in pod
kubectl exec -it mongodb-0 -n trips-ticks -- mongorestore \
  /tmp/mongo-backup \
  --username admin \
  --password 'change-me-in-production' \
  --authenticationDatabase admin
```

**PostgreSQL:**
```bash
# Restore from SQL dump
kubectl exec -i postgres-0 -n trips-ticks -- psql -U postgres \
  < postgresql-backup.sql

# Or from binary format (faster)
kubectl exec -i postgres-0 -n trips-ticks -- pg_restore -U postgres \
  -d trips_ticks_analytics < postgresql-backup.dump
```

---

**Next Steps:**
- After setting up advanced configuration, see [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for common operational commands
- For troubleshooting, check the platform-specific setup guide: [WINDOWS_SETUP_GUIDE.md](WINDOWS_SETUP_GUIDE.md) or [POSIX_SETUP_GUIDE.md](POSIX_SETUP_GUIDE.md)
- For architecture details, see [ARCHITECTURE.md](ARCHITECTURE.md)
