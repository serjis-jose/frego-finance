package finance

import (
	"frego-finance/internal/repository/finance"
	"frego-finance/internal/storage"
)

// Service handles finance business logic
type Service struct {
	repo     *finance.Repository
	uploader storage.DocumentUploader
}

// New creates a new finance service
func New(repo *finance.Repository, uploader storage.DocumentUploader) *Service {
	return &Service{
		repo:     repo,
		uploader: uploader,
	}
}

// TODO: Add methods for:
// - CreateInvoice
// - ApproveInvoice
// - PostInvoice
// - CreateReceipt
// - AllocateReceipt
// - CreatePayment
// - ProcessPayment
// - GenerateFinancialReports
