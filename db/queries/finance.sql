-- name: GetInvoiceByID :one
SELECT * FROM ar_invoice
WHERE id = $1 AND is_active = true;

-- name: ListInvoices :many
SELECT * FROM ar_invoice
WHERE is_active = true
  AND ($1::uuid IS NULL OR customer_id = $1)
  AND ($2::text IS NULL OR invoice_status = $2)
ORDER BY invoice_date DESC, created_at DESC
LIMIT $3 OFFSET $4;

-- name: CreateInvoice :one
INSERT INTO ar_invoice (
  invoice_no,
  invoice_type,
  invoice_date,
  customer_id,
  job_id,
  currency_code,
  exchange_rate,
  subtotal_amount,
  tax_amount,
  grand_total_amount,
  approval_status,
  created_by
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
)
RETURNING *;

-- name: UpdateInvoiceStatus :exec
UPDATE ar_invoice
SET 
  approval_status = $2,
  approval_remarks = $3,
  approved_by = $4,
  approved_at = $5,
  modified_at = now(),
  modified_by = $4
WHERE id = $1;

-- name: GetReceiptByID :one
SELECT * FROM ar_receipt
WHERE id = $1 AND is_active = true;

-- name: ListReceipts :many
SELECT * FROM ar_receipt
WHERE is_active = true
  AND ($1::uuid IS NULL OR customer_id = $1)
ORDER BY receipt_date DESC, created_at DESC
LIMIT $2 OFFSET $3;

-- name: CreateReceipt :one
INSERT INTO ar_receipt (
  receipt_no,
  receipt_type,
  receipt_date,
  customer_id,
  currency_code,
  exchange_rate,
  received_amount_customer,
  amount_in_base_currency,
  approval_status,
  created_by
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10
)
RETURNING *;

-- name: GetVendorInvoiceByID :one
SELECT * FROM ap_vendor_invoice
WHERE id = $1 AND is_active = true;

-- name: ListVendorInvoices :many
SELECT * FROM ap_vendor_invoice
WHERE is_active = true
  AND ($1::uuid IS NULL OR vendor_id = $1)
  AND ($2::text IS NULL OR invoice_status = $2)
ORDER BY invoice_date DESC, created_at DESC
LIMIT $3 OFFSET $4;

-- name: CreateJournalEntry :one
INSERT INTO journal_entry_header (
  je_number,
  je_date,
  description,
  source_module,
  source_document_type,
  source_document_id,
  currency_code,
  exchange_rate,
  total_debit,
  total_credit,
  status,
  created_by
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
)
RETURNING *;

-- name: CreateJournalLine :one
INSERT INTO journal_entry_lines (
  je_id,
  line_no,
  gl_account_id,
  party_id,
  job_id,
  branch_id,
  debit_amount,
  credit_amount,
  narration,
  created_by
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10
)
RETURNING *;

-- name: PostJournalToGL :exec
INSERT INTO general_ledger (
  je_line_id,
  je_id,
  journal_no,
  posting_date,
  journal_description,
  source_module,
  source_document_type,
  source_document_id,
  currency_code,
  exchange_rate,
  journal_status,
  line_no,
  gl_account_id,
  gl_account_code,
  gl_account_name,
  account_group_id,
  account_group_code,
  account_group_name,
  party_id,
  job_id,
  branch_id,
  debit_amount,
  credit_amount,
  line_narration,
  created_by,
  posted_at,
  posted_by
)
SELECT 
  jl.je_line_id,
  jh.je_id,
  jh.je_number,
  jh.je_date,
  jh.description,
  jh.source_module,
  jh.source_document_type,
  jh.source_document_id,
  jh.currency_code,
  jh.exchange_rate,
  jh.status,
  jl.line_no,
  jl.gl_account_id,
  gl.code,
  gl.name,
  gl.account_group_id,
  grp.code,
  grp.name,
  jl.party_id,
  jl.job_id,
  jl.branch_id,
  jl.debit_amount,
  jl.credit_amount,
  jl.narration,
  jh.created_by,
  now(),
  $2
FROM journal_entry_lines jl
JOIN journal_entry_header jh ON jl.je_id = jh.je_id
JOIN gl_account_lu gl ON jl.gl_account_id = gl.id
LEFT JOIN gl_account_group_lu grp ON gl.account_group_id = grp.id
WHERE jh.je_id = $1;
