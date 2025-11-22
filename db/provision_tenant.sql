BEGIN
  CREATE OR REPLACE PROCEDURE ensure_finance_tenant_schema(
    p_tenant_id uuid DEFAULT NULL,
    p_schema text DEFAULT NULL
  )
  LANGUAGE plpgsql
  AS $$
  DECLARE
    tenant_uuid    uuid := COALESCE(p_tenant_id, uuid_generate_v4());
    tenant_id_text text := trim(both from tenant_uuid::text);
    schema_input   text := NULLIF(trim(both from p_schema), '');
    tenant_schema  text;
    v_actor        text := COALESCE(NULLIF(current_setting('app.actor', true), ''), session_user::text);
  BEGIN
    IF tenant_uuid IS NULL THEN
      RAISE EXCEPTION 'Tenant identifier must be provided.';
    END IF;

    -- Determine schema name
    IF schema_input IS NOT NULL THEN
      tenant_schema := schema_input;
    ELSE
      tenant_schema := 'finance_' || regexp_replace(lower(tenant_id_text), '[^a-z0-9_]', '_', 'g');
    END IF;

    -- Create Schema
    EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', tenant_schema);

    -- Set search path to new schema
    EXECUTE format('SET search_path TO %I, public', tenant_schema);

    -- Create all finance tables in the tenant schema
    EXECUTE format($ddl$

    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

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

    -- Ledger account groups (AR, AP, BANK, etc.)
    CREATE TABLE IF NOT EXISTS gl_account_group_lu (
      id          smallint PRIMARY KEY,
      code        text NOT NULL UNIQUE,   -- e.g. 'AR_LEDGER','AP_LEDGER','BANK_LEDGER'
      name        text NOT NULL,
      description text
    );

    -- GL account master
    CREATE TABLE IF NOT EXISTS gl_account_lu (
      id                 uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      code               text NOT NULL UNIQUE,
      name               text NOT NULL,
      account_type       text,                       -- Asset/Liability/Income/Expense/Equity
      account_group_id   smallint REFERENCES gl_account_group_lu(id),
      control_account_for text,                     -- 'Customer','Vendor','Bank', etc. (optional)
      currency_code      char(3) REFERENCES currency_lu(code),
      is_active          boolean DEFAULT true,
      created_at         timestamptz DEFAULT now(),
      created_by         text,
      modified_at        timestamptz,
      modified_by        text
    );

    CREATE INDEX IF NOT EXISTS idx_gl_account_group
      ON gl_account_lu(account_group_id);

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

    CREATE INDEX IF NOT EXISTS idx_bank_account_gl
      ON bank_account_lu(gl_account_id);

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
      display_order smallint NOT NULL,
      description text
    );

    -- ============================================================
    --  LEDGER ENGINE
    --  journal_entry_header + journal_entry_lines + general_ledger
    -- ============================================================

    CREATE TABLE IF NOT EXISTS journal_entry_header (
      id                     uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      journal_no             text NOT NULL UNIQUE,
      journal_date           date NOT NULL,
      description            text,
      source_module          text,           -- 'AR','AP','MANUAL',...
      source_document_type   text,           -- 'AR_INVOICE','AP_PAYMENT',...
      source_document_id     uuid,           -- FK not enforced (can point to any header)
      currency_code          char(3) REFERENCES currency_lu(code),
      exchange_rate          numeric(12,6),
      total_debit            numeric(14,2),
      total_credit           numeric(14,2),
      status                 text,           -- journal posting status (not approval)
      posted_at              timestamptz,
      posted_by              text,
      created_at             timestamptz DEFAULT now(),
      created_by             text,
      modified_at            timestamptz,
      modified_by            text,
      is_active              boolean DEFAULT true
    );

    CREATE INDEX IF NOT EXISTS idx_journal_header_date
      ON journal_entry_header(journal_date);

    CREATE INDEX IF NOT EXISTS idx_journal_header_source
      ON journal_entry_header(source_module, source_document_type, source_document_id);

    CREATE TABLE IF NOT EXISTS journal_entry_lines (
      id               uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      header_id        uuid NOT NULL REFERENCES journal_entry_header(id) ON DELETE CASCADE,
      line_no          int NOT NULL,
      gl_account_id    uuid NOT NULL REFERENCES gl_account_lu(id),
      party_id         uuid -- REFERENCES party_master(id) -- External: UUID only,      -- customer/vendor
      job_id           uuid -- REFERENCES ops_job(id) -- External: UUID only,
      branch_id        uuid REFERENCES branch_lu(branch_id),
      debit_amount     numeric(14,2) DEFAULT 0,
      credit_amount    numeric(14,2) DEFAULT 0,
      narration        text,
      created_at       timestamptz DEFAULT now(),
      created_by       text,
      modified_at      timestamptz,
      modified_by      text,
      is_active        boolean DEFAULT true,

      UNIQUE (header_id, line_no)
    );

    CREATE INDEX IF NOT EXISTS idx_journal_lines_header
      ON journal_entry_lines(header_id);

    CREATE INDEX IF NOT EXISTS idx_journal_lines_gl_account
      ON journal_entry_lines(gl_account_id);

    CREATE INDEX IF NOT EXISTS idx_journal_lines_party
      ON journal_entry_lines(party_id);

    CREATE INDEX IF NOT EXISTS idx_journal_lines_job
      ON journal_entry_lines(job_id);

    -- Final general ledger postings (populated when documents are posted)
    CREATE TABLE IF NOT EXISTS general_ledger (
      entry_id               uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      journal_line_id        uuid,
      journal_header_id      uuid,
      journal_no             text,
      journal_date           date,
      journal_description    text,
      source_module          text,
      source_document_type   text,
      source_document_id     uuid,
      currency_code          char(3),
      exchange_rate          numeric(12,6),
      journal_status         text,
      line_no                int,
      gl_account_id          uuid REFERENCES gl_account_lu(id),
      gl_account_code        text,
      gl_account_name        text,
      account_group_id       smallint,
      account_group_code     text,
      account_group_name     text,
      party_id               uuid,
      job_id                 uuid,
      branch_id              uuid,
      debit_amount           numeric(14,2) DEFAULT 0,
      credit_amount          numeric(14,2) DEFAULT 0,
      line_narration         text,
      created_at             timestamptz DEFAULT now(),
      created_by             text,
      posted_at              timestamptz,
      posted_by              text,
      is_active              boolean DEFAULT true
    );

    CREATE UNIQUE INDEX IF NOT EXISTS idx_general_ledger_line_id
      ON general_ledger(journal_line_id);

    CREATE INDEX IF NOT EXISTS idx_general_ledger_account
      ON general_ledger(gl_account_id, journal_date);

    CREATE INDEX IF NOT EXISTS idx_general_ledger_party
      ON general_ledger(party_id, journal_date);

    CREATE INDEX IF NOT EXISTS idx_general_ledger_group
      ON general_ledger(account_group_code, journal_date);

    -- ============================================================
    --  AR INVOICE (HEADER)
    -- ============================================================

    CREATE TABLE IF NOT EXISTS ar_invoice (
      id                       uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

      invoice_no               text NOT NULL UNIQUE,
      invoice_type             text NOT NULL,                 -- from Excel
      invoice_date             date NOT NULL,
      customer_id              uuid NOT NULL -- REFERENCES party_master(id) -- External: UUID only,
      job_id                   uuid -- REFERENCES ops_job(id) -- External: UUID only,
      billing_address          text,
      billing_country          text,
      currency_code            char(3) NOT NULL REFERENCES currency_lu(code),
      exchange_rate            numeric(12,6),
      payment_term_code        text REFERENCES payment_term_lu(code),
      customer_po_number       text,
      customer_po_date         date,
      sales_executive_id       uuid -- REFERENCES employee_master(id) -- External: UUID only,

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
      invoice_status           text,                          -- Unpaid/Partially/Fully Paid
      gl_posting_status        text,                          -- Pending/Posted/Error
      posting_reference_no     text,

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

    CREATE INDEX IF NOT EXISTS idx_ar_invoice_customer_status
      ON ar_invoice(customer_id, invoice_status);

    CREATE INDEX IF NOT EXISTS idx_ar_invoice_job
      ON ar_invoice(job_id);

    -- ============================================================
    --  AR INVOICE LINES
    --  NOTE: discount_amount → amount_without_tax (for readability)
    -- ============================================================

    CREATE TABLE IF NOT EXISTS ar_invoice_line (
      id                   uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      invoice_id           uuid NOT NULL REFERENCES ar_invoice(id) ON DELETE CASCADE,
      line_no              int NOT NULL,

      invoice_type_code    text REFERENCES invoice_type_lu(code),
      item_description     text NOT NULL,
      item_code            text,
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

    CREATE INDEX IF NOT EXISTS idx_ar_invoice_line_invoice
      ON ar_invoice_line(invoice_id);

    -- ============================================================
    --  AR RECEIPT (HEADER)
    -- ============================================================

    CREATE TABLE IF NOT EXISTS ar_receipt (
      id                          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

      receipt_no                  text NOT NULL UNIQUE,
      receipt_type                text NOT NULL REFERENCES receipt_type_lu(code),
      receipt_date                date NOT NULL,
      customer_id                 uuid NOT NULL -- REFERENCES party_master(id) -- External: UUID only,
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
      gl_posting_status           text,
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

    CREATE INDEX IF NOT EXISTS idx_ar_receipt_customer_date
      ON ar_receipt(customer_id, receipt_date);

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

    CREATE INDEX IF NOT EXISTS idx_ar_receipt_alloc_invoice
      ON ar_receipt_invoice_allocation(invoice_id);

    -- ============================================================
    --  AR CREDIT NOTE
    -- ============================================================

    CREATE TABLE IF NOT EXISTS ar_credit_note (
      id                            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

      credit_note_no                text NOT NULL UNIQUE,
      credit_note_date              date NOT NULL,
      customer_id                   uuid NOT NULL -- REFERENCES party_master(id) -- External: UUID only,
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
      gl_posting_status             text,
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

    CREATE INDEX IF NOT EXISTS idx_ar_credit_note_customer
      ON ar_credit_note(customer_id, credit_note_date);

    -- ============================================================
    --  AP VENDOR INVOICE (HEADER)
    -- ============================================================

    CREATE TABLE IF NOT EXISTS ap_vendor_invoice (
      id                          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

      vendor_invoice_no           text NOT NULL,                 -- vendor''s invoice number
      system_invoice_no           text NOT NULL UNIQUE,          -- internal number
      vendor_id                   uuid NOT NULL -- REFERENCES party_master(id) -- External: UUID only,
      invoice_date                date NOT NULL,
      due_date                    date,
      payment_term_code           text REFERENCES payment_term_lu(code),
      invoice_type                text REFERENCES ap_invoice_category_lu(code),
      job_id                      uuid -- REFERENCES ops_job(id) -- External: UUID only,
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
      invoice_status              text,
      gl_posting_reference        text,
      gl_posting_status           text,

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

    CREATE INDEX IF NOT EXISTS idx_ap_vendor_invoice_vendor_status
      ON ap_vendor_invoice(vendor_id, invoice_status);

    -- ============================================================
    --  AP VENDOR INVOICE LINES
    -- ============================================================

    CREATE TABLE IF NOT EXISTS ap_vendor_invoice_line (
      id                        uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      vendor_invoice_id         uuid NOT NULL REFERENCES ap_vendor_invoice(id) ON DELETE CASCADE,
      line_no                   int NOT NULL,

      ops_provision_id          uuid -- REFERENCES ops_provision(id) -- External: UUID only,
      item_description          text NOT NULL,
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

    CREATE INDEX IF NOT EXISTS idx_ap_vendor_invoice_line_invoice
      ON ap_vendor_invoice_line(vendor_invoice_id);

    -- ============================================================
    --  AP PAYMENT AGAINST INVOICE
    -- ============================================================

    CREATE TABLE IF NOT EXISTS ap_payment_against_invoice (
      id                          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

      payment_voucher_no          text NOT NULL UNIQUE,
      payment_date                date NOT NULL,
      vendor_id                   uuid NOT NULL -- REFERENCES party_master(id) -- External: UUID only,
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
      gl_posting_status           text,

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

    CREATE INDEX IF NOT EXISTS idx_ap_payment_against_vendor
      ON ap_payment_against_invoice(vendor_id, payment_date);

    -- ============================================================
    --  AP PAYMENT WITHOUT INVOICE
    -- ============================================================

    CREATE TABLE IF NOT EXISTS ap_payment_without_invoice (
      id                          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

      payment_voucher_no          text NOT NULL UNIQUE,
      payment_date                date NOT NULL,
      payment_type                text NOT NULL REFERENCES ap_invoice_category_lu(code),
      job_id                      uuid -- REFERENCES ops_job(id) -- External: UUID only,
      party_id                    uuid -- REFERENCES party_master(id) -- External: UUID only,
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

      official_payee_name         text,
      payee_type                  text REFERENCES ap_receiver_type_lu(code),
      official_ref_number         text,
      official_ref_date           date,
      receipt_supporting_documents jsonb,                       -- JSON attachments for receipt proof
      is_marked_as_vendor_advance boolean,
      additional_narration        text,

      approval_status             text REFERENCES approval_status_lu(code),
      approval_remarks            text,
      gl_posting_reference        text,
      gl_posting_status           text,

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

    CREATE INDEX IF NOT EXISTS idx_ap_payment_without_party
      ON ap_payment_without_invoice(party_id, payment_date);

    -- ============================================================
    --  AP DEBIT NOTE
    -- ============================================================

    CREATE TABLE IF NOT EXISTS ap_debit_note (
      id                          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

      debit_note_no               text NOT NULL UNIQUE,
      debit_note_date             date NOT NULL,
      vendor_id                   uuid NOT NULL -- REFERENCES party_master(id) -- External: UUID only,
      vendor_invoice_id           uuid REFERENCES ap_vendor_invoice(id),
      currency_code               char(3) NOT NULL REFERENCES currency_lu(code),
      exchange_rate               numeric(12,6),

      reason_type                 text REFERENCES ap_debit_note_reason_lu(code),
      description                 text,
      amount                      numeric(14,2),
      tax_percent                 numeric(6,3),
      tax_amount                  numeric(14,2),
      total_amount                numeric(14,2),

      approval_status             text REFERENCES approval_status_lu(code),
      approval_remarks            text,
      gl_posting_status           text,
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

    CREATE INDEX IF NOT EXISTS idx_ap_debit_note_vendor_status
      ON ap_debit_note(vendor_id, invoice_status);

    -- ============================================================
    --  FINANCE MODULE LOGGING
    -- ============================================================

    CREATE TABLE IF NOT EXISTS finance_module_log (
      id                uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      tenant_id         uuid NOT NULL REFERENCES tenant_registry(tenant_id),
      action            text NOT NULL,   -- 'provision', 'deprovision', 'update'
      schema_name       text,
      status            text NOT NULL,   -- 'pending', 'success', 'failed'
      error_message     text,
      performed_at      timestamptz DEFAULT now(),
      performed_by      text
    );

    CREATE INDEX IF NOT EXISTS idx_finance_module_log_tenant
      ON finance_module_log(tenant_id);

    CREATE INDEX IF NOT EXISTS idx_finance_module_log_status
      ON finance_module_log(status);

    COMMIT;
  END;
  $$;
