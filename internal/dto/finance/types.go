package finance

import (
	"time"

	"github.com/google/uuid"
)

// Invoice represents an AR invoice
type Invoice struct {
	ID                    uuid.UUID     `json:"id"`
	InvoiceNo             string        `json:"invoice_no"`
	InvoiceType           string        `json:"invoice_type"`
	InvoiceDate           time.Time     `json:"invoice_date"`
	CustomerID            uuid.UUID     `json:"customer_id"`
	JobID                 *uuid.UUID    `json:"job_id,omitempty"`
	BillingAddress        *string       `json:"billing_address,omitempty"`
	BillingCountry        *string       `json:"billing_country,omitempty"`
	CurrencyCode          string        `json:"currency_code"`
	ExchangeRate          *float64      `json:"exchange_rate,omitempty"`
	PaymentTermCode       *string       `json:"payment_term_code,omitempty"`
	CustomerPONumber      *string       `json:"customer_po_number,omitempty"`
	CustomerPODate        *time.Time    `json:"customer_po_date,omitempty"`
	SalesExecutiveID      *uuid.UUID    `json:"sales_executive_id,omitempty"`
	SubtotalAmount        *float64      `json:"subtotal_amount,omitempty"`
	TaxAmount             *float64      `json:"tax_amount,omitempty"`
	GrandTotalAmount      *float64      `json:"grand_total_amount,omitempty"`
	AmountInBaseCurrency  *float64      `json:"amount_in_base_currency,omitempty"`
	AdvanceToAdjust       *float64      `json:"advance_to_adjust,omitempty"`
	NetAmountAfterAdvance *float64      `json:"net_amount_after_advance,omitempty"`
	ProfitBaseCurrency    *float64      `json:"profit_base_currency,omitempty"`
	NotesOperations       *string       `json:"notes_operations,omitempty"`
	NotesFinance          *string       `json:"notes_finance,omitempty"`
	SupportingDocuments   *string       `json:"supporting_documents,omitempty"` // JSON
	Remarks               *string       `json:"remarks,omitempty"`
	ApprovalStatus        *string       `json:"approval_status,omitempty"`
	ApprovalRemarks       *string       `json:"approval_remarks,omitempty"`
	InvoiceStatus         *string       `json:"invoice_status,omitempty"`
	GLPostingStatus       *string       `json:"gl_posting_status,omitempty"`
	PostingReferenceNo    *string       `json:"posting_reference_no,omitempty"`
	CreatedBy             *string       `json:"created_by,omitempty"`
	CreatedAt             time.Time     `json:"created_at"`
	LastUpdatedBy         *string       `json:"last_updated_by,omitempty"`
	LastUpdatedAt         *time.Time    `json:"last_updated_at,omitempty"`
	ApprovedBy            *string       `json:"approved_by,omitempty"`
	ApprovedAt            *time.Time    `json:"approved_at,omitempty"`
	PostedBy              *string       `json:"posted_by,omitempty"`
	PostedAt              *time.Time    `json:"posted_at,omitempty"`
	IsActive              bool          `json:"is_active"`
	Lines                 []InvoiceLine `json:"lines,omitempty"`
}

// InvoiceLine represents an invoice line item
type InvoiceLine struct {
	ID               uuid.UUID  `json:"id"`
	InvoiceID        uuid.UUID  `json:"invoice_id"`
	LineNo           int        `json:"line_no"`
	InvoiceTypeCode  *string    `json:"invoice_type_code,omitempty"`
	ItemDescription  string     `json:"item_description"`
	ItemCode         *string    `json:"item_code,omitempty"`
	Quantity         *float64   `json:"quantity,omitempty"`
	UnitPrice        *float64   `json:"unit_price,omitempty"`
	AmountWithoutTax *float64   `json:"amount_without_tax,omitempty"`
	TaxCodeID        *uuid.UUID `json:"tax_code_id,omitempty"`
	TaxRatePercent   *float64   `json:"tax_rate_percent,omitempty"`
	TaxAmount        *float64   `json:"tax_amount,omitempty"`
	LineTotalWithTax *float64   `json:"line_total_with_tax,omitempty"`
	LineNotes        *string    `json:"line_notes,omitempty"`
	CreatedAt        time.Time  `json:"created_at"`
	CreatedBy        *string    `json:"created_by,omitempty"`
	ModifiedAt       *time.Time `json:"modified_at,omitempty"`
	ModifiedBy       *string    `json:"modified_by,omitempty"`
	IsActive         bool       `json:"is_active"`
}

