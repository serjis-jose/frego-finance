# ✅ Deployment Scripts - Complete!

## Scripts Created (Matching frego-backend)

All scripts are now executable and mirror the frego-backend structure:

### 📁 scripts/

| Script | Purpose | Status |
|--------|---------|--------|
| **build_docker.sh** | Build Docker image with platform support | ✅ Complete |
| **docker_compose_up.sh** | Start services with docker-compose | ✅ Complete |
| **start_postgres.sh** | Start PostgreSQL container | ✅ Complete |
| **bootstrap_db.sh** | Initialize database schema | ✅ Complete |
| **start_service.sh** | Start the finance service locally | ✅ Complete |
| **compile.sh** | Compile Go binaries (multi-platform) | ✅ Complete |
| **provision_tenant.sh** | Provision new tenant | ✅ Complete |
| **generate_provision.py** | Generate provision SQL | ✅ Complete |

---

## 🚀 Usage Examples

### 1. Build Docker Image
```bash
./scripts/build_docker.sh

# With custom settings
IMAGE_NAME=my-finance IMAGE_TAG=v1.0.0 ./scripts/build_docker.sh

# Build and push to registry
REGISTRY=gcr.io/my-project PUSH=true ./scripts/build_docker.sh
```

### 2. Start with Docker Compose
```bash
./scripts/docker_compose_up.sh

# View logs
docker compose logs -f

# Stop
docker compose down
```

### 3. Start PostgreSQL Only
```bash
./scripts/start_postgres.sh

# Custom settings
DB_PORT=5434 DB_NAME=my_finance_db ./scripts/start_postgres.sh
```

### 4. Bootstrap Database
```bash
./scripts/bootstrap_db.sh

# With custom DB URL
DB_URL=postgres://user:pass@host:5432/dbname ./scripts/bootstrap_db.sh
```

### 5. Provision Tenant
```bash
./scripts/provision_tenant.sh <tenant-uuid> [schema-name]

# Example
./scripts/provision_tenant.sh 550e8400-e29b-41d4-a716-446655440000 finance_acme
```

### 6. Start Service Locally
```bash
./scripts/start_service.sh

# Service will:
# - Check database connection
# - Generate code if needed
# - Build the application
# - Start the server
```

### 7. Compile Binaries
```bash
./scripts/compile.sh

# Build for all platforms
BUILD_ALL_PLATFORMS=true ./scripts/compile.sh
```

---

## 📊 Comparison with frego-backend

### frego-backend scripts:
```
scripts/
├── bootstrap-db.sh
├── build_docker.sh
├── compile.sh
├── docker_compose_up.sh
├── start_api_server.sh
├── start_backend.sh
└── start_postgres.sh
```

### frego-finance scripts:
```
scripts/
├── bootstrap_db.sh          ✅ (matches bootstrap-db.sh)
├── build_docker.sh          ✅ (matches)
├── compile.sh               ✅ (matches)
├── docker_compose_up.sh     ✅ (matches)
├── provision_tenant.sh      ✅ (finance-specific)
├── start_postgres.sh        ✅ (matches)
├── start_service.sh         ✅ (matches start_backend.sh)
└── generate_provision.py    ✅ (finance-specific)
```

---

## 🎯 All Scripts Are:

✅ **Executable** - chmod +x applied
✅ **Error-handled** - set -euo pipefail
✅ **Documented** - Clear echo messages
✅ **Configurable** - Environment variable support
✅ **Safe** - Checks for required tools
✅ **Production-ready** - Proper error handling

---

## 🔧 Environment Variables Supported

### build_docker.sh
- `IMAGE_NAME` - Docker image name (default: frego-finance)
- `IMAGE_TAG` - Image tag (default: latest)
- `PLATFORM` - Target platform (default: linux/amd64)
- `REGISTRY` - Container registry URL
- `PUSH` - Push to registry (default: false)

### start_postgres.sh
- `POSTGRES_CONTAINER` - Container name (default: frego-finance-db)
- `DB_NAME` - Database name (default: frego_finance_db)
- `DB_USER` - Database user (default: postgres)
- `DB_PASSWORD` - Database password (default: postgres)
- `DB_PORT` - Host port (default: 5433)

### bootstrap_db.sh
- `DB_URL` - PostgreSQL connection string

### start_service.sh
- Uses `.env` file for all configuration
- Falls back to `.env.example` if not found

### compile.sh
- `GO_BIN` - Go binary path (default: go)
- `BUILD_ALL_PLATFORMS` - Build for multiple platforms (default: false)

---

## 📝 Quick Reference

### Complete Setup from Scratch
```bash
# 1. Start PostgreSQL
./scripts/start_postgres.sh

# 2. Bootstrap database
./scripts/bootstrap_db.sh

# 3. Provision a tenant
./scripts/provision_tenant.sh 550e8400-e29b-41d4-a716-446655440000 finance_demo

# 4. Start the service
./scripts/start_service.sh
```

### Docker Workflow
```bash
# Build image
./scripts/build_docker.sh

# Start everything
./scripts/docker_compose_up.sh

# View logs
docker compose logs -f finance-service

# Stop
docker compose down
```

### Development Workflow
```bash
# Compile only
./scripts/compile.sh

# Run directly
./bin/finance-server
```

---

## ✅ Status: Complete!

All deployment scripts matching frego-backend structure have been created and are ready to use.
