#!/bin/bash
# Generate Kubernetes Secrets from Environment Variables (Bash)
# This script creates secrets.yaml from .env file or environment variables
#
# Usage:
#   ./generate-secrets.sh
#   ./generate-secrets.sh path/to/.env

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default .env file location
ENV_FILE=".env"
if [ $# -gt 0 ]; then
    ENV_FILE="$1"
fi

# Load environment variables from .env file if it exists
if [ -f "$ENV_FILE" ]; then
    log_info "Loading environment variables from $ENV_FILE"
    set -a
    source "$ENV_FILE"
    set +a
else
    log_warn ".env file not found at $ENV_FILE, using system environment variables"
fi

# Function to base64 encode a string
base64_encode() {
    echo -n "$1" | base64
}

# Get values from environment variables with defaults
MONGODB_ADMIN_USER=${MONGODB_ADMIN_USER:-"admin"}
MONGODB_ADMIN_PASSWORD=${MONGODB_ADMIN_PASSWORD:-"change-me"}

POSTGRES_ADMIN_USER=${POSTGRES_ADMIN_USER:-"postgres"}
POSTGRES_ADMIN_PASSWORD=${POSTGRES_ADMIN_PASSWORD:-"change-me"}
POSTGRES_AIRFLOW_USER=${POSTGRES_AIRFLOW_USER:-"airflow"}
POSTGRES_AIRFLOW_PASSWORD=${POSTGRES_AIRFLOW_PASSWORD:-"change-me"}

# Generate fernet key if not provided
if [ -z "$AIRFLOW_FERNET_KEY" ]; then
    if command -v python3 &> /dev/null; then
        AIRFLOW_FERNET_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
        log_info "Generated new fernet key using python3"
    elif command -v python &> /dev/null; then
        AIRFLOW_FERNET_KEY=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
        log_info "Generated new fernet key using python"
    else
        log_warn "Python not available for fernet key generation, using default"
        AIRFLOW_FERNET_KEY="change-me"
    fi
fi

AIRFLOW_WEBSERVER_SECRET_KEY=${AIRFLOW_WEBSERVER_SECRET_KEY:-"change-me"}
AIRFLOW_ADMIN_USER=${AIRFLOW_ADMIN_USER:-"airflow"}
AIRFLOW_ADMIN_PASSWORD=${AIRFLOW_ADMIN_PASSWORD:-"change-me"}

# Construct database URL for Airflow
AIRFLOW_DATABASE_URL="postgresql+psycopg2://${POSTGRES_AIRFLOW_USER}:${POSTGRES_AIRFLOW_PASSWORD}@postgres:5432/airflow"

# Generate secrets.yaml content
cat > ./manifests/config/secrets.yaml << EOF
---
# MongoDB Credentials Secret
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-credentials
  namespace: trips-ticks
type: Opaque
data:
  admin-user: $(base64_encode "$MONGODB_ADMIN_USER")
  admin-password: $(base64_encode "$MONGODB_ADMIN_PASSWORD")
---
# PostgreSQL Credentials Secret
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
  namespace: trips-ticks
type: Opaque
data:
  admin-user: $(base64_encode "$POSTGRES_ADMIN_USER")
  admin-password: $(base64_encode "$POSTGRES_ADMIN_PASSWORD")
  airflow-user: $(base64_encode "$POSTGRES_AIRFLOW_USER")
  airflow-password: $(base64_encode "$POSTGRES_AIRFLOW_PASSWORD")
---
# Airflow Credentials Secret
apiVersion: v1
kind: Secret
metadata:
  name: airflow-credentials
  namespace: trips-ticks
type: Opaque
data:
  fernet-key: $(base64_encode "$AIRFLOW_FERNET_KEY")
  webserver-secret-key: $(base64_encode "$AIRFLOW_WEBSERVER_SECRET_KEY")
  database-url: $(base64_encode "$AIRFLOW_DATABASE_URL")
  airflow-user: $(base64_encode "$AIRFLOW_ADMIN_USER")
  airflow-password: $(base64_encode "$AIRFLOW_ADMIN_PASSWORD")
EOF

log_info "Generated secrets.yaml successfully"
log_info "Location: ./manifests/config/secrets.yaml"

# Summary
echo ""
echo -e "${GREEN}Generated secrets summary:${NC}"
echo "  MongoDB Admin: $MONGODB_ADMIN_USER / *******"
echo "  PostgreSQL Admin: $POSTGRES_ADMIN_USER / *******"
echo "  PostgreSQL Airflow: $POSTGRES_AIRFLOW_USER / *******"
echo "  Airflow Admin: $AIRFLOW_ADMIN_USER / *******"
echo "  Fernet Key: Generated"