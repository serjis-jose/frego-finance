BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
--  FINANCE MODULE SCHEMA
-- ============================================================
-- 
-- DESIGN PRINCIPLE: Finance module can operate standalone
-- 
-- External References (Backend Tables):
--   - All references to backend tables (party_master, ops_job, employee_master, branch_lu)
--     are stored as UUID fields WITHOUT foreign key constraints
--   - This allows finance to work independently even if backend tables don't exist
--   - UUID values can be inserted/used without validation against backend tables
--   - Comments indicate which backend table each UUID references
-- 
-- Internal References (Finance Tables):
--   - References within finance module (e.g., ar_invoice, gl_account_lu)
--     use proper foreign key constraints for data integrity
-- 
-- ============================================================
--  CORE LOOKUPS
-- ============================================================

-- Currency lookup (global)
CREATE TABLE IF NOT EXISTS currency_lu (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  code         char(3) NOT NULL UNIQUE,
  name         text,
  created_at   timestamptz,
  created_by   text,
  modified_at  timestamptz,
  modified_by  text,
  is_active    boolean DEFAULT true
);

-- GL account master
CREATE TABLE IF NOT EXISTS gl_account_lu (
  id                 uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  code               text NOT NULL UNIQUE,
  name               text NOT NULL,
  account_type       text,                       -- Asset/Liability/Income/Expense/Equity
  control_account_for text,                     -- 'Customer','Vendor','Bank', etc. (optional)
  currency_code      char(3) REFERENCES currency_lu(code),
  is_active          boolean DEFAULT true,
  created_at         timestamptz DEFAULT now(),
  created_by         text,
  modified_at        timestamptz,
  modified_by        text
);

-- Tax code master
CREATE TABLE IF NOT EXISTS tax_code_lu (
  id             uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  code           text NOT NULL UNIQUE,
  description    text,
  rate_percent   numeric(6,3) NOT NULL,
  is_active      boolean DEFAULT true,
  created_at     timestamptz DEFAULT now(),
  created_by     text,
  modified_at    timestamptz,
  modified_by    text
);

-- Payment method master
CREATE TABLE IF NOT EXISTS payment_method_lu (
  id           smallint PRIMARY KEY,
  code         text NOT NULL UNIQUE,           -- e.g. CASH,BANK_TRANSFER,CHEQUE
  label        text NOT NULL,
  is_active    boolean DEFAULT true,
  created_at   timestamptz DEFAULT now(),
  created_by   text,
  modified_at  timestamptz,
  modified_by  text
);

-- Payment term master (duplicated from Operations for independence)
CREATE TABLE IF NOT EXISTS payment_term_lu (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  code         text UNIQUE,
  name         text UNIQUE,
  days         int,
  created_at   timestamptz,
  created_by   text,
  modified_at  timestamptz,
  modified_by  text,
  is_active    boolean DEFAULT true
);

-- Bank account master
CREATE TABLE IF NOT EXISTS bank_account_lu (
  id               uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  bank_name        text NOT NULL,
  branch_name      text,
  account_number   text NOT NULL,
  iban             text,
  swift_code       text,
  currency_code    char(3) REFERENCES currency_lu(code),
  gl_account_id    uuid REFERENCES gl_account_lu(id),
  is_default       boolean DEFAULT false,
  is_active        boolean DEFAULT true,
  created_at       timestamptz DEFAULT now(),
  created_by       text,
  modified_at      timestamptz,
  modified_by      text
);

-- Invoice type lookup (for AR invoice lines)
CREATE TABLE IF NOT EXISTS invoice_type_lu (
  code        text PRIMARY KEY,        -- e.g. FREIGHT,CUSTOMS,HANDLING
  label       text NOT NULL UNIQUE,
  description text,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  created_by  text,
  modified_at timestamptz,
  modified_by text
);

-- Receipt type lookup (for AR receipts)
CREATE TABLE IF NOT EXISTS receipt_type_lu (
  code        text PRIMARY KEY,        -- e.g. AGAINST_INVOICE, ADVANCE, ON_ACCOUNT
  label       text NOT NULL UNIQUE,
  description text,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  created_by  text,
  modified_at timestamptz,
  modified_by text
);

-- Receipt advance utilization status lookup
CREATE TABLE IF NOT EXISTS receipt_utilization_status_lu (
  code        text PRIMARY KEY,      -- e.g. UNUTILIZED, PARTIAL, FULL
  label       text NOT NULL UNIQUE,
  description text,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  created_by  text,
  modified_at timestamptz,
  modified_by text
);

-- AR credit note reasons
CREATE TABLE IF NOT EXISTS credit_note_reason_lu (
  code        text PRIMARY KEY,      -- e.g. OVERBILLING, DISCOUNT
  label       text NOT NULL UNIQUE,
  description text,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  created_by  text,
  modified_at timestamptz,
  modified_by text
);

-- AP document categories (Job / Non-Job / Asset / Liability / Advance)
CREATE TABLE IF NOT EXISTS ap_invoice_category_lu (
  code        text PRIMARY KEY,
  label       text NOT NULL UNIQUE,
  description text,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  created_by  text,
  modified_at timestamptz,
  modified_by text
);

