#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DB_URL=${DB_URL:-postgres://postgres:postgres@localhost:5433/frego_finance_db}

echo "==> Bootstrapping Finance database"
echo "    Database: ${DB_URL}"

cd "$ROOT_DIR"

# Check if psql is available
if ! command -v psql >/dev/null 2>&1; then
	echo "ERROR: psql command not found. Please install PostgreSQL client." >&2
	exit 1
fi

# Test connection
echo "==> Testing database connection..."
if ! psql "${DB_URL}" -c "SELECT 1" >/dev/null 2>&1; then
	echo "ERROR: Cannot connect to database. Make sure PostgreSQL is running." >&2
	echo "       Run: ./scripts/start_postgres.sh" >&2
	exit 1
fi

echo "==> Running provisioning script..."
psql "${DB_URL}" -f db/provision_tenant.sql

echo "==> Verifying tenant_registry table..."
psql "${DB_URL}" -c "SELECT COUNT(*) as tenant_count FROM tenant_registry;"

echo ""
echo "==> Database bootstrap complete!"
echo ""
echo "==> Next step: Provision a tenant"
echo "    ./scripts/provision_tenant.sh <tenant-uuid> [schema-name]"
