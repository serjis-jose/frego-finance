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
}

// NewFinanceHandler creates a new finance handler
func NewFinanceHandler(
	logger *slog.Logger,
	financeService *finance.Service,
	tenantService *tenant.Service,
	maxUploadSize int64,
) *FinanceHandler {
	return &FinanceHandler{
		logger:         logger,
		financeService: financeService,
		tenantService:  tenantService,
		maxUploadSize:  maxUploadSize,
	}
}

// ProvisionTenant provisions finance schema for a tenant
func (h *FinanceHandler) ProvisionTenant(ctx context.Context, request ProvisionTenantRequestObject) (ProvisionTenantResponseObject, error) {
	tenantID := request.Params.XTenantID
	var schemaName string
	if request.Body != nil && request.Body.SchemaName != nil {
		schemaName = *request.Body.SchemaName
	}

	err := h.tenantService.ProvisionTenant(ctx, tenantID, schemaName)
	if err != nil {
		h.logger.Error("failed to provision tenant", slog.Any("error", err))
		return ProvisionTenant500Response{}, nil
	}

	return ProvisionTenant200Response{}, nil
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
