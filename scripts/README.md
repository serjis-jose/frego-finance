# Scripts Directory

This directory contains deployment and utility scripts for the Finance microservice.

## 🚀 Main Scripts

### **Database & Provisioning**
- **`bootstrap_db.sh`** - Initialize finance database and create provisioning procedure
- **`migrate_to_shared_tenant_db.sh`** - Migrate to shared tenant registry (one-time)
- **`provision_tenant_complete.sh`** - Provision new tenant across all modules
- **`start_postgres.sh`** - Start PostgreSQL container for development

### **Application**
- **`start_service.sh`** - Start finance service locally
- **`compile.sh`** - Compile Go binaries for multiple platforms

### **Docker**
- **`build_docker.sh`** - Build Docker image
- **`docker_compose_up.sh`** - Start all services with docker-compose

---

## 📖 Usage

### Initial Setup
```bash
# 1. Start PostgreSQL
./start_postgres.sh

# 2. Bootstrap database
./bootstrap_db.sh

# 3. Migrate to shared tenant registry (one-time)
./migrate_to_shared_tenant_db.sh

# 4. Provision a tenant
./provision_tenant_complete.sh "Company Name" "email@example.com" "finance"
```

### Development
```bash
# Start service locally
./start_service.sh

# Or use docker-compose
./docker_compose_up.sh
```

### Build & Deploy
```bash
# Compile binaries
./compile.sh

# Build Docker image
./build_docker.sh

# Build and push to registry
REGISTRY=gcr.io/my-project PUSH=true ./build_docker.sh
```

---

## 🔧 Environment Variables

Scripts respect the following environment variables:

### Database URLs
```bash
TENANT_DB_URL=postgres://postgres:postgres@localhost:5432/frego_tenant_db
DB_URL=postgres://postgres:postgres@localhost:5433/frego_finance_db
```

### Docker
```bash
IMAGE_NAME=frego-finance
IMAGE_TAG=latest
PLATFORM=linux/amd64
REGISTRY=gcr.io/my-project
```

---

## 📝 Script Details

### **bootstrap_db.sh**
Initializes the finance database and runs the provisioning script.
- Creates database if not exists
- Runs `db/provision_tenant.sql`
- Verifies tenant_registry table

### **migrate_to_shared_tenant_db.sh**
One-time migration to shared tenant registry architecture.
- Creates `frego_tenant_db`
- Migrates existing tenants
- Updates module subscriptions

### **provision_tenant_complete.sh**
Provisions a new tenant across all services.

**Usage:**
```bash
./provision_tenant_complete.sh <name> [email] [modules]
```

**Examples:**
```bash
# Finance only
./provision_tenant_complete.sh "Acme Corp" "admin@acme.com" "finance"

# Operations + Finance
./provision_tenant_complete.sh "XYZ Ltd" "admin@xyz.com" "operations,finance"
```

### **start_postgres.sh**
Starts PostgreSQL in a Docker container for local development.
- Creates container if not exists
- Starts existing container if stopped
- Waits for PostgreSQL to be ready

### **start_service.sh**
Starts the finance service locally.
- Checks database connectivity
- Generates code if needed
- Builds and runs the service

### **compile.sh**
Compiles Go binaries.

**Build for all platforms:**
```bash
BUILD_ALL_PLATFORMS=true ./compile.sh
```

### **build_docker.sh**
Builds Docker image for the finance service.

**Options:**
```bash
IMAGE_NAME=my-finance IMAGE_TAG=v1.0.0 ./build_docker.sh
```

### **docker_compose_up.sh**
Starts all services using docker-compose.
- Builds images
- Starts PostgreSQL and finance service
- Shows connection information

---

## ⚠️ Notes

- All scripts are **executable** (`chmod +x` already applied)
- Scripts use `set -euo pipefail` for safety
- Verbose output for debugging
- Error handling included

---

## 🆘 Troubleshooting

### Script fails to run
```bash
# Make executable
chmod +x scripts/*.sh

# Check for syntax errors
bash -n scripts/script_name.sh
```

### Database connection issues
```bash
# Verify PostgreSQL is running
docker ps | grep postgres

# Test connection
psql $DB_URL -c "SELECT 1"
```

### Permission denied
```bash
# Run with proper permissions
sudo ./scripts/script_name.sh
```

---

For more information, see:
- **Migration Guide**: `docs/MIGRATION_TO_SHARED_TENANT_DB.md`
- **Quick Reference**: `docs/QUICK_REFERENCE.md`
