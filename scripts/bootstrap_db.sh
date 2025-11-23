#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DB_FILE=$(cd "$SCRIPT_DIR/.." && pwd)/db/provision_tenant.sql
CONTAINER_DB_FILE=/app/db/provision_tenant.sql

if [ -f "$CONTAINER_DB_FILE" ]; then
  PROVISION_FILE="$CONTAINER_DB_FILE"
else
  PROVISION_FILE="$REPO_DB_FILE"
fi

FINANCE_DB_HOST=${FINANCE_DB_HOST:-postgres-db}
FINANCE_DB_PORT=${FINANCE_DB_PORT:-5432}
FINANCE_DB_NAME=${FINANCE_DB_NAME:-frego_finance_db}
FINANCE_DB_SUPERUSER=${FINANCE_DB_SUPERUSER:-postgres}
FINANCE_DB_SUPERUSER_PASSWORD=${FINANCE_DB_SUPERUSER_PASSWORD:-postgres}
FINANCE_DB_OWNER=${FINANCE_DB_OWNER:-erp_user}

echo "==> Bootstrapping finance database"
echo "    Host:        ${FINANCE_DB_HOST}:${FINANCE_DB_PORT}"
echo "    Database:    ${FINANCE_DB_NAME}"
echo "    Superuser:   ${FINANCE_DB_SUPERUSER}"
echo "    Owner:       ${FINANCE_DB_OWNER}"
echo "    Provisioner: ${PROVISION_FILE}"

if ! command -v psql >/dev/null 2>&1; then
  echo "ERROR: psql command not found. Please install PostgreSQL client utilities." >&2
  exit 1
fi

export PGPASSWORD="${FINANCE_DB_SUPERUSER_PASSWORD}"

if command -v pg_isready >/dev/null 2>&1; then
  until pg_isready -h "${FINANCE_DB_HOST}" -p "${FINANCE_DB_PORT}" -U "${FINANCE_DB_SUPERUSER}" >/dev/null 2>&1; do
    echo "    waiting for Postgres at ${FINANCE_DB_HOST}:${FINANCE_DB_PORT}..."
    sleep 3
  done
else
  echo "    pg_isready not found; skipping readiness check"
fi

echo "==> Ensuring database exists..."
DB_EXISTS=$(
  psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${FINANCE_DB_NAME}'" \
    -h "${FINANCE_DB_HOST}" \
    -p "${FINANCE_DB_PORT}" \
    -U "${FINANCE_DB_SUPERUSER}" \
    -d postgres | tr -d '[:space:]'
)

if [ "${DB_EXISTS}" != "1" ]; then
  echo "    creating database ${FINANCE_DB_NAME} owned by ${FINANCE_DB_OWNER}"
  psql -v ON_ERROR_STOP=1 \
    -h "${FINANCE_DB_HOST}" \
    -p "${FINANCE_DB_PORT}" \
    -U "${FINANCE_DB_SUPERUSER}" \
    -d postgres \
    -c "CREATE DATABASE \"${FINANCE_DB_NAME}\" OWNER \"${FINANCE_DB_OWNER}\""
else
  echo "    database ${FINANCE_DB_NAME} already exists"
fi

if [ ! -f "${PROVISION_FILE}" ]; then
  echo "ERROR: provisioning SQL not found at ${PROVISION_FILE}" >&2
  exit 1
fi

echo "==> Running provisioning script..."
psql -v ON_ERROR_STOP=1 \
  -h "${FINANCE_DB_HOST}" \
  -p "${FINANCE_DB_PORT}" \
  -U "${FINANCE_DB_SUPERUSER}" \
  -d "${FINANCE_DB_NAME}" \
  -f "${PROVISION_FILE}"

echo "==> Verifying tenant_registry entries..."
psql \
  -h "${FINANCE_DB_HOST}" \
  -p "${FINANCE_DB_PORT}" \
  -U "${FINANCE_DB_SUPERUSER}" \
  -d "${FINANCE_DB_NAME}" \
  -c "SELECT COUNT(*) AS tenant_count FROM tenant_registry"

echo "==> Finance database bootstrap complete!"