-- AP payment allocation types (against invoice vs advances)
CREATE TABLE IF NOT EXISTS ap_payment_application_type_lu (
  code        text PRIMARY KEY,
  label       text NOT NULL UNIQUE,
  description text,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  created_by  text,
  modified_at timestamptz,
  modified_by text
);

-- Receiver types for AP direct payments
CREATE TABLE IF NOT EXISTS ap_receiver_type_lu (
  code        text PRIMARY KEY,
  label       text NOT NULL UNIQUE,
  description text,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  created_by  text,
  modified_at timestamptz,
  modified_by text
);

-- Department / cost center lookup (used across AP expenses)
CREATE TABLE IF NOT EXISTS department_cost_center_lu (
  code        text PRIMARY KEY,
  name        text NOT NULL UNIQUE,
  description text,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  created_by  text,
  modified_at timestamptz,
  modified_by text
);

-- Asset category lookup (for asset acquisitions)
CREATE TABLE IF NOT EXISTS asset_category_lu (
  code        text PRIMARY KEY,
  name        text NOT NULL UNIQUE,
  description text,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  created_by  text,
  modified_at timestamptz,
  modified_by text
);

-- AP debit note reasons
CREATE TABLE IF NOT EXISTS ap_debit_note_reason_lu (
  code        text PRIMARY KEY,
  label       text NOT NULL UNIQUE,
  description text,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  created_by  text,
  modified_at timestamptz,
  modified_by text
);


-- Approval status lookup (shared across all finance docs)
-- Values to seed: Draft, Returned, Pending Approval, Approved, Posted
CREATE TABLE IF NOT EXISTS approval_status_lu (
  code        text PRIMARY KEY,        -- 'Draft','Returned','Pending Approval','Approved','Posted'
  description text
);

-- Country lookup (for billing address)
CREATE TABLE IF NOT EXISTS country_lu (
  country_id    serial PRIMARY KEY,
  country_name  text NOT NULL UNIQUE,
  country_code  char(3) NOT NULL UNIQUE,
  created_at    timestamptz DEFAULT now(),
  created_by    text,
  modified_at   timestamptz,
  modified_by   text,
  is_active     boolean DEFAULT true
);

-- Invoice status lookup (for AR and AP invoices)
CREATE TABLE IF NOT EXISTS invoice_status_lu (
  code        text PRIMARY KEY,        -- e.g. UNPAID, PARTIALLY_PAID, FULLY_PAID
  label       text NOT NULL UNIQUE,
  description text,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  created_by  text,
  modified_at timestamptz,
  modified_by text
);

-- GL posting status lookup (shared across all finance docs)
CREATE TABLE IF NOT EXISTS gl_posting_status_lu (
  code        text PRIMARY KEY,        -- e.g. PENDING, POSTED, ERROR
  label       text NOT NULL UNIQUE,
  description text,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  created_by  text,
  modified_at timestamptz,
  modified_by text
);

-- ============================================================
--  LEDGER ENGINE
--  journal_entry_header + journal_entry_lines + general_ledger
-- ============================================================

CREATE TABLE IF NOT EXISTS journal_entry_header (
  je_id                  uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  je_number              text NOT NULL UNIQUE,
  je_date                date NOT NULL,
  document_date          date,            -- Actual document date (invoice date / payment date)
  description            text,
  source_module          text,            -- Module that created this entry (AR_INVOICE / AP_PAYMENT / JV etc.)
  source_id              uuid,            -- Document's primary key (invoice_id, payment_id, etc.)
  source_document_type   text,            -- More granular document classification (e.g. INVOICE/RECEIPT/JV)
  source_document_id     uuid,            -- Explicit reference to the originating document
  currency_code          char(3) REFERENCES currency_lu(code),
  exchange_rate          numeric(12,6),
  total_debit            numeric(14,2),
  total_credit           numeric(14,2),
  status                 text,            -- CREATED (JE generated) / POSTED (GL entries created) / ERROR
  posted_at              timestamptz,
  posted_by              text,
  created_at             timestamptz DEFAULT now(),
  created_by             text,
  modified_at            timestamptz,
  modified_by            text,
  is_active              boolean DEFAULT true,
  
  -- Validation constraints
  CONSTRAINT chk_journal_totals_balance CHECK (
    (total_debit IS NULL AND total_credit IS NULL) OR 
    (total_debit = total_credit)
  ),
  CONSTRAINT chk_journal_debit_non_negative CHECK (total_debit IS NULL OR total_debit >= 0),
  CONSTRAINT chk_journal_credit_non_negative CHECK (total_credit IS NULL OR total_credit >= 0),
  CONSTRAINT chk_journal_totals_non_zero CHECK (
    (total_debit IS NULL AND total_credit IS NULL) OR 
    (total_debit > 0 AND total_credit > 0)
  )
);

