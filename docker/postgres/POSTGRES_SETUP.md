# PostgreSQL Docker Setup

PostgreSQL container configuration shared by multiple services (Airflow, and others). This document covers basic setup and maintenance.

## Quick Start

### 1. Create Environment Variables File

From the `postgres/` subfolder:

**Windows PowerShell:**
```powershell
.\scripts\setup-env.ps1
```

**Linux/macOS Bash:**
```bash
./scripts/setup-env.sh
```

This creates `.env` in the `postgres_config/` folder with:
- PostgreSQL admin credentials
- Application-specific database credentials (Airflow, etc)

### 2. Start PostgreSQL

From the `docker/` folder:

```bash
docker-compose up -d postgres
```

### 3. Verify PostgreSQL is Running

```bash
docker-compose ps postgres
docker-compose logs postgres
```

Test the connection:

```bash
docker-compose exec postgres psql -U postgres -d postgres -c "SELECT version();"
```

## Configuration

### Admin Credentials

The `POSTGRES_USER` and `POSTGRES_PASSWORD` in `.env` are the superuser credentials. Change these in production:

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password_here
```

### Application-Specific Credentials

Each application that uses PostgreSQL should have its own database and user:

```env
# Airflow
AIRFLOW_DB_USER=airflow
AIRFLOW_DB_PASSWORD=airflow_password
AIRFLOW_DB_NAME=airflow

# Future applications
APP_DB_USER=appuser
APP_DB_PASSWORD=app_password
APP_DB_NAME=app_database
```

## Creating Databases for New Applications

When adding a new service that needs PostgreSQL, follow this pattern:

### 1. Add credentials to `postgres/.env`

```env
MYAPP_DB_USER=myapp
MYAPP_DB_PASSWORD=myapp_secure_password
MYAPP_DB_NAME=myapp_db
```

### 2. Create the database and user

Execute as PostgreSQL superuser:

```bash
docker-compose exec postgres psql -U postgres -c "
CREATE USER myapp WITH ENCRYPTED PASSWORD 'myapp_secure_password';
CREATE DATABASE myapp_db OWNER myapp;
GRANT ALL PRIVILEGES ON DATABASE myapp_db TO myapp;
"
```

Or use the helper script (if available):

```bash
docker-compose exec postgres createuser -U postgres -P myapp
docker-compose exec postgres createdb -U postgres -O myapp myapp_db
```

### 3. Update the service's connection string

In the application's docker-compose environment:

```yaml
environment:
  DATABASE_URL: postgresql://myapp:myapp_secure_password@postgres:5432/myapp_db
```

## Management

### Access PostgreSQL Shell

```bash
# As superuser
docker-compose exec postgres psql -U postgres

# As specific user
docker-compose exec postgres psql -U airflow -d airflow
```

### View Databases

```bash
docker-compose exec postgres psql -U postgres -l
```

### View Users

```bash
docker-compose exec postgres psql -U postgres -c "\du"
```

### Backup and Restore

**Backup a specific database:**

```bash
docker-compose exec postgres pg_dump -U postgres airflow > backup_airflow.sql
```

**Backup all databases:**

```bash
docker-compose exec postgres pg_dumpall -U postgres > backup_all.sql
```

**Restore:**

```bash
docker-compose exec -T postgres psql -U postgres < backup_airflow.sql
```

### View Logs

```bash
docker-compose logs postgres
docker-compose logs -f postgres  # Follow logs
```

### Container Health

PostgreSQL includes a health check in docker-compose.yml:

```bash
docker-compose ps postgres
```

Look for `(healthy)` status.

## Troubleshooting

### PostgreSQL won't start

```bash
# Check logs
docker-compose logs postgres

# Common issues:
# - Password error: Verify credentials in .env
# - Port conflict: Port 5432 already in use
# - Permissions: Check postgres_data folder permissions
```

### Can't connect to PostgreSQL

```bash
# Verify service is running
docker-compose ps postgres

# Test connection
docker-compose exec postgres psql -U postgres -d postgres -c "SELECT 1"

# Check network connectivity
docker-compose exec postgres ping -c 1 localhost
```

### Permission denied on postgres_data

On Linux/macOS:

```bash
chmod 755 ./postgres/postgres_config
chmod 755 ./postgres/postgres_data  # if used
```

### Forgot admin password

Recreate the password by stopping and removing the container, then starting fresh:

```bash
docker-compose down postgres
# Edit .env with new password
docker-compose up -d postgres
```

## Security Best Practices

1. **Change default passwords** in production
2. **Use strong passwords:** At least 16 characters with mixed case, numbers, and symbols
3. **Restrict access:** Use network policies and firewall rules
4. **Backup regularly:** Keep encrypted backups in secure locations
5. **Audit access:** Monitor PostgreSQL logs for suspicious activity
6. **Least privilege:** Give users only necessary permissions
7. **Separate credentials:** Each application gets its own user/password

## Additional Resources

- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL Connection Strings](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)
- [PostgreSQL Security](https://www.postgresql.org/docs/current/sql-security.html)
- [Docker PostgreSQL Image](https://hub.docker.com/_/postgres)
