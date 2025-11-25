package api

import (
	"context"
	"log/slog"

	"frego-finance/internal/service/finance"
	"frego-finance/internal/service/tenant"
)

// FinanceHandler handles finance API requests
type FinanceHandler struct {
	logger         *slog.Logger
	financeService *finance.Service
	tenantService  *tenant.Service
	maxUploadSize  int64
	internalSecret string
}

// NewFinanceHandler creates a new finance handler
func NewFinanceHandler(
	logger *slog.Logger,
	financeService *finance.Service,
	tenantService *tenant.Service,
	maxUploadSize int64,
	internalSecret string,
) *FinanceHandler {
	return &FinanceHandler{
		logger:         logger,
		financeService: financeService,
		tenantService:  tenantService,
		maxUploadSize:  maxUploadSize,
		internalSecret: internalSecret,
	}
}

// ProvisionTenant provisions finance schema for a tenant
// Note: This endpoint is also handled by tenant_handler.go for internal service calls
// This handler is for OpenAPI-generated routes at /finance/api/v1/tenants/provision
// ProvisionTenant provisions finance schema for a tenant
// Note: This endpoint is also handled by tenant_handler.go for internal service calls
// This handler is for OpenAPI-generated routes at /finance/api/v1/tenants/provision
func (h *FinanceHandler) ProvisionTenant(ctx context.Context, request ProvisionTenantRequestObject) (ProvisionTenantResponseObject, error) {
	// Provisioning is now handled centrally by frego-backend.
	// This endpoint is deprecated and should not be used.
	msg := "provisioning is now handled centrally"
	return ProvisionTenant200JSONResponse{
		Message: &msg,
	}, nil
}

// HealthCheck implements the health check endpoint
func (h *FinanceHandler) HealthCheck(ctx context.Context, request HealthCheckRequestObject) (HealthCheckResponseObject, error) {
	return HealthCheck200TextResponse("OK"), nil
}

// ListInvoices implements the list invoices endpoint
func (h *FinanceHandler) ListInvoices(ctx context.Context, request ListInvoicesRequestObject) (ListInvoicesResponseObject, error) {
	// TODO: Implement
	return ListInvoices200JSONResponse{
		Invoices: &[]Invoice{},
		Total:    new(int),
	}, nil
}

// CreateInvoice implements the create invoice endpoint
func (h *FinanceHandler) CreateInvoice(ctx context.Context, request CreateInvoiceRequestObject) (CreateInvoiceResponseObject, error) {
	// TODO: Implement
	return CreateInvoice201JSONResponse{}, nil
}

// GetInvoice implements the get invoice endpoint
func (h *FinanceHandler) GetInvoice(ctx context.Context, request GetInvoiceRequestObject) (GetInvoiceResponseObject, error) {
	// TODO: Implement
	return GetInvoice200JSONResponse{}, nil
}

// ListReceipts implements the list receipts endpoint
func (h *FinanceHandler) ListReceipts(ctx context.Context, request ListReceiptsRequestObject) (ListReceiptsResponseObject, error) {
	// TODO: Implement
	return ListReceipts200JSONResponse{
		Receipts: &[]Receipt{},
	}, nil
}

// CreateReceipt implements the create receipt endpoint
func (h *FinanceHandler) CreateReceipt(ctx context.Context, request CreateReceiptRequestObject) (CreateReceiptResponseObject, error) {
	// TODO: Implement
	return CreateReceipt201JSONResponse{}, nil
}