CREATE TABLE IF NOT EXISTS journal_entry_lines (
  je_line_id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  je_id              uuid NOT NULL REFERENCES journal_entry_header(je_id) ON DELETE CASCADE,
  line_no            int NOT NULL,
  gl_account_id      uuid NOT NULL REFERENCES gl_account_lu(id),
  gl_account_code    text,            -- Which GL account to debit/credit
  cost_center_code   text,            -- Optional cost center / department
  vendor_id          uuid,            -- Used for AP transactions
  vendor_name        text,            -- Snapshot: party_master.name (for standalone display)
  customer_id        uuid,            -- Used for AR transactions
  customer_name      text,            -- Snapshot: party_master.name (for standalone display)
  job_id             uuid,            -- REFERENCES ops_job(id) -- External: UUID only
  job_no             text,            -- Optional job number for job-based postings
  job_code           text,            -- Snapshot: ops_job.job_code (for standalone display)
  branch_id          uuid,            -- REFERENCES branch_lu(branch_id) -- External: UUID only
  debit_amount       numeric(14,2) DEFAULT 0,
  credit_amount      numeric(14,2) DEFAULT 0,
  narration          text,
  created_at         timestamptz DEFAULT now(),
  created_by         text,
  modified_at        timestamptz,
  modified_by        text,
  is_active          boolean DEFAULT true,

  UNIQUE (je_id, line_no),
  
  -- Validation constraints
  CONSTRAINT chk_line_debit_non_negative CHECK (debit_amount >= 0),
  CONSTRAINT chk_line_credit_non_negative CHECK (credit_amount >= 0),
  CONSTRAINT chk_line_amounts_valid CHECK (
    (debit_amount > 0 AND credit_amount = 0) OR 
    (debit_amount = 0 AND credit_amount > 0)
  )
);

-- ============================================================
--  JOURNAL ENTRY VALIDATION TRIGGERS
-- ============================================================

-- Trigger to prevent modifications to journal entry header after POSTED
CREATE OR REPLACE FUNCTION trg_prevent_je_modification_after_posted()
RETURNS trigger AS $$
BEGIN
  -- Prevent any updates if status is 'POSTED'
  IF OLD.status = 'POSTED' THEN
    RAISE EXCEPTION 'Cannot modify journal entry after it has been POSTED. Journal No: %', OLD.je_number;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_journal_entry_header_prevent_posted_modification ON journal_entry_header;
CREATE TRIGGER trg_journal_entry_header_prevent_posted_modification
BEFORE UPDATE ON journal_entry_header
FOR EACH ROW EXECUTE FUNCTION trg_prevent_je_modification_after_posted();

-- Trigger to prevent modifications to journal entry lines when header is POSTED
CREATE OR REPLACE FUNCTION trg_prevent_je_lines_modification_after_posted()
RETURNS trigger AS $$
DECLARE
  v_status text;
BEGIN
  SELECT status INTO v_status
  FROM journal_entry_header
  WHERE je_id = COALESCE(NEW.je_id, OLD.je_id);
  
  IF v_status = 'POSTED' THEN
    RAISE EXCEPTION 'Cannot modify journal entry lines after journal entry has been POSTED';
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_journal_entry_lines_prevent_posted_modification ON journal_entry_lines;
CREATE TRIGGER trg_journal_entry_lines_prevent_posted_modification
BEFORE INSERT OR UPDATE OR DELETE ON journal_entry_lines
FOR EACH ROW EXECUTE FUNCTION trg_prevent_je_lines_modification_after_posted();

-- Trigger to validate header totals match sum of line totals (when header is updated)
CREATE OR REPLACE FUNCTION trg_validate_journal_header_totals()
RETURNS trigger AS $$
DECLARE
  v_sum_debit  numeric(14,2);
  v_sum_credit numeric(14,2);
BEGIN
  -- Only validate if totals are being set (not NULL)
  IF NEW.total_debit IS NOT NULL AND NEW.total_credit IS NOT NULL THEN
    -- Calculate sum of line totals
    SELECT 
      COALESCE(SUM(debit_amount), 0),
      COALESCE(SUM(credit_amount), 0)
    INTO v_sum_debit, v_sum_credit
    FROM journal_entry_lines
    WHERE je_id = NEW.je_id
      AND is_active = true;
    
    -- Validate: Header total_debit = SUM of line debits
    IF NEW.total_debit != v_sum_debit THEN
      RAISE EXCEPTION 'Header total_debit (%) must equal SUM of line debits (%)', NEW.total_debit, v_sum_debit;
    END IF;
    
    -- Validate: Header total_credit = SUM of line credits
    IF NEW.total_credit != v_sum_credit THEN
      RAISE EXCEPTION 'Header total_credit (%) must equal SUM of line credits (%)', NEW.total_credit, v_sum_credit;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_journal_entry_header_validate_totals ON journal_entry_header;
CREATE TRIGGER trg_journal_entry_header_validate_totals
BEFORE UPDATE ON journal_entry_header
FOR EACH ROW EXECUTE FUNCTION trg_validate_journal_header_totals();

-- Trigger to validate header totals match sum of line totals (when lines are modified)
CREATE OR REPLACE FUNCTION trg_validate_journal_lines_totals()
RETURNS trigger AS $$
DECLARE
  v_sum_debit  numeric(14,2);
  v_sum_credit numeric(14,2);
  v_header_debit numeric(14,2);
  v_header_credit numeric(14,2);
  v_je_id uuid;