// Receipt represents an AR receipt
type Receipt struct {
	ID                       uuid.UUID           `json:"id"`
	ReceiptNo                string              `json:"receipt_no"`
	ReceiptType              string              `json:"receipt_type"`
	ReceiptDate              time.Time           `json:"receipt_date"`
	CustomerID               uuid.UUID           `json:"customer_id"`
	CurrencyCode             string              `json:"currency_code"`
	ExchangeRate             *float64            `json:"exchange_rate,omitempty"`
	PaymentModeID            *int                `json:"payment_mode_id,omitempty"`
	BankAccountID            *uuid.UUID          `json:"bank_account_id,omitempty"`
	ChequeTxnNo              *string             `json:"cheque_txn_no,omitempty"`
	PaymentDate              *time.Time          `json:"payment_date,omitempty"`
	ReceiptReference         *string             `json:"receipt_reference,omitempty"`
	SupportingDocuments      *string             `json:"supporting_documents,omitempty"` // JSON
	ReceivedAmountCustomer   *float64            `json:"received_amount_customer,omitempty"`
	AmountInBaseCurrency     *float64            `json:"amount_in_base_currency,omitempty"`
	ReceiptPurpose           *string             `json:"receipt_purpose,omitempty"`
	Remarks                  *string             `json:"remarks,omitempty"`
	TotalAllocatedAmount     *float64            `json:"total_allocated_amount,omitempty"`
	UnallocatedAmount        *float64            `json:"unallocated_amount,omitempty"`
	AdvanceCarryForwardFlag  *bool               `json:"advance_carry_forward_flag,omitempty"`
	AdvanceReferenceNo       *string             `json:"advance_reference_no,omitempty"`
	AdvanceAmountCustomer    *float64            `json:"advance_amount_customer,omitempty"`
	AdvanceAmountBase        *float64            `json:"advance_amount_base,omitempty"`
	AdvanceJobOrEnquiry      *string             `json:"advance_job_or_enquiry,omitempty"`
	AdvanceUtilizationStatus *string             `json:"advance_utilization_status,omitempty"`
	AdvanceUtilizationRef    *string             `json:"advance_utilization_ref,omitempty"`
	AdvanceUtilizedAmount    *float64            `json:"advance_utilized_amount,omitempty"`
	AdvanceBalanceAmount     *float64            `json:"advance_balance_amount,omitempty"`
	ApprovalStatus           *string             `json:"approval_status,omitempty"`
	ApprovalRemarks          *string             `json:"approval_remarks,omitempty"`
	GLPostingStatus          *string             `json:"gl_posting_status,omitempty"`
	PostingReferenceNo       *string             `json:"posting_reference_no,omitempty"`
	CreatedBy                *string             `json:"created_by,omitempty"`
	CreatedAt                time.Time           `json:"created_at"`
	LastUpdatedBy            *string             `json:"last_updated_by,omitempty"`
	LastUpdatedAt            *time.Time          `json:"last_updated_at,omitempty"`
	ApprovedBy               *string             `json:"approved_by,omitempty"`
	ApprovedAt               *time.Time          `json:"approved_at,omitempty"`
	PostedBy                 *string             `json:"posted_by,omitempty"`
	PostedAt                 *time.Time          `json:"posted_at,omitempty"`
	IsActive                 bool                `json:"is_active"`
	Allocations              []ReceiptAllocation `json:"allocations,omitempty"`
}

