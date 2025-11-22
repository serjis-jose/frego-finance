package finance

import (
	"frego-finance/internal/db"
)

// Repository handles finance data access
type Repository struct {
	sessions *db.TenantSessionManager
}

// NewWithSessions creates a new finance repository
func NewWithSessions(sessions *db.TenantSessionManager) *Repository {
	return &Repository{
		sessions: sessions,
	}
}

// TODO: Add methods for:
// - CreateInvoice
// - GetInvoice
// - ListInvoices
// - CreateReceipt
// - GetReceipt
// - ListReceipts
// - CreatePayment
// - GetPayment
// - ListPayments
// - CreateJournalEntry
// - GetJournalEntry
// - PostToGL