BEGIN
  v_je_id := COALESCE(NEW.je_id, OLD.je_id);
  
  -- Get the header totals
  SELECT total_debit, total_credit INTO v_header_debit, v_header_credit
  FROM journal_entry_header
  WHERE je_id = v_je_id;
  
  -- Only validate if header totals are set
  IF v_header_debit IS NOT NULL AND v_header_credit IS NOT NULL THEN
    -- Calculate sum of line totals
    SELECT 
      COALESCE(SUM(debit_amount), 0),
      COALESCE(SUM(credit_amount), 0)
    INTO v_sum_debit, v_sum_credit
    FROM journal_entry_lines
    WHERE je_id = v_je_id
      AND is_active = true;
    
    -- Validate: Header total_debit = SUM of line debits
    IF v_header_debit != v_sum_debit THEN
      RAISE EXCEPTION 'Header total_debit (%) must equal SUM of line debits (%)', v_header_debit, v_sum_debit;
    END IF;
    
    -- Validate: Header total_credit = SUM of line credits
    IF v_header_credit != v_sum_credit THEN
      RAISE EXCEPTION 'Header total_credit (%) must equal SUM of line credits (%)', v_header_credit, v_sum_credit;
    END IF;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_journal_entry_lines_validate_totals ON journal_entry_lines;
CREATE TRIGGER trg_journal_entry_lines_validate_totals
AFTER INSERT OR UPDATE OR DELETE ON journal_entry_lines
FOR EACH ROW EXECUTE FUNCTION trg_validate_journal_lines_totals();

-- Final general ledger postings (populated when documents are posted)
CREATE TABLE IF NOT EXISTS general_ledger (
  gl_entry_id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  je_line_id             uuid,            -- Reference to JE Line
  je_id                  uuid,            -- Reference to JE Header
  posting_date           date,            -- Ledger posting date (same as JE date)
  source_module          text,            -- AR_INVOICE / AP_INVOICE / etc.
  source_id              uuid,            -- The document ID from source module
  source_document_type   text,            -- More granular document classification (e.g. INVOICE/RECEIPT/JV)
  source_document_id     uuid,            -- Explicit reference to the originating document
  currency_code          char(3),         -- Original transaction currency
  exchange_rate          numeric(12,6),   -- FX rate used
  journal_status         text,
  line_no                int,
  gl_account_id          uuid REFERENCES gl_account_lu(id),
  gl_account_code        text,            -- GL account code
  cost_center_code       text,            -- Optional cost center
  vendor_id              uuid,            -- Vendor reference (for AP reporting)
  vendor_name            text,            -- Snapshot: party_master.name (for standalone display)
  customer_id            uuid,            -- Customer reference (for AR reporting)
  customer_name          text,            -- Snapshot: party_master.name (for standalone display)
  job_id                 uuid,
  job_no                 text,            -- Optional job no (if job related)
  job_code               text,            -- Snapshot: ops_job.job_code (for standalone display)
  branch_id              uuid,
  debit_amount           numeric(14,2) DEFAULT 0, -- Debit amount in base currency
  credit_amount          numeric(14,2) DEFAULT 0, -- Credit amount in base currency
  amount_base            numeric(14,2),   -- Amount converted into base currency
  created_at             timestamptz DEFAULT now(), -- Timestamp when GL row was actually inserted
  created_by             text,
  posted_at              timestamptz,     -- Same as created_at (but kept separately for audit)
  posted_by              text,            -- User/system who performed posting
  is_active              boolean DEFAULT true
);

-- ============================================================
--  AR INVOICE (HEADER)
-- ============================================================

CREATE TABLE IF NOT EXISTS ar_invoice (
  id                       uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

  invoice_no               text NOT NULL UNIQUE,
  invoice_type             text NOT NULL REFERENCES invoice_type_lu(code),
  invoice_date             date NOT NULL,
  customer_id              uuid, -- REFERENCES party_master(id) -- External: UUID only (nullable for Finance independence)
  customer_name            text, -- Snapshot: party_master.name (for standalone display)
  job_id                   uuid, -- REFERENCES ops_job(id) -- External: UUID only
  job_code                 text, -- Snapshot: ops_job.job_code (for standalone display)
  billing_address          text,
  billing_country           char(3) REFERENCES country_lu(country_code),
  currency_code            char(3) NOT NULL REFERENCES currency_lu(code),
  exchange_rate            numeric(12,6),
  payment_term_code        text, -- REFERENCES payment_term_lu(code) -- Internal table
  customer_po_number       text,
  customer_po_date         date,
  sales_executive_id       uuid, -- REFERENCES employee_master(id) -- External: UUID only
  sales_executive_name     text, -- Snapshot: employee_master.name (for standalone display)

  subtotal_amount          numeric(14,2),                 -- sum of line amount_without_tax
  tax_amount               numeric(14,2),
  grand_total_amount       numeric(14,2),
  amount_in_base_currency  numeric(14,2),

  advance_to_adjust        numeric(14,2),
  net_amount_after_advance numeric(14,2),
  profit_base_currency     numeric(14,2),

  notes_operations         text,
  notes_finance            text,
  supporting_documents     jsonb,                         -- JSON ARRAY of supporting docs
  remarks                  text,

  approval_status          text REFERENCES approval_status_lu(code),
  approval_remarks         text,
  invoice_status           text REFERENCES invoice_status_lu(code),  -- Unpaid/Partially/Fully Paid
  gl_posting_status        text REFERENCES gl_posting_status_lu(code),  -- Pending/Posted/Error
  posting_reference_no      text,

  created_by               text,
  created_at               timestamptz DEFAULT now(),
  last_updated_by          text,
  last_updated_at          timestamptz,
  approved_by              text,
  approved_at              timestamptz,
  posted_by                text,
  posted_at                timestamptz,
  is_active                boolean DEFAULT true
);

