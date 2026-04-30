# Generate Kubernetes Secrets from Environment Variables (PowerShell)
# This script creates secrets.yaml from .env file or environment variables
#
# Usage:
#   .\generate-secrets.ps1
#   .\generate-secrets.ps1 -EnvFile "path/to/.env"

param(
    [Parameter(Mandatory = $false)]
    [string]$EnvFile = ".env"
)

$ErrorActionPreference = "Stop"

# Colors for output
$ColorInfo = "Green"
$ColorWarn = "Yellow"
$ColorError = "Red"

function Write-InfoLog {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $ColorInfo
}

function Write-WarnLog {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor $ColorWarn
}

function Write-ErrorLog {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $ColorError
}

# Load environment variables from .env file if it exists
if (Test-Path $EnvFile) {
    Write-InfoLog "Loading environment variables from $EnvFile"
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            [System.Environment]::SetEnvironmentVariable($key, $value, 'Process')
            Write-InfoLog "Loaded $key from .env file"
        }
    }
} else {
    Write-WarnLog ".env file not found at $EnvFile, using system environment variables"
}

# Function to base64 encode a string
function Convert-ToBase64 {
    param([string]$Text)
    return [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Text))
}

# Get values from environment variables with defaults
$MONGODB_ADMIN_USER = $env:MONGODB_ADMIN_USER
if (-not $MONGODB_ADMIN_USER) { $MONGODB_ADMIN_USER = "admin" }

$MONGODB_ADMIN_PASSWORD = $env:MONGODB_ADMIN_PASSWORD
if (-not $MONGODB_ADMIN_PASSWORD) { $MONGODB_ADMIN_PASSWORD = "change-me" }

$POSTGRES_ADMIN_USER = $env:POSTGRES_ADMIN_USER
if (-not $POSTGRES_ADMIN_USER) { $POSTGRES_ADMIN_USER = "postgres" }

$POSTGRES_ADMIN_PASSWORD = $env:POSTGRES_ADMIN_PASSWORD
if (-not $POSTGRES_ADMIN_PASSWORD) { $POSTGRES_ADMIN_PASSWORD = "change-me" }

$POSTGRES_AIRFLOW_USER = $env:POSTGRES_AIRFLOW_USER
if (-not $POSTGRES_AIRFLOW_USER) { $POSTGRES_AIRFLOW_USER = "airflow" }

$POSTGRES_AIRFLOW_PASSWORD = $env:POSTGRES_AIRFLOW_PASSWORD
if (-not $POSTGRES_AIRFLOW_PASSWORD) { $POSTGRES_AIRFLOW_PASSWORD = "change-me" }

$AIRFLOW_FERNET_KEY = $env:AIRFLOW_FERNET_KEY
if (-not $AIRFLOW_FERNET_KEY) {
    # Generate a new fernet key
    try {
        $AIRFLOW_FERNET_KEY = python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())" 2>$null
        if (-not $AIRFLOW_FERNET_KEY) {
            throw "Python not available"
        }
    } catch {
        Write-WarnLog "Python not available for fernet key generation, using default"
        $AIRFLOW_FERNET_KEY = "change-me"
    }
}

$AIRFLOW_WEBSERVER_SECRET_KEY = $env:AIRFLOW_WEBSERVER_SECRET_KEY
if (-not $AIRFLOW_WEBSERVER_SECRET_KEY) { $AIRFLOW_WEBSERVER_SECRET_KEY = "change-me" }

$AIRFLOW_ADMIN_USER = $env:AIRFLOW_ADMIN_USER
if (-not $AIRFLOW_ADMIN_USER) { $AIRFLOW_ADMIN_USER = "airflow" }

$AIRFLOW_ADMIN_PASSWORD = $env:AIRFLOW_ADMIN_PASSWORD
if (-not $AIRFLOW_ADMIN_PASSWORD) { $AIRFLOW_ADMIN_PASSWORD = "change-me" }

# Construct database URL for Airflow
$AIRFLOW_DATABASE_URL = "postgresql+psycopg2://$POSTGRES_AIRFLOW_USER`:$POSTGRES_AIRFLOW_PASSWORD@postgres:5432/airflow"

# Generate secrets.yaml content
$SecretsContent = @"
---
# MongoDB Credentials Secret
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-credentials
  namespace: trips-ticks
type: Opaque
data:
  admin-user: $(Convert-ToBase64 $MONGODB_ADMIN_USER)
  admin-password: $(Convert-ToBase64 $MONGODB_ADMIN_PASSWORD)
---
# PostgreSQL Credentials Secret
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
  namespace: trips-ticks
type: Opaque
data:
  admin-user: $(Convert-ToBase64 $POSTGRES_ADMIN_USER)
  admin-password: $(Convert-ToBase64 $POSTGRES_ADMIN_PASSWORD)
  airflow-user: $(Convert-ToBase64 $POSTGRES_AIRFLOW_USER)
  airflow-password: $(Convert-ToBase64 $POSTGRES_AIRFLOW_PASSWORD)
---
# Airflow Credentials Secret
apiVersion: v1
kind: Secret
metadata:
  name: airflow-credentials
  namespace: trips-ticks
type: Opaque
data:
  fernet-key: $(Convert-ToBase64 $AIRFLOW_FERNET_KEY)
  webserver-secret-key: $(Convert-ToBase64 $AIRFLOW_WEBSERVER_SECRET_KEY)
  database-url: $(Convert-ToBase64 $AIRFLOW_DATABASE_URL)
  airflow-user: $(Convert-ToBase64 $AIRFLOW_ADMIN_USER)
  airflow-password: $(Convert-ToBase64 $AIRFLOW_ADMIN_PASSWORD)
"@

# Write to secrets.yaml
$SecretsFile = "./manifests/config/secrets.yaml"
Set-Content -Path $SecretsFile -Value $SecretsContent -Encoding UTF8

Write-InfoLog "Generated secrets.yaml successfully"
Write-InfoLog "Location: $SecretsFile"

# Summary
Write-Host ""
Write-Host "Generated secrets summary:" -ForegroundColor Cyan
Write-Host "  MongoDB Admin: $MONGODB_ADMIN_USER / *******" -ForegroundColor White
Write-Host "  PostgreSQL Admin: $POSTGRES_ADMIN_USER / *******" -ForegroundColor White
Write-Host "  PostgreSQL Airflow: $POSTGRES_AIRFLOW_USER / *******" -ForegroundColor White
Write-Host "  Airflow Admin: $AIRFLOW_ADMIN_USER / *******" -ForegroundColor White
Write-Host "  Fernet Key: Generated" -ForegroundColor White