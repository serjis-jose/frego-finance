package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"frego-finance/internal/api"
	"frego-finance/internal/auth"
	"frego-finance/internal/config"
	"frego-finance/internal/db"
	"frego-finance/internal/logging"
	financerepo "frego-finance/internal/repository/finance"
	tenantrepo "frego-finance/internal/repository/tenant"
	"frego-finance/internal/server"
	financeservice "frego-finance/internal/service/finance"
	tenantservice "frego-finance/internal/service/tenant"
	"frego-finance/internal/storage"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/cors"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load(ctx)
	if err != nil {
		slog.Error("failed to load config", slog.Any("error", err))
		os.Exit(1)
	}

	logger := logging.New(cfg.Environment)
	ctx = logging.WithContext(ctx, logger)

	logger.Info("starting frego finance service",
		slog.String("environment", cfg.Environment),
		slog.String("version", "1.0.0"),
	)

	authenticator, err := auth.NewAuthenticator(ctx, auth.Config{
		Issuer:      cfg.Security.KeycloakIssuer,
		Audiences:   cfg.Security.KeycloakAudience,
		TenantClaim: cfg.Security.KeycloakTenantClaim,
	})
	if err != nil {
		logger.Error("failed to init keycloak authenticator", slog.Any("error", err))
		os.Exit(1)
	}

	// Connect to shared tenant registry database
	tenantPool, err := db.NewPool(ctx, logger, cfg.TenantDatabase.URL, cfg.TenantDatabase.MaxOpenConns, cfg.TenantDatabase.MaxIdleConns, cfg.TenantDatabase.ConnMaxLifetime, cfg.TenantDatabase.PreferSimpleProto)
	if err != nil {
		logger.Error("failed to init tenant database", slog.Any("error", err))
		os.Exit(1)
	}
	defer tenantPool.Close()

	// Connect to service-specific finance database
	financePool, err := db.NewPool(ctx, logger, cfg.Database.URL, cfg.Database.MaxOpenConns, cfg.Database.MaxIdleConns, cfg.Database.ConnMaxLifetime, cfg.Database.PreferSimpleProto)
	if err != nil {
		logger.Error("failed to init finance database", slog.Any("error", err))
		os.Exit(1)
	}
	defer financePool.Close()

	if err := db.EnsureFinanceTenantProvisioning(ctx, financePool); err != nil {
		logger.Error("failed to ensure finance tenant provisioning procedure", slog.Any("error", err))
		os.Exit(1)
	}

	// Create tenant session manager with both pools
	tenantSessions := db.NewTenantSessionManager(tenantPool, financePool, "finance")

	var documentUploader storage.DocumentUploader
	if strings.TrimSpace(cfg.Storage.Bucket) == "" || strings.TrimSpace(cfg.Storage.Region) == "" {
		logger.Warn("document storage disabled; missing S3 configuration")
		documentUploader = storage.NewNoopUploader()
	} else {
		uploader, err := storage.NewS3Uploader(ctx, storage.S3Config{
			Bucket:          cfg.Storage.Bucket,
			Region:          cfg.Storage.Region,
			Endpoint:        cfg.Storage.Endpoint,
			AccessKeyID:     cfg.Storage.AccessKeyID,
			SecretAccessKey: cfg.Storage.SecretAccessKey,
			UsePathStyle:    cfg.Storage.UsePathStyle,
			KeyPrefix:       cfg.Storage.KeyPrefix,
		})
		if err != nil {
			logger.Error("failed to init document storage", slog.Any("error", err))
			os.Exit(1)
		}
		documentUploader = uploader
	}

	financeRepo := financerepo.NewWithSessions(tenantSessions)
	financeService := financeservice.New(financeRepo, documentUploader)

	tenantRepo := tenantrepo.New(tenantPool, financePool, cfg.Database.User)
	tenantService := tenantservice.New(tenantRepo)

	financeHandler := api.NewFinanceHandler(logger, financeService, tenantService, cfg.Storage.MaxUploadSize)
	strictServer := api.NewStrictHandler(financeHandler, nil)
	apiHandler := api.HandlerWithOptions(strictServer, api.ChiServerOptions{
		BaseURL: "/finance/api/v1",
		Middlewares: []api.MiddlewareFunc{
			logging.InjectMiddleware(logger),
		},
	})

	// Tenant provisioning handler (for backend-to-finance communication)
	tenantHandler := api.NewTenantHandler(logger, tenantService, cfg.InternalSecret)
	tenantRouter := chi.NewRouter()
	tenantHandler.RegisterRoutes(tenantRouter)

	corsOrigins := append([]string{}, cfg.Security.AllowedOrigins...)
	corsOrigins = append(corsOrigins, "https://dev.myfrego.com", "http://localhost:3000")
	corsMiddleware := cors.Handler(cors.Options{
		AllowedOrigins: corsOrigins,
		AllowedMethods: []string{
			http.MethodGet,
			http.MethodPost,
			http.MethodPut,
			http.MethodPatch,
			http.MethodDelete,
			http.MethodOptions,
		},
		AllowedHeaders: []string{
			"Accept",
			"Authorization",
			"Content-Type",
			"X-Requested-With",
			"X-Tenant-ID",
		},
		AllowCredentials: true,
		MaxAge:           300,
	})

	router := server.BuildRouter(
		logger,
		apiHandler,
		tenantRouter,
		corsMiddleware,
		auth.Middleware(logger, authenticator),
		server.TenantMiddleware(logger, tenantPool, cfg.Security.DefaultTenant),
	)

	httpServer := server.New(logger, cfg.HTTPAddress, router, cfg.GracefulDelay)

	go func() {
		if err := httpServer.Start(ctx); err != nil {
			logger.Error("http server stopped", slog.Any("error", err))
		}
	}()

	<-ctx.Done()
	logger.Info("shutting down gracefully...")

	if err := httpServer.Shutdown(context.Background()); err != nil {
		logger.Error("failed graceful shutdown", slog.Any("error", err))
		os.Exit(1)
	}

	logger.Info("shutdown complete")
}