-- ============================================================
--  AR INVOICE LINES
--  NOTE: discount_amount → amount_without_tax (for readability)
-- ============================================================

CREATE TABLE IF NOT EXISTS ar_invoice_line (
  id                   uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  invoice_id           uuid NOT NULL REFERENCES ar_invoice(id) ON DELETE CASCADE,
  line_no              int NOT NULL,

  ops_billing_id       uuid, -- REFERENCES ops_billing(id) -- External: UUID only
  item_code            text,
  item_description     text,
  unit_of_measure      text,
  quantity             numeric(14,3),
  unit_price           numeric(14,2),

  amount_without_tax   numeric(14,2),                     -- line net amount excl. tax
  tax_code_id          uuid REFERENCES tax_code_lu(id),
  tax_rate_percent     numeric(6,3),
  tax_amount           numeric(14,2),
  line_total_with_tax  numeric(14,2),
  line_notes           text,

  created_at           timestamptz DEFAULT now(),
  created_by           text,
  modified_at          timestamptz,
  modified_by          text,
  is_active            boolean DEFAULT true,

  UNIQUE (invoice_id, line_no)
);

-- ============================================================
--  AR RECEIPT (HEADER)
-- ============================================================

CREATE TABLE IF NOT EXISTS ar_receipt (
  id                          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

  receipt_no                  text NOT NULL UNIQUE,
  receipt_type                text NOT NULL REFERENCES receipt_type_lu(code),
  receipt_date                date NOT NULL,
  customer_id                 uuid, -- REFERENCES party_master(id) -- External: UUID only (nullable for Finance independence)
  customer_name               text, -- Snapshot: party_master.name (for standalone display)
  currency_code               char(3) NOT NULL REFERENCES currency_lu(code),
  exchange_rate               numeric(12,6),
  payment_mode_id             smallint REFERENCES payment_method_lu(id),
  bank_account_id             uuid REFERENCES bank_account_lu(id),
  cheque_txn_no               text,
  payment_date                date,
  receipt_reference           text,
  supporting_documents        jsonb,                        -- JSON attachment metadata

  received_amount_customer    numeric(14,2),
  amount_in_base_currency     numeric(14,2),
  receipt_purpose             text,
  remarks                     text,

  total_allocated_amount      numeric(14,2),
  unallocated_amount          numeric(14,2),
  advance_carry_forward_flag  boolean,

  advance_reference_no        text,
  advance_amount_customer     numeric(14,2),
  advance_amount_base         numeric(14,2),
  advance_job_or_enquiry      text,
  advance_utilization_status  text REFERENCES receipt_utilization_status_lu(code),
  advance_utilization_ref     text,
  advance_utilized_amount     numeric(14,2),
  advance_balance_amount      numeric(14,2),

  approval_status             text REFERENCES approval_status_lu(code),
  approval_remarks            text,
  gl_posting_status        text REFERENCES gl_posting_status_lu(code),  -- Pending/Posted/Error
  posting_reference_no        text,

  created_by                  text,
  created_at                  timestamptz DEFAULT now(),
  last_updated_by             text,
  last_updated_at             timestamptz,
  approved_by                 text,
  approved_at                 timestamptz,
  posted_by                   text,
  posted_at                   timestamptz,
  is_active                   boolean DEFAULT true
);

-- ============================================================
--  AR RECEIPT - INVOICE ALLOCATION
-- ============================================================

CREATE TABLE IF NOT EXISTS ar_receipt_invoice_allocation (
  id                    uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  receipt_id            uuid NOT NULL REFERENCES ar_receipt(id) ON DELETE CASCADE,
  line_no               int NOT NULL,

  invoice_id            uuid REFERENCES ar_invoice(id),
  invoice_no_snapshot   text,
  invoice_date_snapshot date,
  invoice_amount        numeric(14,2),
  outstanding_amount    numeric(14,2),
  allocated_amount      numeric(14,2),

  created_at            timestamptz DEFAULT now(),
  created_by            text,
  modified_at           timestamptz,
  modified_by           text,
  is_active             boolean DEFAULT true,

  UNIQUE (receipt_id, line_no)
);

-- ============================================================
--  AR CREDIT NOTE
-- ============================================================

CREATE TABLE IF NOT EXISTS ar_credit_note (
  id                            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

  credit_note_no                text NOT NULL UNIQUE,
  credit_note_date              date NOT NULL,
  customer_id                   uuid, -- REFERENCES party_master(id) -- External: UUID only (nullable for Finance independence)
  customer_name                 text, -- Snapshot: party_master.name (for standalone display)
  invoice_id                    uuid REFERENCES ar_invoice(id),
  currency_code                 char(3) NOT NULL REFERENCES currency_lu(code),
  exchange_rate                 numeric(12,6),

  reason_type                   text REFERENCES credit_note_reason_lu(code),
  description                   text,
  credit_amount_without_tax     numeric(14,2),
  tax_code_id                   uuid REFERENCES tax_code_lu(id),
  tax_amount                    numeric(14,2),
  total_credit_amount_with_tax  numeric(14,2),

  remarks                       text,
  supporting_documents          jsonb,                      -- JSON attachment metadata

  approval_status               text REFERENCES approval_status_lu(code),
  approval_remarks              text,
  gl_posting_status             text REFERENCES gl_posting_status_lu(code),
  posting_reference_no          text,

  created_by                    text,
  created_at                    timestamptz DEFAULT now(),
  last_updated_by               text,
  last_updated_at               timestamptz,
  approved_by                   text,
  approved_at                   timestamptz,
  posted_by                     text,
  posted_at                     timestamptz,
  is_active                     boolean DEFAULT true
);

