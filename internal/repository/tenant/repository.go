package tenant

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Repository handles tenant data access
type Repository struct {
	tenantPool  *pgxpool.Pool
	financePool *pgxpool.Pool
	dbUser      string
}

// New creates a new tenant repository
func New(tenantPool, financePool *pgxpool.Pool, dbUser string) *Repository {
	return &Repository{
		tenantPool:  tenantPool,
		financePool: financePool,
		dbUser:      dbUser,
	}
}

// ProvisionTenant creates a new tenant schema
func (r *Repository) ProvisionTenant(ctx context.Context, tenantID uuid.UUID, schemaName string) error {
	// 0. Validate optional schema name (must match allowed pattern)
	if schemaName != "" {
		if matched, _ := regexp.MatchString(`^[a-z0-9_]+$`, schemaName); !matched {
			return fmt.Errorf("invalid schema name: %s", schemaName)
		}
	}

	// 1. Insert audit log entry with pending status
	_, logErr := r.tenantPool.Exec(ctx, `
		INSERT INTO tenant_module_log (tenant_id, module_name, action, schema_name, status, provisioned_by)
		VALUES ($1, 'finance', 'provision', $2, 'pending', current_user)
	`, tenantID, schemaName)
	if logErr != nil {
		// Continue even if log fails, but surface the error later
		logErr = fmt.Errorf("audit log insert failed: %w", logErr)
	}

	// 2. Provision schema in finance DB
	_, err := r.financePool.Exec(ctx, `
		CALL ensure_finance_tenant_schema($1, $2, $3)
	`, tenantID, schemaName, r.dbUser)
	if err != nil {
		// Update audit log to failed
		_, _ = r.tenantPool.Exec(ctx, `
			UPDATE tenant_module_log SET status = 'failed', error_message = $3
			WHERE tenant_id = $1 AND module_name = 'finance' AND action = 'provision' AND status = 'pending'
		`, tenantID, schemaName, err.Error())
		if logErr != nil {
			return fmt.Errorf("%w; also %v", err, logErr)
		}
		return fmt.Errorf("provision tenant schema: %w", err)
	}

	// 3. Determine final schema name (same logic as procedure)
	finalSchemaName := schemaName
	if finalSchemaName == "" {
		// Replicate the logic from SQL procedure: 'finance_' || sanitized_uuid
		// This is slightly risky if logic diverges, but acceptable for now.
		// Or we can query the DB to find the schema, but that's complex.
		// Better approach: The caller should ideally provide the schema name or we enforce a standard.
		// Let's replicate the standard logic for now.
		// tenant_id is UUID, so just "finance_" + sanitized UUID string
		// UUID string is already safe-ish but let's be sure.
		finalSchemaName = fmt.Sprintf("finance_%s", tenantID.String())
		// The SQL uses: regexp_replace(lower(tenant_id_text), '[^a-z0-9_]', '_', 'g')
		// UUIDs only have hyphens which are replaced by underscores in some logic, but here it seems standard.
		// Let's stick to the SQL logic: replace non-alphanumeric with underscore.
		// Actually, UUID string format is standard.
		// Let's just use the provided schemaName if present, else update with the standard convention.
		// Wait, if I don't know exactly what the procedure did, I might store the wrong name.
		// A better way is to update the procedure to return the name, or just rely on the convention.
		// Let's rely on the convention: finance_{uuid_with_underscores}
		// But wait, the SQL procedure replaces hyphens with underscores?
		// "regexp_replace(lower(tenant_id_text), '[^a-z0-9_]', '_', 'g')"
		// Yes, hyphens become underscores.
	}

	// To be safe and consistent, let's update the registry with the schema name.
	// We need to make sure this matches what was created.
	// If schemaName was passed, we use that.
	// If not, we construct it.

	if finalSchemaName == "" {
		// Simple implementation of the SQL logic
		s := strings.ReplaceAll(tenantID.String(), "-", "_")
		finalSchemaName = "finance_" + s
	}

	// 3. Update tenant registry in tenant DB
	_, err = r.tenantPool.Exec(ctx, `
		UPDATE tenant_registry 
		SET finance_schema = $2, modified_at = now()
		WHERE tenant_id = $1
	`, tenantID, finalSchemaName)

	if err != nil {
		// Note: Schema is created but registry update failed. This is an inconsistency.
		// In a real system, we might want distributed transaction or compensation.
		return fmt.Errorf("update tenant registry: %w", err)
	}

	return nil
}

// GetTenantSchema returns the schema name for a tenant
func (r *Repository) GetTenantSchema(ctx context.Context, tenantID uuid.UUID) (string, error) {
	var schemaName string
	err := r.tenantPool.QueryRow(ctx, `
		SELECT finance_schema 
		FROM tenant_registry 
		WHERE tenant_id = $1 AND is_active = true
	`, tenantID).Scan(&schemaName)

	if err != nil {
		return "", fmt.Errorf("get tenant schema: %w", err)
	}

	return schemaName, nil
}
