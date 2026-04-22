# MongoDB Docker Setup

Complete guide for building, running, and connecting to MongoDB in Docker.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
  - [1. Create Environment Variables File](#1-create-environment-variables-file)
  - [2. Build and Run the Container](#2-build-and-run-the-container)
  - [3. Verify the Container is Running](#3-verify-the-container-is-running)
- [Understanding docker-compose.yml Configuration](#understanding-docker-composeyml-configuration)
  - [Healthcheck Section](#healthcheck-section)
  - [Log Rotation Configuration](#log-rotation-configuration)
- [Connecting via Command Line](#connecting-via-command-line)
  - [Using MongoDB Shell (mongosh)](#using-mongodb-shell-mongosh)
  - [Installing mongosh Locally (Optional)](#installing-mongosh-locally-optional)
- [Connecting from Python](#connecting-from-python)
  - [Prerequisites](#prerequisites-1)
  - [Installation](#installation)
  - [Basic Connection Example](#basic-connection-example)
  - [Complete Example Script](#complete-example-script)
- [Persistent Storage Configuration](#persistent-storage-configuration)
  - [Current Setup](#current-setup)
  - [MongoDB Configuration Files](#mongodb-configuration-files)
  - [Folder Structure](#folder-structure)
  - [Changing the Storage Path](#changing-the-storage-path)
  - [Verify Storage is Working](#verify-storage-is-working)
- [MongoDB Logs](#mongodb-logs)
  - [Log Files Overview](#log-files-overview)
  - [Docker Container Logs (Already Rotating)](#docker-container-logs-already-rotating)
  - [MongoDB Application Logs](#mongodb-application-logs)
  - [Viewing MongoDB Logs](#viewing-mongodb-logs)
  - [Enabling MongoDB Log Rotation](#enabling-mongodb-log-rotation)
- [Container Management](#container-management)
- [Environment Variables Reference](#environment-variables-reference)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)

## Prerequisites

- Docker Desktop installed (or Docker Engine on Linux)
- Docker Compose installed (comes with Docker Desktop)
- For Python connections: `pymongo` library (`pip install pymongo`)
- For CLI connections: MongoDB Shell (`mongosh`) - can be installed separately or used inside the container

**Note:** The environment setup and MongoDB documentation files are located in the `mongodb/` subfolder. Run all commands from this folder unless otherwise noted.

## Quick Start

### 1. Create Environment Variables File

**Option A: Automatic Setup (Recommended)**

From the `mongodb/` subfolder, run the setup script for your operating system:

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
- Check for existing system environment variables (`MONGO_ROOT_USER`, `MONGO_ROOT_PASSWORD`, `MONGO_DB_NAME`, etc.)
- Use them if they exist, otherwise use the default values
- Create a `.env` file in the `mongodb_config/` subfolder with the appropriate values

**Option B: Manual Setup**

From the `mongodb/` folder:

1. Copy `.env.example` to `mongodb_config/.env`:
   ```bash
   cp .env.example ./mongodb_config/.env  # Linux/macOS
   copy .env.example .\mongodb_config\.env  # Windows Command Prompt
   ```

2. Edit `mongodb_config/.env` and update with your credentials:
   ```env
   MONGO_ROOT_USER=admin
   MONGO_ROOT_PASSWORD=SecurePassword123!
   MONGO_DB_NAME=myapp
   ```

⚠️ **Important:** 
- The `.env` file must be created in the `mongodb_config/` subfolder (shared between docker-compose and the container)
- The file is not included in the repository for security reasons
- Never commit the `.env` file to version control (it's already listed in `.gitignore`)

### 2. Build and Run the Container

From the `docker/` folder (where `docker-compose.yml` is located), run:

```bash
docker-compose up -d
```

This will:
- Download the latest MongoDB image
- Create a container named `mongodb-container`
- Mount volumes in the `mongodb/` subfolder for persistent storage (data, config, and logs)
- Enable authentication
- Configure automatic Docker log rotation (max 200MB per file, 3 files retained)
- Start a health check to verify MongoDB is ready
- Start the container in detached mode

### 3. Verify the Container is Running

```bash
docker-compose ps
```

You should see `mongodb-container` with status "Up".

Check the health:

```bash
docker-compose logs mongodb
```

## Understanding docker-compose.yml Configuration

### Healthcheck Section

The `healthcheck` section ensures Docker knows when MongoDB is ready to accept connections:

```yaml
healthcheck:
  test: echo 'db.runCommand("ping").ok' | mongosh localhost/test --quiet
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 40s
```

**What each parameter means:**

- **`test`**: The command to run to check if MongoDB is healthy. Sends a ping command to the database and expects a success response.
- **`interval: 10s`**: Run the health check every 10 seconds after the container starts.
- **`timeout: 5s`**: Wait up to 5 seconds for the health check command to complete before considering it failed.
- **`retries: 5`**: If the health check fails, retry up to 5 times before marking the container as "unhealthy".
- **`start_period: 40s`**: Give the container 40 seconds to start up before beginning health checks. MongoDB needs time to initialize the database.

**Health Status:**
- **Healthy**: MongoDB is running and accepting connections
- **Unhealthy**: MongoDB failed the health check 5 times in a row
- **Starting**: Container is in the initial 40-second startup period

You can view the health status with:
```bash
docker-compose ps
# Look for "(healthy)" or "(unhealthy)" next to the container name
```

### Log Rotation Configuration

Logs are managed by two mechanisms:

1. **Application Logs** (in mongodb_logs folder): Mounted volume for MongoDB's own log file
2. **Docker Logs** (automatic rotation): Configured via the `logging` section to prevent disk space issues

**Docker Log Rotation (implemented):**
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "200m"      # Rotate when file reaches 200MB
    max-file: "3"         # Keep 3 most recent rotated files
    labels: "mongodb"
```

This configuration automatically:
- Rotates the Docker container logs when they reach 200MB
- Keeps the 3 most recent log files
- Automatically deletes older logs to save disk space

## Connecting via Command Line

### Using MongoDB Shell (mongosh)

**From inside the container (easiest method):**

First, source your environment variables:

**On Linux/macOS:**
```bash
source ../.env
docker exec -it mongodb-container mongosh -u "$MONGO_ROOT_USER" -p "$MONGO_ROOT_PASSWORD"
```

**On Windows PowerShell (Load from .env file):**

Instead of hardcoding values, load them from your `.env` file using this function:

⚠️ **Note on Script Execution:** If you get a "script execution disabled" error, enable script execution first:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Or run just this script with: `powershell -ExecutionPolicy Bypass -Command "..."`

```powershell
function Load-EnvFile {
    param(
        [string]$Path = ".\mongodb_config\.env"
    )
    
    if (-not (Test-Path $Path)) {
        Write-Error ".env file not found at $Path"
        return
    }
    
    Get-Content $Path | ForEach-Object {
        # Skip empty lines and comments
        if ($_ -match '^\s*([^=]+)=(.*)$' -and -not $_.StartsWith('#')) {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [System.Environment]::SetEnvironmentVariable($name, $value, 'Process')
            Write-Host "✓ Loaded: $name" -ForegroundColor Green
        }
    }
}

# Load the environment variables from .env file
Load-EnvFile

# Now connect using the loaded variables
docker exec -it mongodb-container mongosh -u $env:MONGO_ROOT_USER -p $env:MONGO_ROOT_PASSWORD
```

Add this function to your PowerShell profile for reusability, or paste it into your terminal before connecting.

**Alternative: Quick One-Liner:**

If you prefer not to use a function:

```powershell
Get-Content .\mongodb_config\.env | ForEach-Object { if ($_ -match '^\s*([^=]+)=(.*)$') { [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process') } }; docker exec -it mongodb-container mongosh -u $env:MONGO_ROOT_USER -p $env:MONGO_ROOT_PASSWORD
```

**On Windows Command Prompt:**
```cmd
setlocal enabledelayedexpansion
for /f "tokens=*" %%i in (.\mongodb_config\.env) do set %%i
docker exec -it mongodb-container mongosh -u !MONGO_ROOT_USER! -p !MONGO_ROOT_PASSWORD!
```

**Once connected, you can run MongoDB commands:**

```javascript
// List databases
show databases

// Switch to your database
use myapp

// List collections
show collections

// Insert a document
db.users.insertOne({ name: "John", email: "john@example.com" })

// Find documents
db.users.find()

// Exit
exit
```

### Installing mongosh Locally (Optional)

To connect from your host machine without `docker exec`:

**Windows:**
1. Download from [MongoDB Shell Releases](https://www.mongodb.com/try/download/shell)
2. Extract the executable
3. Add to your PATH or run directly

Alternatively, if you have WSL2, you can use the Linux installation method.

**macOS:**
```bash
brew install mongosh
```

**Linux:**
```bash
curl https://downloads.mongodb.com/compass/mongosh-latest-linux-x64.tgz | tar -xz
# Move the mongosh binary to your PATH
```

Then connect from your local machine:

**On Linux/macOS:**
```bash
mongosh "mongodb://$MONGO_ROOT_USER:$MONGO_ROOT_PASSWORD@localhost:27017/myapp?authSource=admin"
```

**On Windows (set environment variables first):**
```powershell
mongosh "mongodb://$env:MONGO_ROOT_USER`:$env:MONGO_ROOT_PASSWORD@localhost:27017/myapp?authSource=admin"
```

## Connecting from Python

### Prerequisites

We recommend using a Python virtual environment to isolate dependencies. See [virtualpy.sh](../../bash/virtualpy.sh) for instructions on creating and managing virtual environments.

### Installation

```bash
pip install pymongo python-dotenv
```

### Basic Connection Example

Create a `.env` file in your Python project root with:

```env
MONGO_ROOT_USER=admin
MONGO_ROOT_PASSWORD=SecurePassword123!
MONGO_HOST=localhost
MONGO_PORT=27017
MONGO_DB_NAME=myapp
```

Then use environment variable substitution in your code:

```python
import os
from dotenv import load_dotenv
from pymongo import MongoClient
from pymongo.errors import ServerSelectionTimeoutError

# Load environment variables from .env file
load_dotenv()

# Configuration from environment variables
MONGO_ROOT_USER = os.getenv('MONGO_ROOT_USER')
MONGO_ROOT_PASSWORD = os.getenv('MONGO_ROOT_PASSWORD')
MONGO_HOST = os.getenv('MONGO_HOST', 'localhost')
MONGO_PORT = os.getenv('MONGO_PORT', '27017')
MONGO_DB_NAME = os.getenv('MONGO_DB_NAME')

# Build connection string
MONGO_URI = f"mongodb://{MONGO_ROOT_USER}:{MONGO_ROOT_PASSWORD}@{MONGO_HOST}:{MONGO_PORT}/{MONGO_DB_NAME}?authSource=admin"

try:
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    # Verify connection
    client.admin.command('ping')
    print("✓ Connected to MongoDB!")
    
    # Access database
    db = client[MONGO_DB_NAME]
    
    # Access collection
    users = db.users
    
    # Insert a document
    result = users.insert_one({
        "name": "Alice",
        "email": "alice@example.com",
        "age": 28
    })
    print(f"Inserted document ID: {result.inserted_id}")
    
    # Find documents
    user = users.find_one({"name": "Alice"})
    print(f"Found user: {user}")
    
    # Find multiple documents
    all_users = users.find()
    for user in all_users:
        print(user)
    
except ServerSelectionTimeoutError as e:
    print(f"✗ Failed to connect: {e}")
    print("   Make sure MongoDB container is running: docker-compose up -d")
finally:
    client.close()
```

### Complete Example Script

A full example script with insert, query, update, and delete operations is provided in [mongodb_example.py](./mongodb_example.py). Run it with:

```bash
python mongodb_example.py
```

Make sure your `.env` file is in the same directory as the script.

## Persistent Storage Configuration

### Current Setup

The data volumes are mounted in the `mongodb/` subfolder:

```yaml
volumes:
  - ./mongodb/mongodb_data:/data/db           # Database files
  - ./mongodb/mongodb_config:/data/configdb   # Configuration files
  - ./mongodb/mongodb_logs:/var/log/mongodb   # Log files
```

### MongoDB Configuration Files

Example MongoDB configuration files are provided in the `mongodb_config/` folder:

- **`mongod.conf.example`**: Full reference of available MongoDB configuration options
- **`mongod.conf.template`**: A template you can customize for your setup

To use a custom MongoDB configuration file:

1. Copy the template to `mongod.conf`:
   ```bash
   cp ./mongodb_config/mongod.conf.template ./mongodb_config/mongod.conf
   ```

2. Edit `mongod.conf` with your desired settings

3. Mount and use it in `docker-compose.yml`:
   ```yaml
   volumes:
     - ./mongodb/mongodb_config/mongod.conf:/etc/mongod.conf
   
   command: --config /etc/mongod.conf
   ```

4. Restart the container:
   ```bash
   docker-compose restart mongodb
   ```

### Folder Structure

```
docker/
├── docker-compose.yml (references ./mongodb/mongodb_config/.env)
└── mongodb/
    ├── .env.example
    ├── .gitignore
    ├── MONGODB_SETUP.md (this file)
    ├── mongodb_example.py
    ├── mongodb_data/           # Database persistence
    ├── mongodb_config/         # Configuration folder
    │   ├── .env (created by setup scripts, not in git)
    │   ├── mongod.conf.example
    │   └── mongod.conf.template
    ├── mongodb_logs/           # Log files
    └── scripts/                # Setup scripts
        ├── setup-env.ps1       # Windows setup script
        └── setup-env.sh        # Linux/macOS setup script
```

### Changing the Storage Path

To use a different location on your host machine:

1. **Open `docker-compose.yml`**

2. **Find the volumes section** and update the paths:

```yaml
volumes:
  - ./mongodb/mongodb_data:/data/db
  - ./mongodb/mongodb_config:/data/configdb
  - ./mongodb/mongodb_logs:/var/log/mongodb
```

3. **Replace paths as needed:**

**Examples:**

```yaml
# Using absolute path on Windows
- C:\MongoDB\data:/data/db
- C:\MongoDB\config:/data/configdb
- C:\MongoDB\logs:/var/log/mongodb

# Using absolute path on macOS/Linux
- /home/user/mongodb_data:/data/db
- /home/user/mongodb_config:/data/configdb
- /home/user/mongodb_logs:/var/log/mongodb

# Using relative path with different name
- ./data/mongo/db:/data/db
- ./data/mongo/config:/data/configdb
- ./data/mongo/logs:/var/log/mongodb
```

4. **Restart the container:**

```bash
docker-compose down
docker-compose up -d
```

⚠️ **Important:** Ensure the folder exists or Docker will create it. The folder must have proper read/write permissions.

### Verify Storage is Working

Check that data persists:

1. Insert data in MongoDB
2. Stop the container: `docker-compose down`
3. Start it again: `docker-compose up -d`
4. Query the data - it should still be there!

## MongoDB Logs

### Log Files Overview

There are two types of logs to be aware of:

1. **Docker Container Logs** - stdout/stderr output from the container as a whole
2. **MongoDB Application Logs** - MongoDB's own `mongod.log` file

### Docker Container Logs (Already Rotating)

Location varies by OS:
- **Linux**: `/var/lib/docker/containers/<container-id>/<container-id>-json.log`
- **Windows/macOS**: Managed by Docker Desktop (not directly accessible)

**Current rotation configuration:**
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "200m"      # Rotates when file reaches 200MB
    max-file: "3"         # Keeps 3 most recent files
    labels: "mongodb"
```

View Docker container logs:
```bash
docker-compose logs mongodb
docker-compose logs -f mongodb  # Follow in real-time
```

### MongoDB Application Logs

MongoDB logs are written to:
- **In container**: `/var/log/mongodb/mongod.log`
- **On host (mounted)**: `./mongodb/mongodb_logs/mongod.log`

**Current configuration:**
- Logs are appended (not overwritten) via `--logappend` flag in docker-compose.yml
- Stored in a dedicated mounted volume for easy access and backup

### Viewing MongoDB Logs

**From the mounted folder on your host:**
```bash
cat ./mongodb/mongodb_logs/mongod.log
tail -f ./mongodb/mongodb_logs/mongod.log  # Follow in real-time
```

**From inside the running container:**
```bash
docker exec mongodb-container tail -f /var/log/mongodb/mongod.log
```

### Enabling MongoDB Log Rotation

To rotate the MongoDB application log file (not just Docker logs), use MongoDB's configuration:

**Option 1: Enable in mongod.conf (Recommended)**

1. Copy the template to `mongod.conf`:
   ```bash
   cp ./mongodb_config/mongod.conf.template ./mongodb_config/mongod.conf
   ```

2. The template already has log rotation enabled:
   ```yaml
   systemLog:
     destination: file
     path: /var/log/mongodb/mongod.log
     logAppend: true
     logRotate: reopen
   ```

3. Mount the config file in `docker-compose.yml`:
   ```yaml
   volumes:
     - ./mongodb/mongodb_config/mongod.conf:/etc/mongod.conf
   command: --config /etc/mongod.conf
   ```

4. Restart the container:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

**How `logRotate: reopen` works:**
- When the log file is rotated externally (by a tool like Linux `logrotate`), MongoDB detects this
- MongoDB closes and reopens the log file instead of continuing to write to the old file
- This allows external log rotation tools to manage file sizes and retention

**Option 2: Use Linux logrotate (Host-based)**

On Linux hosts, you can use the native `logrotate` utility:

1. Create `/etc/logrotate.d/mongodb-docker`:
   ```
   /path/to/mongodb_logs/mongod.log {
       daily
       rotate 7
       compress
       delaycompress
       notifempty
       create 0640 mongodb mongodb
       postrotate
           docker exec mongodb-container /bin/sh -c 'kill -SIGUSR1 $(pidof mongod)' || true
       endscript
   }
   ```

2. Test the configuration:
   ```bash
   sudo logrotate -v /etc/logrotate.d/mongodb-docker
   ```

### Log Rotation Strategy

**Summary of current setup:**

| Log Type | Location | Rotation | Size Limit | Files Kept |
|----------|----------|----------|-----------|-----------|
| Docker logs | `/var/lib/docker/containers/` | Automatic | 200MB | 3 |
| MongoDB logs | `./mongodb/mongodb_logs/` | Manual (via config) | Unlimited | Unlimited |

**Recommendation:**
- For production: Use mongod.conf with log rotation
- For development: Current Docker rotation is sufficient
- Periodically clean old logs: `rm ./mongodb/mongodb_logs/mongod.log*`

## Container Management

### Stop the Container

```bash
docker-compose down
```

### View Logs

```bash
docker-compose logs mongodb
```

### Real-time Logs

```bash
docker-compose logs -f mongodb
```

### Remove Everything (including data)

⚠️ **Warning:** Docker's `-v` flag only removes named volumes, NOT bind mounts (your data folders). To completely clean up:

**Step 1: Stop and remove containers**
```bash
docker-compose down
```

**Step 2: Remove persistent data folders**

**On Windows PowerShell:**
```powershell
Remove-Item -Recurse -Force .\mongodb_data, .\mongodb_logs
Remove-Item -Force .\mongodb_config\.env
```

**On Linux/macOS:**
```bash
rm -rf ./mongodb_data ./mongodb_logs
rm -f ./mongodb_config/.env
```

**Alternative (removes everything including containers):**
```bash
docker-compose down -v
rm -rf ./mongodb_data ./mongodb_logs ./mongodb_config/.env  # Linux/macOS
# or
Remove-Item -Recurse -Force .\mongodb_data, .\mongodb_logs; Remove-Item -Force .\mongodb_config\.env  # PowerShell
```

### Access Container Shell

```bash
docker exec -it mongodb-container bash
```

## Environment Variables Reference

Create your `.env` file based on `.env.example`. Update these variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `MONGO_ROOT_USER` | (required) | Root username |
| `MONGO_ROOT_PASSWORD` | (required) | Root password (change from default!) |
| `MONGO_DB_NAME` | (required) | Default database name |

## Security Best Practices

✅ **Do:**

- Change the default password immediately in `.env`
- Keep `.env` out of version control (it's in `.gitignore`)
- Use strong passwords (mix of upper/lowercase, numbers, symbols)
- Bind MongoDB to localhost only in development (already configured)
- Use different credentials for different environments (dev, staging, production)
- Regularly backup your data in `mongodb/mongodb_data/`
- Monitor logs in `mongodb/mongodb_logs/` for suspicious activity

❌ **Don't:**

- Commit `.env` files to git
- Use default or simple passwords in any environment
- Expose MongoDB port (27017) to the internet
- Store credentials in code or comments
- Skip environment variable substitution in connection strings

## Troubleshooting

### Docker daemon is not running

**Error:** `"The system cannot find the file specified" error during docker-compose up: This error may indicate the docker daemon is not running`

**Solution:**

**On Windows:**
- Start Docker Desktop from the Start Menu
- Wait for it to fully initialize (3-5 minutes) before running docker commands
- Verify it's running by checking the system tray icon
- Test with: `docker ps`

**On Linux:**
```bash
sudo systemctl start docker
# OR
sudo service docker start
```

**On macOS:**
- Open Applications > Docker.app
- Wait for the menu bar icon to show (whale icon is active when running)
- Test with: `docker ps`

**If docker still doesn't work:**
```bash
# Check docker service status
docker info

# Restart docker service (Linux)
sudo systemctl restart docker

# Restart docker daemon (macOS/Windows)
# Quit Docker.app completely and restart it
```

### Container won't start

```bash
docker-compose down
docker-compose up -d --build
docker-compose logs mongodb
```

### Authentication failed

1. Verify environment variables in `.env` match your connection string
2. Ensure `authSource=admin` is in your connection string
3. Check that `MONGO_ROOT_USER` and `MONGO_ROOT_PASSWORD` are set

```bash
docker-compose restart mongodb
```

### Connection timeout from Python

- Verify container is running: `docker-compose ps`
- Check firewall isn't blocking port 27017
- Try connecting from container first:
  ```bash
  docker exec -it mongodb-container mongosh -u $MONGO_ROOT_USER -p $MONGO_ROOT_PASSWORD
  ```
- Check logs for errors: `docker-compose logs mongodb`

### Permission denied on data folder

On Linux/macOS:

```bash
chmod 755 ./mongodb/mongodb_data
chmod 755 ./mongodb/mongodb_config
chmod 755 ./mongodb/mongodb_logs
```

### Port already in use

If port 27017 is taken, change it in `docker-compose.yml`:

```yaml
ports:
  - "27018:27017"  # Use 27018 instead
```

Then update connection strings to use port `27018`.

## Additional Resources

- [MongoDB Docker Documentation](https://hub.docker.com/_/mongo)
- [PyMongo Documentation](https://pymongo.readthedocs.io/)
- [MongoDB Shell (mongosh) Documentation](https://www.mongodb.com/docs/mongodb-shell/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [MongoDB Log Management](https://www.mongodb.com/docs/manual/administration/monitoring/#monitoring-with-logs)
