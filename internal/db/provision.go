package db

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sync"

	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	financeProvisionMu      sync.Mutex
	financeProvisionApplied bool

	financeProvisionLoadOnce sync.Once
	financeProvisionSQL      string
	financeProvisionLoadErr  error
)

func loadFinanceProvisionScript() (string, error) {
	financeProvisionLoadOnce.Do(func() {
		candidates := []string{
			filepath.Join("db", "provision_tenant.sql"),
			filepath.Join("..", "db", "provision_tenant.sql"),
			filepath.Join("/", "app", "db", "provision_tenant.sql"),
		}
		for _, candidate := range candidates {
			data, err := os.ReadFile(candidate)
			if err == nil {
				financeProvisionSQL = string(data)
				financeProvisionLoadErr = nil
				return
			}
			financeProvisionLoadErr = err
		}
	})

	if financeProvisionLoadErr != nil {
		return "", fmt.Errorf("load finance provisioning script: %w", financeProvisionLoadErr)
	}
	if financeProvisionSQL == "" {
		return "", fmt.Errorf("finance provisioning script is empty")
	}
	return financeProvisionSQL, nil
}

// EnsureFinanceTenantProvisioning installs the finance tenant provisioning procedure if it is absent.
func EnsureFinanceTenantProvisioning(ctx context.Context, pool *pgxpool.Pool) error {
	financeProvisionMu.Lock()
	defer financeProvisionMu.Unlock()

	if financeProvisionApplied {
		return nil
	}

	script, err := loadFinanceProvisionScript()
	if err != nil {
		return err
	}

	conn, err := pool.Acquire(ctx)
	if err != nil {
		return fmt.Errorf("acquire connection: %w", err)
	}
	defer conn.Release()

	var exists bool
	if err := conn.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1 FROM pg_proc
			WHERE proname = 'ensure_finance_tenant_schema'
		)
	`).Scan(&exists); err != nil {
		return fmt.Errorf("check finance procedure: %w", err)
	}

	if !exists {
		if _, err := conn.Exec(ctx, script); err != nil {
			return fmt.Errorf("execute provisioning script: %w", err)
		}
	}

	financeProvisionApplied = true
	return nil
}
