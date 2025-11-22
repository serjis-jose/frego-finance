#!/usr/bin/env bash
# Complete Setup Script: Provision tenant across shared registry and all services
# Usage: ./provision_tenant_complete.sh <tenant_name> <contact_email> <modules>

set -euo pipefail

TENANT_NAME=${1:-}
CONTACT_EMAIL=${2:-}
MODULES=${3:-"operations,finance"}  # Comma-separated: operations,finance,inventory

TENANT_DB_URL=${TENANT_DB_URL:-postgres://postgres:postgres@localhost:5432/frego_tenant_db}
ERP_DB_URL=${ERP_DB_URL:-postgres://postgres:postgres@localhost:5432/frego_erp_db}
FINANCE_DB_URL=${FINANCE_DB_URL:-postgres://postgres:postgres@localhost:5433/frego_finance_db}

if [ -z "$TENANT_NAME" ]; then
    echo "Usage: $0 <tenant_name> [contact_email] [modules]"
    echo ""
    echo "Examples:"
    echo "  $0 'Acme Corp' 'admin@acme.com' 'operations,finance'"
    echo "  $0 'XYZ Ltd' 'admin@xyz.com' 'finance'"
    exit 1
fi

# Generate tenant ID and slug
TENANT_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
TENANT_SLUG=$(echo "$TENANT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//' | sed 's/_$//')

echo "============================================"
echo "Complete Tenant Provisioning"
echo "============================================"
echo "Tenant Name:    $TENANT_NAME"
echo "Tenant ID:      $TENANT_ID"
echo "Tenant Slug:    $TENANT_SLUG"
echo "Contact Email:  ${CONTACT_EMAIL:-N/A}"
echo "Modules:        $MODULES"
echo "============================================"
echo ""

# Step 1: Register tenant in shared registry
echo "Step 1: Registering tenant in shared registry..."
psql "${TENANT_DB_URL}" <<SQL
CALL register_tenant(
    '${TENANT_ID}'::uuid,
    '${TENANT_SLUG}',
    '${TENANT_NAME}',
    $([ -n "$CONTACT_EMAIL" ] && echo "'${CONTACT_EMAIL}'" || echo "NULL")
);
SQL
echo "  ✓ Tenant registered"

# Step 2: Subscribe to modules and provision
IFS=',' read -ra MODULE_ARRAY <<< "$MODULES"

for module in "${MODULE_ARRAY[@]}"; do
    module=$(echo "$module" | xargs)  # Trim whitespace
    
    case "$module" in
        operations)
            echo ""
            echo "Step 2a: Provisioning Operations module..."
            OPERATIONS_SCHEMA="tenant_${TENANT_SLUG}"
            
            # Subscribe in registry
            psql "${TENANT_DB_URL}" <<SQL
CALL subscribe_tenant_to_module('${TENANT_ID}'::uuid, 'operations', '${OPERATIONS_SCHEMA}');
SQL
            
            # Provision in ERP DB
            if psql "${ERP_DB_URL}" -c "SELECT 1" >/dev/null 2>&1; then
                psql "${ERP_DB_URL}" <<SQL
CALL ensure_party_tenant_schema('${TENANT_ID}'::uuid, '${OPERATIONS_SCHEMA}');
SQL
                
                # Mark as provisioned
                psql "${TENANT_DB_URL}" <<SQL
CALL mark_module_provisioned('${TENANT_ID}'::uuid, 'operations', 'success');
SQL
                echo "  ✓ Operations provisioned: ${OPERATIONS_SCHEMA}"
            else
                echo "  ✗ frego_erp_db not available"
                psql "${TENANT_DB_URL}" <<SQL
CALL mark_module_provisioned('${TENANT_ID}'::uuid, 'operations', 'failed', 'ERP database not available');
SQL
            fi
            ;;
            
        finance)
            echo ""
            echo "Step 2b: Provisioning Finance module..."
            FINANCE_SCHEMA="finance_${TENANT_SLUG}"
            
            # Subscribe in registry
            psql "${TENANT_DB_URL}" <<SQL
CALL subscribe_tenant_to_module('${TENANT_ID}'::uuid, 'finance', '${FINANCE_SCHEMA}');
SQL
            
            # Provision in Finance DB
            if psql "${FINANCE_DB_URL}" -c "SELECT 1" >/dev/null 2>&1; then
                psql "${FINANCE_DB_URL}" <<SQL
CALL ensure_finance_tenant_schema('${TENANT_ID}'::uuid, '${FINANCE_SCHEMA}');
SQL
                
                # Mark as provisioned
                psql "${TENANT_DB_URL}" <<SQL
CALL mark_module_provisioned('${TENANT_ID}'::uuid, 'finance', 'success');
SQL
                echo "  ✓ Finance provisioned: ${FINANCE_SCHEMA}"
            else
                echo "  ✗ frego_finance_db not available"
                psql "${TENANT_DB_URL}" <<SQL
CALL mark_module_provisioned('${TENANT_ID}'::uuid, 'finance', 'failed', 'Finance database not available');
SQL
            fi
            ;;
            
        *)
            echo "  ✗ Unknown module: $module (skipping)"
            ;;
    esac
done

# Step 3: Verify provisioning
echo ""
echo "Step 3: Verifying provisioning..."
echo ""
psql "${TENANT_DB_URL}" <<SQL
SELECT 
    tenant_id,
    tenant_name,
    tenant_slug,
    array_to_string(modules_subscribed, ', ') as modules,
    operations_schema,
    finance_schema,
    is_active
FROM tenant_registry
WHERE tenant_id = '${TENANT_ID}'::uuid;
SQL

echo ""
echo "Provisioning log:"
psql "${TENANT_DB_URL}" <<SQL
SELECT 
    module_name,
    action,
    schema_name,
    status,
    error_message,
    provisioned_at
FROM tenant_module_log
WHERE tenant_id = '${TENANT_ID}'::uuid
ORDER BY provisioned_at;
SQL

echo ""
echo "============================================"
echo "Provisioning Complete!"
echo "============================================"
echo ""
echo "Tenant Details:"
echo "  ID:     $TENANT_ID"
echo "  Slug:   $TENANT_SLUG"
echo "  Modules: $MODULES"
echo ""
echo "Use this tenant ID in your API requests:"
echo "  X-Tenant-ID: $TENANT_ID"