-- ============================================================
--  AP VENDOR INVOICE (HEADER)
-- ============================================================

CREATE TABLE IF NOT EXISTS ap_vendor_invoice (
  id                          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

  vendor_invoice_no           text NOT NULL,                 -- vendor's invoice number
  system_invoice_no           text NOT NULL UNIQUE,          -- internal number
  vendor_id                   uuid, -- REFERENCES party_master(id) -- External: UUID only (nullable for Finance independence)
  vendor_name                  text, -- Snapshot: party_master.name (for standalone display)
  invoice_date                date NOT NULL,
  due_date                    date,
  payment_term_code           text, -- REFERENCES payment_term_lu(code) -- Internal table
  invoice_type                text REFERENCES ap_invoice_category_lu(code),
  job_id                      uuid, -- REFERENCES ops_job(id) -- External: UUID only
  job_code                    text, -- Snapshot: ops_job.job_code (for standalone display)
  department_cost_center_code text REFERENCES department_cost_center_lu(code),
  cost_head_gl_account_id     uuid REFERENCES gl_account_lu(id),
  asset_category_code         text REFERENCES asset_category_lu(code),
  currency_code               char(3) NOT NULL REFERENCES currency_lu(code),
  exchange_rate               numeric(12,6),

  subtotal_amount             numeric(14,2),
  tax_amount                  numeric(14,2),
  total_amount                numeric(14,2),
  amount_base_currency        numeric(14,2),
  provision_amount            numeric(14,2),
  provision_difference        numeric(14,2),
  notes_operations            text,
  vendor_supporting_documents jsonb,                       -- JSON vendor document attachments
  internal_comments           text,

  approval_status             text REFERENCES approval_status_lu(code),
  approval_remarks            text,
  reversal_reference          text,
  invoice_status              text REFERENCES invoice_status_lu(code),
  gl_posting_reference        text,
  gl_posting_status           text REFERENCES gl_posting_status_lu(code),

  created_by                  text,
  created_at                  timestamptz DEFAULT now(),
  last_updated_by             text,
  last_updated_at             timestamptz,
  approved_by                 text,
  approved_at                 timestamptz,
  posted_by                   text,
  posted_at                   timestamptz,
  is_active                   boolean DEFAULT true
);

-- ============================================================
--  AP VENDOR INVOICE LINES
-- ============================================================

CREATE TABLE IF NOT EXISTS ap_vendor_invoice_line (
  id                        uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_invoice_id         uuid NOT NULL REFERENCES ap_vendor_invoice(id) ON DELETE CASCADE,
  line_no                   int NOT NULL,

  ops_provision_id          uuid, -- REFERENCES ops_provision(id) -- External: UUID only
  item_code                 text,
  item_description          text,
  unit_of_measure           text,
  quantity                  numeric(14,3),
  unit_price                numeric(14,2),
  discount_amount           numeric(14,2),
  tax_code_id               uuid REFERENCES tax_code_lu(id),
  tax_rate_percent          numeric(6,3),
  tax_amount                numeric(14,2),
  line_amount               numeric(14,2),
  expense_gl_account_id     uuid REFERENCES gl_account_lu(id),
  line_notes                text,

  created_at                timestamptz DEFAULT now(),
  created_by                text,
  modified_at               timestamptz,
  modified_by               text,
  is_active                 boolean DEFAULT true,

  UNIQUE (vendor_invoice_id, line_no)
);

-- ============================================================
--  AP PAYMENT AGAINST INVOICE
-- ============================================================

CREATE TABLE IF NOT EXISTS ap_payment_against_invoice (
  id                          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

  payment_voucher_no          text NOT NULL UNIQUE,
  payment_date                date NOT NULL,
  vendor_id                   uuid, -- REFERENCES party_master(id) -- External: UUID only (nullable for Finance independence)
  vendor_name                 text, -- Snapshot: party_master.name (for standalone display)
  payment_type                text NOT NULL REFERENCES ap_payment_application_type_lu(code),
  vendor_invoice_id           uuid REFERENCES ap_vendor_invoice(id),
  invoice_type                text REFERENCES ap_invoice_category_lu(code),
  currency_code               char(3) NOT NULL REFERENCES currency_lu(code),
  exchange_rate               numeric(12,6),
  payment_purpose             text,

  payment_mode_id             smallint REFERENCES payment_method_lu(id),
  bank_account_id             uuid REFERENCES bank_account_lu(id),
  cheque_txn_no               text,
  payment_amount              numeric(14,2),
  amount_in_base_currency     numeric(14,2),
  payment_remarks             text,

  total_invoice_amount        numeric(14,2),
  total_outstanding_amount    numeric(14,2),
  allocated_amount            numeric(14,2),
  unallocated_amount          numeric(14,2),
  carry_as_advance_flag       boolean,

  approval_status             text REFERENCES approval_status_lu(code),
  approval_remarks            text,
  gl_posting_reference        text,
  gl_posting_status           text REFERENCES gl_posting_status_lu(code),

  created_by                  text,
  created_at                  timestamptz DEFAULT now(),
  last_updated_by             text,
  last_updated_at             timestamptz,
  approved_by                 text,
  approved_at                 timestamptz,
  posted_by                   text,
  posted_at                   timestamptz,
  is_active                   boolean DEFAULT true
);

