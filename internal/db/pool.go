package db

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// NewPool creates a new PostgreSQL connection pool
func NewPool(
	ctx context.Context,
	logger *slog.Logger,
	dbURL string,
	maxOpenConns int,
	maxIdleConns int,
	connMaxLifetime time.Duration,
	preferSimpleProtocol bool,
) (*pgxpool.Pool, error) {
	config, err := pgxpool.ParseConfig(dbURL)
	if err != nil {
		return nil, fmt.Errorf("parse db url: %w", err)
	}

	config.MaxConns = int32(maxOpenConns)
	config.MinConns = int32(maxIdleConns)
	config.MaxConnLifetime = connMaxLifetime
	config.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeExec

	if preferSimpleProtocol {
		config.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	}

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("create pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping database: %w", err)
	}

	logger.Info("database connection pool established",
		slog.Int("max_conns", maxOpenConns),
		slog.Int("min_conns", maxIdleConns),
	)

	return pool, nil
}

// EnsureFinanceTenantProvisioning ensures the finance tenant provisioning procedure exists
func EnsureFinanceTenantProvisioning(ctx context.Context, pool *pgxpool.Pool) error {
	// Check if the procedure exists
	var exists bool
	err := pool.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1 FROM pg_proc 
			WHERE proname = 'ensure_finance_tenant_schema'
		)
	`).Scan(&exists)

	if err != nil {
		return fmt.Errorf("check procedure existence: %w", err)
	}

	if !exists {
		return fmt.Errorf("finance tenant provisioning procedure not found - please run db/provision_tenant.sql")
	}

	return nil
}
