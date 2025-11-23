package api

import (
	"context"
	"log/slog"

	"github.com/google/uuid"

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
func (h *FinanceHandler) ProvisionTenant(ctx context.Context, request ProvisionTenantRequestObject) (ProvisionTenantResponseObject, error) {
	// After code generation, request.Body will be of type *ProvisionTenantJSONRequestBody
	// with fields: TenantId (string/UUID), DisplayName (*string), Actor (*string)

	// TODO: Enforce internal secret check for provisioning requests once tenants service is wired with auth
	if h.internalSecret == "" {
		h.logger.Warn("frego internal secret is missing; skipping provisioning auth check")
	}

	if request.Body == nil {
		return ProvisionTenant400JSONResponse{
			Code:    "INVALID_REQUEST",
			Message: "request body is required",
		}, nil
	}

	tenantID := request.Body.TenantId
	if tenantID == uuid.Nil {
		h.logger.Error("invalid tenant ID", slog.String("tenant_id", tenantID.String()))
		return ProvisionTenant400JSONResponse{
			Code:    "INVALID_TENANT_ID",
			Message: "tenantId is required",
		}, nil
	}

	displayName := ""
	if request.Body.DisplayName != nil {
		displayName = *request.Body.DisplayName
	}

	err := h.tenantService.ProvisionTenant(ctx, tenantID, displayName)
	if err != nil {
		h.logger.Error("failed to provision tenant", slog.Any("error", err))
		return ProvisionTenant500JSONResponse{
			Code:    "PROVISION_FAILED",
			Message: err.Error(),
		}, nil
	}

	// Get the final schema name
	schemaName, _ := h.tenantService.GetTenantSchema(ctx, tenantID)

	msg := "finance schema provisioned successfully"

	return ProvisionTenant200JSONResponse{
		Message:    &msg,
		TenantId:   &tenantID,
		SchemaName: &schemaName,
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
