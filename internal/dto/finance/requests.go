package finance

// CreateInvoiceRequest represents a request to create an invoice
type CreateInvoiceRequest struct {
	InvoiceNo        string              `json:"invoice_no" validate:"required"`
	InvoiceType      string              `json:"invoice_type" validate:"required"`
	InvoiceDate      string              `json:"invoice_date" validate:"required"` // ISO 8601 date
	CustomerID       string              `json:"customer_id" validate:"required,uuid"`
	JobID            *string             `json:"job_id,omitempty" validate:"omitempty,uuid"`
	CurrencyCode     string              `json:"currency_code" validate:"required,len=3"`
	ExchangeRate     *float64            `json:"exchange_rate,omitempty"`
	PaymentTermCode  *string             `json:"payment_term_code,omitempty"`
	CustomerPONumber *string             `json:"customer_po_number,omitempty"`
	SalesExecutiveID *string             `json:"sales_executive_id,omitempty" validate:"omitempty,uuid"`
	NotesOperations  *string             `json:"notes_operations,omitempty"`
	NotesFinance     *string             `json:"notes_finance,omitempty"`
	Remarks          *string             `json:"remarks,omitempty"`
	Lines            []CreateInvoiceLine `json:"lines" validate:"required,min=1,dive"`
}

// CreateInvoiceLine represents an invoice line in create request
type CreateInvoiceLine struct {
	LineNo           int      `json:"line_no" validate:"required,min=1"`
	InvoiceTypeCode  *string  `json:"invoice_type_code,omitempty"`
	ItemDescription  string   `json:"item_description" validate:"required"`
	ItemCode         *string  `json:"item_code,omitempty"`
	Quantity         *float64 `json:"quantity,omitempty" validate:"omitempty,gt=0"`
	UnitPrice        *float64 `json:"unit_price,omitempty" validate:"omitempty,gte=0"`
	AmountWithoutTax *float64 `json:"amount_without_tax,omitempty" validate:"omitempty,gte=0"`
	TaxCodeID        *string  `json:"tax_code_id,omitempty" validate:"omitempty,uuid"`
	TaxRatePercent   *float64 `json:"tax_rate_percent,omitempty" validate:"omitempty,gte=0,lte=100"`
	TaxAmount        *float64 `json:"tax_amount,omitempty" validate:"omitempty,gte=0"`
	LineNotes        *string  `json:"line_notes,omitempty"`
}

// CreateReceiptRequest represents a request to create a receipt
type CreateReceiptRequest struct {
	ReceiptNo              string                    `json:"receipt_no" validate:"required"`
	ReceiptType            string                    `json:"receipt_type" validate:"required"`
	ReceiptDate            string                    `json:"receipt_date" validate:"required"` // ISO 8601 date
	CustomerID             string                    `json:"customer_id" validate:"required,uuid"`
	CurrencyCode           string                    `json:"currency_code" validate:"required,len=3"`
	ExchangeRate           *float64                  `json:"exchange_rate,omitempty"`
	PaymentModeID          *int                      `json:"payment_mode_id,omitempty"`
	BankAccountID          *string                   `json:"bank_account_id,omitempty" validate:"omitempty,uuid"`
	ChequeTxnNo            *string                   `json:"cheque_txn_no,omitempty"`
	ReceivedAmountCustomer float64                   `json:"received_amount_customer" validate:"required,gt=0"`
	ReceiptPurpose         *string                   `json:"receipt_purpose,omitempty"`
	Remarks                *string                   `json:"remarks,omitempty"`
	Allocations            []CreateReceiptAllocation `json:"allocations,omitempty" validate:"dive"`
}

// CreateReceiptAllocation represents invoice allocation in create request
type CreateReceiptAllocation struct {
	LineNo          int     `json:"line_no" validate:"required,min=1"`
	InvoiceID       string  `json:"invoice_id" validate:"required,uuid"`
	AllocatedAmount float64 `json:"allocated_amount" validate:"required,gt=0"`
}

// ListInvoicesRequest represents query parameters for listing invoices
type ListInvoicesRequest struct {
	CustomerID *string `json:"customer_id,omitempty" validate:"omitempty,uuid"`
	Status     *string `json:"status,omitempty"`
	FromDate   *string `json:"from_date,omitempty"` // ISO 8601 date
	ToDate     *string `json:"to_date,omitempty"`   // ISO 8601 date
	Limit      int     `json:"limit" validate:"min=1,max=100"`
	Offset     int     `json:"offset" validate:"min=0"`
}

// ListInvoicesResponse represents the response for listing invoices
type ListInvoicesResponse struct {
	Invoices []Invoice `json:"invoices"`
	Total    int       `json:"total"`
	Limit    int       `json:"limit"`
	Offset   int       `json:"offset"`
}

// ListReceiptsRequest represents query parameters for listing receipts
type ListReceiptsRequest struct {
	CustomerID *string `json:"customer_id,omitempty" validate:"omitempty,uuid"`
	FromDate   *string `json:"from_date,omitempty"` // ISO 8601 date
	ToDate     *string `json:"to_date,omitempty"`   // ISO 8601 date
	Limit      int     `json:"limit" validate:"min=1,max=100"`
	Offset     int     `json:"offset" validate:"min=0"`
}

// ListReceiptsResponse represents the response for listing receipts
type ListReceiptsResponse struct {
	Receipts []Receipt `json:"receipts"`
	Total    int       `json:"total"`
	Limit    int       `json:"limit"`
	Offset   int       `json:"offset"`
}

// ApproveInvoiceRequest represents a request to approve an invoice
type ApproveInvoiceRequest struct {
	ApprovalRemarks *string `json:"approval_remarks,omitempty"`
}

// PostInvoiceRequest represents a request to post an invoice to GL
type PostInvoiceRequest struct {
	PostingDate *string `json:"posting_date,omitempty"` // ISO 8601 date
}

// ErrorResponse represents an error response
type ErrorResponse struct {
	Code    string                 `json:"code"`
	Message string                 `json:"message"`
	Details map[string]interface{} `json:"details,omitempty"`
}