-- ============================================================
--  AP VENDOR INVOICE ALLOCATION (PAYMENT AGAINST INVOICE)
-- ============================================================

CREATE TABLE IF NOT EXISTS ap_vendor_invoice_allocation (
  id                           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  payment_against_invoice_id   uuid NOT NULL REFERENCES ap_payment_against_invoice(id) ON DELETE CASCADE,
  line_no                      int NOT NULL,

  vendor_invoice_id            uuid REFERENCES ap_vendor_invoice(id),
  invoice_reference            text,                       -- User-entered reference (if no system invoice)
  invoice_no_snapshot          text,
  invoice_date_snapshot        date,
  invoice_amount               numeric(14,2),
  outstanding_amount           numeric(14,2),
  allocated_amount             numeric(14,2),

  created_at                   timestamptz DEFAULT now(),
  created_by                   text,
  modified_at                  timestamptz,
  modified_by                  text,
  is_active                    boolean DEFAULT true,

  UNIQUE (payment_against_invoice_id, line_no)
);

-- ============================================================
--  AP PAYMENT WITHOUT INVOICE
-- ============================================================

CREATE TABLE IF NOT EXISTS ap_payment_without_invoice (
  id                          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

  payment_voucher_no          text NOT NULL UNIQUE,
  payment_date                date NOT NULL,
  payment_type                text NOT NULL REFERENCES ap_invoice_category_lu(code),
  job_id                      uuid, -- REFERENCES ops_job(id) -- External: UUID only
  job_code                    text, -- Snapshot: ops_job.job_code (for standalone display)
  party_id                    uuid, -- REFERENCES party_master(id) -- External: UUID only
  party_name                  text, -- Snapshot: party_master.name (for standalone display)
  vendor_code_snapshot        text,
  currency_code               char(3) NOT NULL REFERENCES currency_lu(code),
  exchange_rate               numeric(12,6),
  payment_purpose             text,
  cost_head_gl_account_id     uuid REFERENCES gl_account_lu(id),

  payment_mode_id             smallint REFERENCES payment_method_lu(id),
  payment_account_id          uuid REFERENCES bank_account_lu(id),
  cheque_txn_no               text,
  amount_excl_tax             numeric(14,2),
  tax_code_id                 uuid REFERENCES tax_code_lu(id),
  tax_amount                  numeric(14,2),
  total_amount                numeric(14,2),
  amount_in_base_currency     numeric(14,2),
  payment_remarks             text,

  payee_name         text,
  payee_type                  text REFERENCES ap_receiver_type_lu(code),
  ref_number         text,
  ref_date           date,
  receipt_supporting_documents jsonb,                       -- JSON attachments for receipt proof
  is_marked_as_vendor_advance boolean,
  additional_narration        text,

  approval_status             text REFERENCES approval_status_lu(code),
  approval_remarks            text,
  gl_posting_reference        text,
  gl_posting_status           text REFERENCES gl_posting_status_lu(code),

  created_by                  text,
  created_at                  timestamptz DEFAULT now(),
  last_updated_by             text,
  last_updated_at             timestamptz,
  approved_by                 text,
  approved_at                 timestamptz,
  posted_by                   text,
  posted_at                   timestamptz,
  is_active                   boolean DEFAULT true
);

-- ============================================================
--  AP VENDOR PROVISION DETAILS (PAYMENT WITHOUT INVOICE)
-- ============================================================

CREATE TABLE IF NOT EXISTS ap_vendor_provision_details (
  id                           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  payment_without_invoice_id   uuid NOT NULL REFERENCES ap_payment_without_invoice(id) ON DELETE CASCADE,
  line_no                      int NOT NULL,

  ops_provision_id             uuid, -- REFERENCES ops_provision(id) -- External: UUID only
  item_description             text,
  item_code                    text,
  quantity                     numeric(14,3),
  unit_price                   numeric(14,2),
  amount_without_tax           numeric(14,2),
  tax_percent                  numeric(6,3),
  tax_amount                   numeric(14,2),
  total_with_tax               numeric(14,2),
  outstanding_amount           numeric(14,2),
  allocated_amount             numeric(14,2),

  created_at                   timestamptz DEFAULT now(),
  created_by                   text,
  modified_at                  timestamptz,
  modified_by                  text,
  is_active                    boolean DEFAULT true,

  UNIQUE (payment_without_invoice_id, line_no)
);

-- ============================================================
--  AP DEBIT NOTE
-- ============================================================

