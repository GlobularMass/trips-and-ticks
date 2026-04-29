# Apache Airflow Docker Setup

Complete guide for building, running, and managing Apache Airflow in Docker with PostgreSQL as the metadata database.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
  - [1. Create Environment Variables File](#1-create-environment-variables-file)
  - [2. Initialize Airflow Database](#2-initialize-airflow-database)
  - [3. Create Admin User](#3-create-admin-user)
  - [4. Access Airflow Web UI](#4-access-airflow-web-ui)
- [Understanding the Setup](#understanding-the-setup)
  - [Services Overview](#services-overview)
  - [Architecture](#architecture)
  - [Volumes and Persistent Storage](#volumes-and-persistent-storage)
- [Creating and Managing DAGs](#creating-and-managing-dags)
  - [DAG File Structure](#dag-file-structure)
  - [Example DAG Walkthrough](#example-dag-walkthrough)
  - [DAG Best Practices](#dag-best-practices)
- [Connecting to External Services](#connecting-to-external-services)
  - [MongoDB Connection Example](#mongodb-connection-example)
  - [Database Connections](#database-connections)
- [Container Management](#container-management)
- [Logs and Monitoring](#logs-and-monitoring)
- [Environment Variables Reference](#environment-variables-reference)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)

## Prerequisites

- Docker Desktop installed (or Docker Engine on Linux)
- Docker Compose installed (comes with Docker Desktop)
- For DAG development: Python 3.8+ installed locally
- For generating Fernet keys: `cryptography` library (`pip install cryptography`)

**Note:** The Airflow configuration files are located in the `airflow/` subfolder. Run all docker-compose commands from the `docker/` folder.

## Quick Start

### 1. Set Up PostgreSQL (One-time setup)

PostgreSQL is decoupled and managed separately. See [../postgres/POSTGRES_SETUP.md](../postgres/POSTGRES_SETUP.md) for detailed instructions.

**Quick steps:**

From the `postgres/` subfolder:

```powershell
# Windows PowerShell
.\scripts\setup-env.ps1
```

```bash
# Linux/macOS Bash
./scripts/setup-env.sh
```

Then from `docker/` folder:

```bash
docker-compose up -d postgres
```

### 2. Create Airflow Environment Variables File

**Option A: Automatic Setup (Recommended)**

From the `airflow/` subfolder, run the setup script for your operating system:

**Windows PowerShell:**
```powershell
.\scripts\setup-env.ps1
```

⚠️ **Note on Script Execution:** If you get a script execution error, use one of these options:

Option 1 (Recommended - Permanent): Enable scripts for your user
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Option 2 (Temporary): Run this script while bypassing the policy
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-env.ps1
```

Option 3: Use the Bash alternative instead (requires Git Bash or WSL)

**Linux/macOS Bash:**
```bash
./scripts/setup-env.sh
```

The script will:
- Generate a Fernet key for encrypting sensitive data
- Create a `.env` file in the `airflow_config/` subfolder

**Option B: Manual Setup**

From the `airflow/` folder:

1. Copy `.env.example` to `airflow_config/.env`:
   ```bash
   cp .env.example ./airflow_config/.env  # Linux/macOS
   copy .env.example .\airflow_config\.env  # Windows Command Prompt
   ```

2. Edit `airflow_config/.env` with your configuration:
   ```env
   AIRFLOW__CORE__EXECUTOR=LocalExecutor
   AIRFLOW_WEBSERVER_PORT=8080
   ```

3. Generate a Fernet key for data encryption:
   ```bash
   python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
   ```

4. Update `AIRFLOW__CORE__FERNET_KEY` in your `.env` file

⚠️ **Important:**
- The `.env` file must be created in the `airflow_config/` subfolder
- Database credentials are loaded from `postgres/postgres_config/.env`
- The file is not included in the repository for security reasons
- Never commit the `.env` file to version control (it's in `.gitignore`)

### 3. Create Airflow Database on PostgreSQL

Airflow needs its own database and user on PostgreSQL. Run this from the `docker/` folder:

```bash
docker-compose exec postgres psql -U postgres -c "
CREATE USER airflow WITH ENCRYPTED PASSWORD 'airflow';
CREATE DATABASE airflow OWNER airflow;
GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;
"
```

Or use individual commands:

```bash
docker-compose exec postgres createuser -U postgres -P airflow
docker-compose exec postgres createdb -U postgres -O airflow airflow
```

**Note:** If you've customized the Airflow database credentials in `postgres/.env`, use those credentials instead.

### 4. Start Airflow Services

From the `docker/` folder:

```bash
docker-compose up -d airflow-webserver airflow-scheduler
```

(PostgreSQL must be running first)

### 5. Initialize Airflow Database

Run the Airflow database migration to set up all required tables:

```bash
docker-compose exec airflow-webserver airflow db migrate
```

Check the status:

```bash
docker-compose logs airflow-webserver
```

### 6. Create Admin User

Create your first Airflow admin user:

```bash
docker-compose exec airflow-webserver airflow users create \
  --username admin \
  --password admin \
  --firstname Admin \
  --lastname User \
  --role Admin \
  --email admin@example.com
```

**Change these credentials:** The default credentials above are for local testing only. In production, use strong passwords.

### 7. Access Airflow Web UI

After initialization, access the Airflow web interface:

```
http://localhost:8080
```

Login with your admin credentials created above.

## Understanding the Setup

### Services Overview

**PostgreSQL (`postgres`)**
- Role: Metadata database (shared service, managed separately)
- Image: `postgres:15-alpine` (lightweight)
- Contains: DAG states, task history, connections, variables for Airflow and other applications
- Port: `5432` (mapped to `${POSTGRES_PORT}` on host, default `5432`)
- Storage: `postgres_data` volume (persistent Docker managed volume)
- Configuration: See [../postgres/POSTGRES_SETUP.md](../postgres/POSTGRES_SETUP.md)
- **Note:** PostgreSQL is decoupled and can be used by multiple services (Airflow, future applications, etc.)

**Airflow Webserver (`airflow-webserver`)**
- Role: Web interface and REST API for Airflow
- Image: `apache/airflow:latest`
- Port: `${AIRFLOW_WEBSERVER_PORT}` (default `8080`)
- Purpose: Monitor DAGs, view task logs, manage connections and variables
- Volumes: DAGs, logs, config folders
- Requires: PostgreSQL running with `airflow` database created

**Airflow Scheduler (`airflow-scheduler`)**
- Role: Orchestrates DAG runs and task scheduling
- Image: `apache/airflow:latest`
- Purpose: Monitors DAGs, triggers runs on schedule, monitors task execution
- Runs in background (no external port)
- Volumes: DAGs, logs, config folders
- Requires: PostgreSQL running with `airflow` database created

### Architecture

```
┌─────────────────────────────────────────────┐
│       Postgres Docker Network               │
│   (shared by multiple services)             │
│                                             │
│  ┌──────────────────┐  ┌────────────────┐  │
│  │  Webserver       │  │   Scheduler    │  │
│  │  (:8080)         │  │   (background) │  │
│  │                  │  │                │  │
│  │ LocalExecutor    │  │ LocalExecutor  │  │
│  └────────┬─────────┘  └────────┬───────┘  │
│           │                    │           │
│           └────────────┬───────┘           │
│                        │                   │
│                  ┌─────▼────────┐          │
│                  │  PostgreSQL  │          │
│                  │  Container   │          │
│                  │  (postgres)  │          │
│                  │  (:5432)     │          │
│                  │              │          │
│                  │  Databases:  │          │
│                  │  - airflow   │          │
│                  │  - (future)  │          │
│                  └──────────────┘          │
│                                             │
└─────────────────────────────────────────────┘

Host System
├── postgres/                ← PostgreSQL config, docs, scripts
├── airflow/                 ← Airflow config, DAGs, logs
│   ├── airflow_dags/        ← Place your DAGs here
│   ├── airflow_logs/        ← Task execution logs
├── postgres/                ← PostgreSQL config, docs, scripts
├── airflow/                 ← Airflow config, DAGs, logs
│   ├── airflow_dags/        ← Place your DAGs here
│   ├── airflow_logs/        ← Task execution logs
│   ├── airflow_config/      ← Airflow configuration
└── docker-compose.yml       ← Orchestrates all services
```

**Note:** PostgreSQL data is stored in a Docker-managed volume (`postgres_data`) for reliability and portability.

### Volumes and Persistent Storage

**PostgreSQL Volume (Docker-managed)**
- Managed by: Docker named volume `postgres_data`
- Stores: All Airflow metadata, databases, and future application data
- Persists across container restarts automatically
- See [../postgres/POSTGRES_SETUP.md](../postgres/POSTGRES_SETUP.md) for backup/restore instructions

**Airflow DAGs Volume**
- Host: `./airflow/airflow_dags/`
- Container: `/home/airflow/dags`
- Contains all your DAG definition files
- Changes are picked up automatically by the scheduler (within a few seconds)
- Host: `./airflow/airflow_logs/`
- Container: `/home/airflow/logs`
- Contains task execution logs
- Searchable through the web UI Task Logs page

**Airflow Config Volume**
- Host: `./airflow/airflow_config/`
- Container: `/home/airflow/config`
- Contains `.env` file and other configuration

## Creating and Managing DAGs

### DAG File Structure

DAG files go in the `airflow_dags/` folder. Example structure:

```
airflow_dags/
├── example_dag.py           # Example DAG (provided)
├── daily_etl_dag.py         # Your daily ETL pipeline
├── data_processing.py       # Data processing tasks
└── reporting_dag.py         # Reporting pipelines
```

**File Naming Rules:**
- Must have `.py` extension
- Filename cannot contain hyphens (use underscores: `my_dag.py`, not `my-dag.py`)
- Filename is NOT the DAG ID (set explicitly in code)
- Files in subdirectories are also scanned

### Example DAG Walkthrough

The provided `example_dag.py` demonstrates:

```python
from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

# DAG definition
dag = DAG(
    'example_dag',                              # Unique DAG ID
    schedule_interval='@daily',                 # Run once per day
    start_date=datetime(2024, 1, 1),           # Start date
    catchup=False,                              # Don't backfill
    tags=['example'],                           # Organizational tags
)

# Task definitions
task_1 = PythonOperator(
    task_id='hello_task',
    python_callable=print_hello,
    dag=dag,
)

task_2 = BashOperator(
    task_id='bash_task',
    bash_command='echo "Hello from bash!"',
    dag=dag,
)

# Define task dependencies
task_1 >> task_2  # task_1 runs first, then task_2
```

**Key Concepts:**

| Concept | Explanation |
|---------|-------------|
| **DAG** | Directed Acyclic Graph; defines your workflow |
| **Task** | Individual unit of work in a DAG |
| **Operator** | Python class that defines what a task does |
| **Task ID** | Unique identifier within a DAG |
| **DAG ID** | Unique identifier for the entire DAG |
| **Schedule Interval** | How often the DAG runs (`@daily`, `@hourly`, cron expression) |
| **Dependencies** | Order of task execution (`>>` operator) |

### DAG Best Practices

1. **Idempotency**: Tasks should produce the same result if run multiple times
2. **Small tasks**: Break complex operations into smaller, focused tasks
3. **Meaningful IDs**: Use descriptive task and DAG IDs
4. **Error handling**: Add retry logic and failure notifications
5. **Keep DAGs simple**: Avoid complex conditional logic within DAGs
6. **Use templates**: Leverage Airflow's templating for dynamic values
7. **Monitor execution**: Check logs regularly for errors

Example with retries and error handling:

```python
default_args = {
    'owner': 'data-team',
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'on_failure_callback': send_failure_alert,  # Custom function
}

dag = DAG('my_dag', default_args=default_args, ...)
```

## Connecting to External Services

### MongoDB Connection Example

To connect tasks to MongoDB (running in the same Docker network):

```python
from pymongo import MongoClient
from airflow.operators.python import PythonOperator

def process_mongodb_data(**context):
    # Connect to MongoDB (use hostname from docker-compose)
    client = MongoClient('mongodb://admin:password@mongodb-container:27017/')
    db = client['myapp']
    
    # Query data
    collection = db['mycollection']
    documents = collection.find({'status': 'active'})
    
    # Process...
    for doc in documents:
        print(doc)
    
    client.close()

# In your DAG
task = PythonOperator(
    task_id='mongodb_task',
    python_callable=process_mongodb_data,
    dag=dag,
)
```

**Important:** Use `mongodb-container` as the hostname (from docker-compose service name, not container name).

### Database Connections

**Using Airflow Connections:**

1. Go to Admin → Connections in web UI
2. Create new connection:
   - Conn ID: `mongodb_default`
   - Conn Type: `mongo`
   - Host: `mongodb-container`
   - Port: `27017`
   - Extra: `{"authSource": "admin"}`

3. Use in DAG:
```python
from airflow.providers.mongo.hooks.mongo import MongoHook

def my_task():
    hook = MongoHook(mongo_conn_id='mongodb_default')
    collection = hook.get_collection('mydb', 'mycollection')
    # ...
```

## Container Management

### View Service Status

```bash
docker-compose ps
```

Shows all services with their current state and ports.

### Start Services

```bash
# Start all services
docker-compose up -d

# Start specific services
docker-compose up -d postgres airflow-webserver
```

### Stop Services

```bash
# Stop all services
docker-compose stop

# Stop and remove containers (data persists)
docker-compose down

# Stop and remove everything including volumes (WARNING: data loss!)
docker-compose down -v
```

### View Logs

```bash
# View logs from all services
docker-compose logs -f

# View logs from specific service
docker-compose logs -f airflow-webserver
docker-compose logs -f airflow-scheduler
docker-compose logs -f postgres

# View last 100 lines
docker-compose logs --tail=100 airflow-webserver
```

### Access Container Shell

```bash
# Access webserver shell
docker-compose exec airflow-webserver bash

# Access scheduler shell
docker-compose exec airflow-scheduler bash

# Access PostgreSQL shell
docker-compose exec postgres psql -U airflow -d airflow
```

## Logs and Monitoring

### Task Logs

**Via Web UI:**
1. Go to Airflow DAGs page
2. Click on a DAG run
3. Click on a task instance
4. View logs in the "Logs" tab

**Via File System:**

Task logs are stored in `airflow_logs/` with structure:
```
airflow_logs/
└── dag_id/
    └── task_id/
        └── 2024-01-01T00_00_00+00_00/
            └── 1.log
```

**Via Docker Logs:**

```bash
docker-compose logs -f airflow-scheduler | grep "ERROR"    # View errors
docker-compose logs -f airflow-webserver                    # View webserver logs
```

### Health Checks

The services include health checks:

```bash
docker-compose ps
```

Look for `(healthy)` status next to each service.

## Environment Variables Reference

Create your `.env` file based on `.env.example`. Key variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | `airflow` | PostgreSQL username |
| `POSTGRES_PASSWORD` | `airflow` | PostgreSQL password (⚠️ change in production) |
| `POSTGRES_DB` | `airflow` | PostgreSQL database name |
| `AIRFLOW__CORE__EXECUTOR` | `LocalExecutor` | Task execution strategy |
| `AIRFLOW__CORE__FERNET_KEY` | *(required)* | Key for encrypting sensitive data |
| `AIRFLOW__WEBSERVER__SECRET_KEY` | *(auto-generated)* | Secret key for web UI |
| `AIRFLOW_WEBSERVER_PORT` | `8080` | Port for web UI |
| `POSTGRES_PORT_FORWARD` | `5432` | Port forwarding for PostgreSQL |

### Executor Options

| Executor | Best For | Notes |
|----------|----------|-------|
| `LocalExecutor` | Development, single-machine | Tasks run sequentially on same machine |
| `SequentialExecutor` | Testing, CI/CD | Tasks run one at a time (slowest) |
| `CeleryExecutor` | Production, distributed | Requires Redis; tasks run on workers |

## Security Best Practices

1. **Generate Fernet Keys:** Never use placeholder keys in production
   ```bash
   python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
   ```

2. **Use Strong Passwords:** Change default PostgreSQL and Airflow admin credentials

3. **Restrict Web UI Access:** Use firewall rules and authentication

4. **Secure Connections:** Use SSL/TLS for production deployments

5. **Variable Security:** Use Airflow Variables and Connections instead of hardcoding in DAGs

6. **File Permissions:** Restrict access to `airflow_config/.env`:
   ```bash
   chmod 600 ./airflow_config/.env
   ```

7. **Network Isolation:** Services communicate via Docker network, not exposed ports

## Troubleshooting

### Docker daemon is not running

**Error:** `error during connect: This error may indicate the docker daemon is not running`

**Solution:**

**On Windows:**
- Start Docker Desktop from the Start Menu
- Wait for it to fully initialize (3-5 minutes) before running docker commands
- Verify it's running by checking the system tray icon
- Test with: `docker ps`

**On Linux:**
```bash
sudo systemctl start docker
```

**On macOS:**
- Open Applications > Docker.app
- Wait for the menu bar icon to show (whale icon is active when running)
- Test with: `docker ps`

### Webserver won't start

```bash
# Check logs
docker-compose logs airflow-webserver

# Common issues:
# - PostgreSQL not ready: wait a minute and try restarting
docker-compose restart airflow-webserver

# - Port 8080 already in use: change AIRFLOW_WEBSERVER_PORT in .env
# - Fernet key missing: generate and add to .env
```

### PostgreSQL connection fails

```bash
# Check PostgreSQL is running and healthy
docker-compose ps postgres

# Verify credentials in .env match
docker-compose logs postgres

# Manually test PostgreSQL connection
docker-compose exec postgres psql -U airflow -d airflow -c "SELECT 1"
```

### DAG not appearing in Airflow

1. Verify file is in `airflow_dags/` folder
2. Check for syntax errors:
   ```bash
   python airflow_dags/your_dag.py
   ```
3. Ensure DAG ID is unique (no duplicates)
4. Check scheduler logs for parsing errors:
   ```bash
   docker-compose logs airflow-scheduler | grep ERROR
   ```
5. Wait 30 seconds and refresh the web UI

### Tasks not executing

1. Check scheduler is running:
   ```bash
   docker-compose ps airflow-scheduler
   ```

2. Check DAG is paused (toggle in web UI)

3. Verify schedule interval is correct

4. Check task dependencies and upstream tasks

5. View scheduler logs:
   ```bash
   docker-compose logs -f airflow-scheduler
   ```

### Permission denied on airflow_logs folder (Linux/macOS)

```bash
chmod 755 ./airflow/airflow_logs
chmod 755 ./airflow/airflow_dags
chmod 755 ./airflow/airflow_config
```

### Out of memory or disk space

Airflow logs can grow large. To clean up old logs:

```bash
# View disk usage
du -sh ./airflow/airflow_logs

# Remove logs older than 30 days (Linux/macOS)
find ./airflow/airflow_logs -type f -mtime +30 -delete

# Clean Docker system
docker system prune -a
```

### Port already in use

If port 8080 or 5432 is in use:

1. Change in `.env`:
   ```env
   AIRFLOW_WEBSERVER_PORT=8090
   POSTGRES_PORT_FORWARD=5433
   ```

2. Restart services:
   ```bash
   docker-compose restart
   ```

## Additional Resources

- [Apache Airflow Official Documentation](https://airflow.apache.org/docs/)
- [Airflow Python API Reference](https://airflow.apache.org/docs/apache-airflow/stable/python-api-for-operators-and-hooks.html)
- [Available Airflow Operators](https://airflow.apache.org/docs/apache-airflow/stable/howto/operator/index.html)
- [Airflow Community Providers](https://airflow.apache.org/docs/apache-airflow-providers/packages-ref.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Airflow Best Practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html)
- [Debugging DAGs](https://airflow.apache.org/docs/apache-airflow/stable/debugging-dag-definition-files.html)
