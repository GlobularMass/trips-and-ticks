# Trips and Ticks - Kubernetes Architecture & Technical Overview

## Document Overview

This document provides a comprehensive technical overview of the Kubernetes deployment architecture for the Trips and Ticks application, including component details, networking, data flows, and operational considerations.

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Component Specifications](#component-specifications)
3. [Network Architecture](#network-architecture)
4. [Data Flow](#data-flow)
5. [Resource Management](#resource-management)
6. [High Availability & Disaster Recovery](#high-availability--disaster-recovery)
7. [Security Architecture](#security-architecture)
8. [Performance Considerations](#performance-considerations)

## System Architecture

### Overview Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│                   (trips-ticks namespace)                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   MongoDB    │    │  PostgreSQL  │    │   Airflow    │  │
│  │ StatefulSet  │    │ StatefulSet  │    │ Deployments  │  │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘  │
│         │                    │                    │          │
│         └────────────────────┼────────────────────┘          │
│                              │                               │
│              ┌───────────────┴───────────────┐               │
│              │   Kubernetes Services        │               │
│              │   (Internal DNS)            │               │
│              └───────────────┬───────────────┘               │
│                              │                               │
│        ┌─────────────────────┼─────────────────────┐        │
│        │                     │                     │        │
│   ┌────▼────┐          ┌─────▼──────┐        ┌────▼────┐  │
│   │  PVC    │          │    PVC     │        │   PVC   │  │
│   │(MongoDB)│          │(PostgreSQL)│        │(Airflow)│  │
│   └─────────┘          └────────────┘        └─────────┘  │
│         │                     │                     │       │
│         └─────────────────────┼─────────────────────┘       │
│                               │                             │
│              ┌────────────────▼────────────────┐           │
│              │ Persistent Volumes              │           │
│              │ (Local Storage or Cloud)        │           │
│              └─────────────────────────────────┘           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         │ External Access    │                    │
         ▼                    ▼                    ▼
    MongoDB         PostgreSQL         Airflow WebUI
   (port 27017)    (port 5432)         (port 8080)
```

### Key Layers

1. **Container Layer:** Docker containers for MongoDB, PostgreSQL, Airflow
2. **Orchestration Layer:** Kubernetes StatefulSets, Deployments, Services
3. **Networking Layer:** ClusterIP services, NetworkPolicies
4. **Storage Layer:** PersistentVolumes and PersistentVolumeClaims
5. **Configuration Layer:** ConfigMaps for settings, Secrets for credentials

## Component Specifications

### 1. MongoDB StatefulSet

**Purpose:** Primary data store for real-time trip tracking and telemetry data

**Specification:**

```yaml
Kind: StatefulSet
Replicas: 1 (configurable to 3+ for HA)
Image: mongo:6.0
Port: 27017
Storage: 10Gi (PersistentVolumeClaim)
```

**Key Features:**
- Persistent volume for data durability
- Admin authentication enabled
- HeartbeatFrequencyMS optimized for cluster detection
- WiredTiger storage engine
- Replica set support via `rs.initiate()`

**Database Structure:**
```
Database: trips_ticks_db
Collections:
  - trips (trip records)
  - ticks (location updates/telemetry)
  - events (system events)
  - metadata (configuration)
```

**Initialization:**
```javascript
// Connect and initialize
use admin
db.auth('admin', 'password')
use trips_ticks_db
db.createCollection('trips')
db.createCollection('ticks')
db.trips.createIndex({ timestamp: 1 })
db.ticks.createIndex({ trip_id: 1, timestamp: 1 })
```

### 2. PostgreSQL StatefulSet

**Purpose:** Analytical and transactional data store for processed records and metadata

**Specification:**

```yaml
Kind: StatefulSet
Replicas: 1 (configurable to 2+ for HA)
Image: postgres:15-alpine
Port: 5432
Storage: 20Gi (PersistentVolumeClaim)
```

**Key Features:**
- Persistent volume for data durability
- md5-based password authentication
- Optimized connection pooling settings
- WAL archiving for backup/recovery
- Adaptive query planning

**Database Structure:**
```sql
Database: trips_ticks_analytics
Tables:
  - trips_summary (aggregated trip data)
  - tick_analytics (processed telemetry)
  - performance_metrics (system metrics)
  - airflow_metadata (Airflow DAG runs)
  - airflow_logs (Airflow task logs)

User: airflow
  - Purpose: Used by Airflow for metadata storage
  - Permissions: Full access to airflow and analytics tables
```

**Special Considerations:**
- PostGIS extension available (for geospatial queries)
- Full-text search enabled for analytics
- Query performance monitored via pg_stat_statements

### 3. Apache Airflow Deployment

#### Webserver Deployment

**Purpose:** Web UI for DAG management, monitoring, and configuration

**Specification:**

```yaml
Kind: Deployment
Replicas: 1 (configurable to 2+ for HA)
Image: apache/airflow:latest
Port: 8080
Storage: N/A (logs stored in persistent volume)
Environment:
  - Executor: LocalExecutor
  - Database Backend: PostgreSQL
```

**Key Features:**
- Multi-user authentication
- DAG versioning and history
- Task logs and metrics
- Connection management UI
- Variable and XCom storage
- Plugin management

**Exposed Endpoints:**
- `/` - Main UI
- `/api/` - REST API
- `/health` - Health check
- `/flower` - Task queue monitoring (if using Celery)

**Resource Scaling:**
- Web server serves HTTP requests
- CPU usage moderate (task execution on scheduler)
- Memory grows with DAG complexity

#### Scheduler Deployment

**Purpose:** Orchestrates DAG scheduling and task execution

**Specification:**

```yaml
Kind: Deployment
Replicas: 1 (single scheduler recommended, else use HA setup)
Image: apache/airflow:latest
Port: N/A (internal communication only)
Storage: PVC for logs
Environment:
  - Executor: LocalExecutor
  - Database Backend: PostgreSQL
```

**Key Features:**
- DAG parsing and scheduling
- Task dependency resolution
- Retry logic and fault tolerance
- Monitoring and alerting hooks
- Dynamic DAG generation support

**Important Notes:**
- Only one active scheduler should run (unless using HA setup)
- Scheduler scans DAGs every 300 seconds (configurable)
- Logs stored to persistent volume for persistence

#### DAGs Storage

**Purpose:** Persistent storage for Airflow DAG files

**Specification:**

```yaml
Kind: PersistentVolumeClaim
Size: 5Gi
MountPath: /home/airflow/dags
Access Mode: ReadWriteMany (for shared access)
```

**DAG Structure:**
```
/home/airflow/dags/
├── example_dags/
│   ├── trip_processing_dag.py
│   ├── analytics_pipeline_dag.py
│   └── data_cleanup_dag.py
├── operators/
│   ├── mongodb_operator.py
│   ├── postgres_operator.py
│   └── custom_operators.py
└── utils/
    ├── database_utils.py
    ├── api_utils.py
    └── logging_config.py
```

#### Logs Storage

**Purpose:** Persistent storage for Airflow task execution logs

**Specification:**

```yaml
Kind: PersistentVolumeClaim
Size: 10Gi
MountPath: /home/airflow/logs
Access Mode: ReadWriteMany
Retention: Configure via airflow.cfg (default 30 days)
```

**Log Structure:**
```
/home/airflow/logs/
├── dag_id_1/
│   ├── task_id_1/
│   │   ├── 2024-01-15T10:30:00/
│   │   │   ├── 1_try.log (first attempt)
│   │   │   └── 2_try.log (retry)
```

### 4. ConfigMaps & Secrets

#### ConfigMaps

**Purpose:** Application configuration and environment variables

**Key ConfigMaps:**

1. **mongodb-config**
   - MongoDB server configuration (mongod.conf)
   - Replica set settings
   - Storage engine options

2. **postgres-config**
   - PostgreSQL server configuration
   - Connection limits
   - Performance tuning parameters

3. **airflow-config**
   - Airflow core settings
   - Executor configuration
   - Web server settings
   - Scheduler settings

4. **app-config**
   - Application environment variables
   - Service discovery DNS names
   - Database names

#### Secrets

**Purpose:** Sensitive credentials and keys

**Key Secrets:**

1. **mongodb-credentials**
   - Admin username (base64 encoded)
   - Admin password (base64 encoded)

2. **postgres-credentials**
   - Superuser credentials
   - Airflow user credentials

3. **airflow-credentials**
   - Fernet encryption key (for sensitive data)
   - Web server secret key
   - Admin credentials

## Network Architecture

### Service Communication

```
Service Mesh (Internal):
  ┌─────────────────────────────────────┐
  │      Kubernetes DNS (kube-dns)      │
  │   trips-ticks.local: ClusterIP      │
  └────────┬────────────────────────────┘
           │
  ┌────────┴──────────┬──────────────┬──────────────┐
  │                   │              │              │
  ▼                   ▼              ▼              ▼
mongodb          postgres      airflow-webserver  airflow-scheduler
(port 27017)     (port 5432)   (port 8080)        (internal)
```

### Service Types

1. **MongoDB Service**
   ```yaml
   Type: ClusterIP (headless for StatefulSet)
   DNS: mongodb.trips-ticks.svc.cluster.local
   Port: 27017
   ```

2. **PostgreSQL Service**
   ```yaml
   Type: ClusterIP
   DNS: postgres.trips-ticks.svc.cluster.local
   Port: 5432
   ```

3. **Airflow WebServer**
   ```yaml
   Type: LoadBalancer (or NodePort for local)
   Port: 8080
   External endpoint: Load Balancer IP or Node IP
   ```

### Network Policies

**Default Policy:** Allow all internal traffic within namespace

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-internal
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: trips-ticks
```

**DNS Only Policy:** Allows egress to external DNS

```yaml
egress:
- to:
  - namespaceSelector: {}
  ports:
  - protocol: TCP
    port: 53
  - protocol: UDP
    port: 53
```

## Data Flow

### 1. Trip Data Ingestion

```
External API/Application
         │
         ▼
    Airflow DAG (trip_ingestion_dag)
         │
         ├──> Fetch from source API
         │
         ├──> Validate & transform
         │
         └──> Store in MongoDB
              └─> trips collection
              └─> ticks collection
```

### 2. Data Processing Pipeline

```
MongoDB (Raw Data)
         │
         ▼
Airflow Scheduler
         │
    ┌────┴───┬──────────┬───────────┐
    │        │          │           │
    ▼        ▼          ▼           ▼
[ETL]   [Transform][Aggregate][Validate]
    │        │          │           │
    └────┬───┴──────────┴───────────┘
         │
         ▼
PostgreSQL (Analytics)
    ├─> trips_summary
    ├─> tick_analytics
    └─> performance_metrics
```

### 3. Query Path

```
User/Application
         │
         ▼
If Real-time Data:
    └──> MongoDB (Direct Query)
         
If Analytics:
    └──> PostgreSQL (Processed Data)

If Scheduled Reports:
    └──> Airflow DAG
         └──> Query PostgreSQL
         └──> Generate Report
         └──> Export/Notify
```

## Resource Management

### Memory Management

**Pod Memory Allocation:**

| Component | Request | Limit | Notes |
|-----------|---------|-------|-------|
| MongoDB | 512Mi | 1Gi | Adjust based on data volume |
| PostgreSQL | 512Mi | 1Gi | Handles analytical workload |
| Airflow Webserver | 1Gi | 2Gi | UI and API server |
| Airflow Scheduler | 512Mi | 1Gi | DAG parsing and scheduling |

**Total Baseline:** 2.5Gi (without headroom)
**Recommended Total:** 5-10Gi (with 2-4x headroom)

### CPU Management

**Pod CPU Allocation:**

| Component | Request | Limit | Notes |
|-----------|---------|-------|-------|
| MongoDB | 250m | 500m | I/O bound |
| PostgreSQL | 250m | 500m | I/O bound |
| Airflow Webserver | 500m | 1000m | Handles requests |
| Airflow Scheduler | 250m | 500m | Scheduling overhead |

### Storage Management

**Storage Allocation:**

| Component | Size | Growth Rate | Retention |
|-----------|------|-------------|-----------|
| MongoDB | 10Gi | ~100MB/day | Keep all data |
| PostgreSQL | 20Gi | ~50MB/day | Keep aggregated data |
| Airflow Logs | 10Gi | ~50MB/day | 30 days default |

### Resource Quotas

**Namespace Quota Example:**

```yaml
ResourceQuota:
  CPU: 20 cores
  Memory: 40Gi
  Pods: 50
  PVC: 10
```

## High Availability & Disaster Recovery

### High Availability Setup

#### MongoDB HA

```yaml
# Scale to 3 replicas
replicas: 3

# Initialize replica set manually
rs.initiate({
  _id: "rs0",
  members: [
    {_id: 0, host: "mongodb-0:27017"},
    {_id: 1, host: "mongodb-1:27017"},
    {_id: 2, host: "mongodb-2:27017"}
  ]
})
```

#### PostgreSQL HA

Option 1: **Streaming Replication**
```yaml
# Primary + Standby setup
Primary: postgres-0
Standby: postgres-1

# WAL archiving enabled for Point-in-Time Recovery
```

Option 2: **Distributed PostgreSQL (e.g., Citus)**
- Horizontal scalability
- No single point of failure
- Distributed query execution

#### Airflow HA

```yaml
# Multiple scheduler instances
Airflow Scheduler:
  replicas: 3
  
# Multiple webserver instances
Airflow Webserver:
  replicas: 2
  
# Shared database (PostgreSQL)
# Shared logs (PVC)
```

### Disaster Recovery

#### Backup Strategy

1. **Database Backups (Daily)**
   - MongoDB: Daily mongodump
   - PostgreSQL: Daily pg_dump
   - Retention: 30 days

2. **Volume Snapshots (Weekly)**
   - VolumeSnapshot for PVCs
   - Retention: 8 snapshots (2 months)

3. **Configuration Backup (Daily)**
   - Export ConfigMaps and Secrets
   - Store in version control
   - Retention: Indefinite

#### Recovery Procedures

**MongoDB Recovery:**
```bash
# From mongodump
mongorestore --drop <backup-directory>

# From snapshot
# Create PVC from VolumeSnapshot
# Attach to new MongoDB pod
```

**PostgreSQL Recovery:**
```bash
# From pg_dump
psql < backup.sql

# Point-in-time recovery
pg_basebackup -D /recovery
```

## Security Architecture

### Authentication & Authorization

```
┌──────────────────┐
│  Ingress Layer   │
├──────────────────┤
│  basic-auth or   │
│  OAuth2 Proxy    │
└────────┬─────────┘
         │
┌────────▼──────────┐
│  Service Level    │
├───────────────────┤
│  - RBAC           │
│  - Pod Security   │
│  - Network Policy │
└───────────────────┘
         │
┌────────▼──────────┐
│  Database Level   │
├───────────────────┤
│  - User Auth      │
│  - Encryption     │
│  - Audit Logs     │
└───────────────────┘
```

### Encryption

**In Transit:**
- TLS/SSL for Ingress
- Encrypted connections between services
- Network policies for east-west traffic

**At Rest:**
- Encrypted PersistentVolumes (cloud provider)
- Database-level encryption (MongoDB, PostgreSQL)
- Secret encryption in etcd

### RBAC Configuration

```yaml
ServiceAccount: airflow
ClusterRole:
  - pods: get, list, watch, create, delete
  - pods/logs: get, list
  - jobs: get, list, watch, create, delete
  - secrets: get

Roles per Component:
  - MongoDB: Limited to collection operations
  - PostgreSQL: Limited to schema operations
  - Airflow: Full DAG management
```

## Performance Considerations

### Database Query Optimization

**MongoDB:**
```javascript
// Indexes for common queries
db.trips.createIndex({ user_id: 1, timestamp: -1 })
db.ticks.createIndex({ trip_id: 1, timestamp: 1 })

// Aggregation pipeline for analytics
db.ticks.aggregate([
  { $match: { trip_id: ObjectId(...) } },
  { $group: { _id: "$user_id", count: { $sum: 1 } } }
])
```

**PostgreSQL:**
```sql
-- Indexes for common queries
CREATE INDEX ON trips_summary(user_id, created_at DESC);
CREATE INDEX ON tick_analytics(trip_id, timestamp);

-- Analyze query plans
EXPLAIN ANALYZE SELECT * FROM trips_summary WHERE user_id = 1;
```

### Caching Strategy

1. **In-Memory Caching (Airflow):**
   - XCOM for inter-task data
   - Task result cache
   - DAG parsing cache

2. **Database-Level Caching:**
   - Query result caching
   - Index caching (buffer pool)
   - Materialized views for common reports

### Monitoring Metrics

**Key Metrics to Monitor:**

| Metric | Source | Alert Threshold |
|--------|--------|-----------------|
| Pod CPU Usage | Kubernetes | > 80% limit |
| Pod Memory Usage | Kubernetes | > 85% limit |
| PVC Usage | Kubernetes | > 90% capacity |
| MongoDB Connections | MongoDB | > 90% max |
| PostgreSQL Connections | PostgreSQL | > 90% max |
| DAG Parse Time | Airflow | > 30s |
| Task Success Rate | Airflow | < 95% |

---

For deployment instructions, see [README.md](../README.md)
For setup details, see [POSIX_SETUP_GUIDE.md](POSIX_SETUP_GUIDE.md)