// ReceiptAllocation represents invoice allocation for a receipt
type ReceiptAllocation struct {
	ID                  uuid.UUID  `json:"id"`
	ReceiptID           uuid.UUID  `json:"receipt_id"`
	LineNo              int        `json:"line_no"`
	InvoiceID           *uuid.UUID `json:"invoice_id,omitempty"`
	InvoiceNoSnapshot   *string    `json:"invoice_no_snapshot,omitempty"`
	InvoiceDateSnapshot *time.Time `json:"invoice_date_snapshot,omitempty"`
	InvoiceAmount       *float64   `json:"invoice_amount,omitempty"`
	OutstandingAmount   *float64   `json:"outstanding_amount,omitempty"`
	AllocatedAmount     *float64   `json:"allocated_amount,omitempty"`
	CreatedAt           time.Time  `json:"created_at"`
	CreatedBy           *string    `json:"created_by,omitempty"`
	ModifiedAt          *time.Time `json:"modified_at,omitempty"`
	ModifiedBy          *string    `json:"modified_by,omitempty"`
	IsActive            bool       `json:"is_active"`
}

// VendorInvoice represents an AP vendor invoice
type VendorInvoice struct {
	ID                        uuid.UUID           `json:"id"`
	VendorInvoiceNo           string              `json:"vendor_invoice_no"`
	SystemInvoiceNo           string              `json:"system_invoice_no"`
	VendorID                  uuid.UUID           `json:"vendor_id"`
	InvoiceDate               time.Time           `json:"invoice_date"`
	DueDate                   *time.Time          `json:"due_date,omitempty"`
	PaymentTermCode           *string             `json:"payment_term_code,omitempty"`
	InvoiceType               *string             `json:"invoice_type,omitempty"`
	JobID                     *uuid.UUID          `json:"job_id,omitempty"`
	DepartmentCostCenterCode  *string             `json:"department_cost_center_code,omitempty"`
	CostHeadGLAccountID       *uuid.UUID          `json:"cost_head_gl_account_id,omitempty"`
	AssetCategoryCode         *string             `json:"asset_category_code,omitempty"`
	CurrencyCode              string              `json:"currency_code"`
	ExchangeRate              *float64            `json:"exchange_rate,omitempty"`
	SubtotalAmount            *float64            `json:"subtotal_amount,omitempty"`
	TaxAmount                 *float64            `json:"tax_amount,omitempty"`
	TotalAmount               *float64            `json:"total_amount,omitempty"`
	AmountBaseCurrency        *float64            `json:"amount_base_currency,omitempty"`
	ProvisionAmount           *float64            `json:"provision_amount,omitempty"`
	ProvisionDifference       *float64            `json:"provision_difference,omitempty"`
	NotesOperations           *string             `json:"notes_operations,omitempty"`
	VendorSupportingDocuments *string             `json:"vendor_supporting_documents,omitempty"` // JSON
	InternalComments          *string             `json:"internal_comments,omitempty"`
	ApprovalStatus            *string             `json:"approval_status,omitempty"`
	ApprovalRemarks           *string             `json:"approval_remarks,omitempty"`
	ReversalReference         *string             `json:"reversal_reference,omitempty"`
	InvoiceStatus             *string             `json:"invoice_status,omitempty"`
	GLPostingReference        *string             `json:"gl_posting_reference,omitempty"`
	GLPostingStatus           *string             `json:"gl_posting_status,omitempty"`
	CreatedBy                 *string             `json:"created_by,omitempty"`
	CreatedAt                 time.Time           `json:"created_at"`
	LastUpdatedBy             *string             `json:"last_updated_by,omitempty"`
	LastUpdatedAt             *time.Time          `json:"last_updated_at,omitempty"`
	ApprovedBy                *string             `json:"approved_by,omitempty"`
	ApprovedAt                *time.Time          `json:"approved_at,omitempty"`
	PostedBy                  *string             `json:"posted_by,omitempty"`
	PostedAt                  *time.Time          `json:"posted_at,omitempty"`
	IsActive                  bool                `json:"is_active"`
	Lines                     []VendorInvoiceLine `json:"lines,omitempty"`
}