CREATE TABLE IF NOT EXISTS ap_debit_note (
  id                          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

  debit_note_no               text NOT NULL UNIQUE,
  debit_note_date             date NOT NULL,
  vendor_id                   uuid, -- REFERENCES party_master(id) -- External: UUID only (nullable for Finance independence)
  vendor_name                 text, -- Snapshot: party_master.name (for standalone display)
  vendor_invoice_id           uuid REFERENCES ap_vendor_invoice(id),
  currency_code               char(3) NOT NULL REFERENCES currency_lu(code),
  exchange_rate               numeric(12,6),

  reason_type                 text REFERENCES ap_debit_note_reason_lu(code),
  description                 text,
  amount                      numeric(14,2),
  tax_percent                 numeric(6,3),
  tax_amount                  numeric(14,2),
  total_amount                numeric(14,2),
  expense_gl_account_id       uuid REFERENCES gl_account_lu(id),
  department_cost_center_code text REFERENCES department_cost_center_lu(code),

  supporting_documents        jsonb,                      -- JSON attachment metadata
  remarks                     text,

  approval_status             text REFERENCES approval_status_lu(code),
  approval_remarks            text,

  created_by                  text,
  created_at                  timestamptz DEFAULT now(),
  last_updated_by             text,
  last_updated_at             timestamptz,
  approved_by                 text,
  approved_at                 timestamptz,
  is_active                   boolean DEFAULT true
);

-- ============================================================
--  APPROVAL HISTORY + TRIGGER
-- ============================================================

CREATE TABLE IF NOT EXISTS approval_history (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  module_name   text NOT NULL,       -- table name
  record_id     uuid NOT NULL,
  from_status   text,
  to_status     text,
  action        text NOT NULL,       -- Submitted/Approved/Rejected/Cancelled/StatusChanged
  action_by     text,
  action_at     timestamptz DEFAULT now(),
  remarks       text,
  is_active     boolean DEFAULT true
);

CREATE OR REPLACE FUNCTION trg_approval_status_audit()
RETURNS trigger AS $$
DECLARE
    v_from    text;
    v_to      text;
    v_action  text;
    v_actor   text;
    v_remarks text;
BEGIN
    IF NEW.approval_status IS DISTINCT FROM OLD.approval_status THEN
        v_from := OLD.approval_status;
        v_to   := NEW.approval_status;

        IF v_to = 'Pending Approval' THEN v_action := 'Submitted';
        ELSIF v_to = 'Approved' THEN v_action := 'Approved';
        ELSIF v_to = 'Returned' THEN v_action := 'Returned';
        ELSIF v_to = 'Posted' THEN v_action := 'Posted';
        ELSE v_action := 'StatusChanged';
        END IF;

        v_actor   := COALESCE(NEW.last_updated_by, NEW.approved_by, NEW.created_by);
        v_remarks := COALESCE(NEW.approval_remarks, '');

        INSERT INTO approval_history (
          module_name, record_id, from_status, to_status,
          action, action_by, remarks
        )
        VALUES (
          TG_TABLE_NAME, NEW.id, v_from, v_to,
          v_action, v_actor, v_remarks
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach triggers to finance headers
DROP TRIGGER IF EXISTS trg_ar_invoice_approval ON ar_invoice;
CREATE TRIGGER trg_ar_invoice_approval
AFTER UPDATE ON ar_invoice
FOR EACH ROW EXECUTE FUNCTION trg_approval_status_audit();

DROP TRIGGER IF EXISTS trg_ar_receipt_approval ON ar_receipt;
CREATE TRIGGER trg_ar_receipt_approval
AFTER UPDATE ON ar_receipt
FOR EACH ROW EXECUTE FUNCTION trg_approval_status_audit();

DROP TRIGGER IF EXISTS trg_ar_credit_note_approval ON ar_credit_note;
CREATE TRIGGER trg_ar_credit_note_approval
AFTER UPDATE ON ar_credit_note
FOR EACH ROW EXECUTE FUNCTION trg_approval_status_audit();

DROP TRIGGER IF EXISTS trg_ap_vendor_invoice_approval ON ap_vendor_invoice;
CREATE TRIGGER trg_ap_vendor_invoice_approval
AFTER UPDATE ON ap_vendor_invoice
FOR EACH ROW EXECUTE FUNCTION trg_approval_status_audit();

DROP TRIGGER IF EXISTS trg_ap_payment_against_invoice_approval ON ap_payment_against_invoice;
CREATE TRIGGER trg_ap_payment_against_invoice_approval
AFTER UPDATE ON ap_payment_against_invoice
FOR EACH ROW EXECUTE FUNCTION trg_approval_status_audit();

DROP TRIGGER IF EXISTS trg_ap_payment_without_invoice_approval ON ap_payment_without_invoice;
CREATE TRIGGER trg_ap_payment_without_invoice_approval
AFTER UPDATE ON ap_payment_without_invoice
FOR EACH ROW EXECUTE FUNCTION trg_approval_status_audit();

DROP TRIGGER IF EXISTS trg_ap_debit_note_approval ON ap_debit_note;
CREATE TRIGGER trg_ap_debit_note_approval
AFTER UPDATE ON ap_debit_note
FOR EACH ROW EXECUTE FUNCTION trg_approval_status_audit();

COMMIT;