// VendorInvoiceLine represents a vendor invoice line
type VendorInvoiceLine struct {
	ID                 uuid.UUID  `json:"id"`
	VendorInvoiceID    uuid.UUID  `json:"vendor_invoice_id"`
	LineNo             int        `json:"line_no"`
	OpsProvisionID     *uuid.UUID `json:"ops_provision_id,omitempty"`
	ItemDescription    string     `json:"item_description"`
	Quantity           *float64   `json:"quantity,omitempty"`
	UnitPrice          *float64   `json:"unit_price,omitempty"`
	DiscountAmount     *float64   `json:"discount_amount,omitempty"`
	TaxCodeID          *uuid.UUID `json:"tax_code_id,omitempty"`
	TaxRatePercent     *float64   `json:"tax_rate_percent,omitempty"`
	TaxAmount          *float64   `json:"tax_amount,omitempty"`
	LineAmount         *float64   `json:"line_amount,omitempty"`
	ExpenseGLAccountID *uuid.UUID `json:"expense_gl_account_id,omitempty"`
	LineNotes          *string    `json:"line_notes,omitempty"`
	CreatedAt          time.Time  `json:"created_at"`
	CreatedBy          *string    `json:"created_by,omitempty"`
	ModifiedAt         *time.Time `json:"modified_at,omitempty"`
	ModifiedBy         *string    `json:"modified_by,omitempty"`
	IsActive           bool       `json:"is_active"`
}

// JournalEntry represents a journal entry header
type JournalEntry struct {
	ID                 uuid.UUID     `json:"id"`
	JournalNo          string        `json:"journal_no"`
	JournalDate        time.Time     `json:"journal_date"`
	Description        *string       `json:"description,omitempty"`
	SourceModule       *string       `json:"source_module,omitempty"`
	SourceDocumentType *string       `json:"source_document_type,omitempty"`
	SourceDocumentID   *uuid.UUID    `json:"source_document_id,omitempty"`
	CurrencyCode       *string       `json:"currency_code,omitempty"`
	ExchangeRate       *float64      `json:"exchange_rate,omitempty"`
	TotalDebit         *float64      `json:"total_debit,omitempty"`
	TotalCredit        *float64      `json:"total_credit,omitempty"`
	Status             *string       `json:"status,omitempty"`
	PostedAt           *time.Time    `json:"posted_at,omitempty"`
	PostedBy           *string       `json:"posted_by,omitempty"`
	CreatedAt          time.Time     `json:"created_at"`
	CreatedBy          *string       `json:"created_by,omitempty"`
	ModifiedAt         *time.Time    `json:"modified_at,omitempty"`
	ModifiedBy         *string       `json:"modified_by,omitempty"`
	IsActive           bool          `json:"is_active"`
	Lines              []JournalLine `json:"lines,omitempty"`
}

// JournalLine represents a journal entry line
type JournalLine struct {
	ID           uuid.UUID  `json:"id"`
	HeaderID     uuid.UUID  `json:"header_id"`
	LineNo       int        `json:"line_no"`
	GLAccountID  uuid.UUID  `json:"gl_account_id"`
	PartyID      *uuid.UUID `json:"party_id,omitempty"`
	JobID        *uuid.UUID `json:"job_id,omitempty"`
	BranchID     *uuid.UUID `json:"branch_id,omitempty"`
	DebitAmount  *float64   `json:"debit_amount,omitempty"`
	CreditAmount *float64   `json:"credit_amount,omitempty"`
	Narration    *string    `json:"narration,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
	CreatedBy    *string    `json:"created_by,omitempty"`
	ModifiedAt   *time.Time `json:"modified_at,omitempty"`
	ModifiedBy   *string    `json:"modified_by,omitempty"`
	IsActive     bool       `json:"is_active"`
}
