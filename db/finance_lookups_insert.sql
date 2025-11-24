-- ============================================================
--  FINANCE MODULE LOOKUP DATA
--  Insert seed data for all lookup tables
-- ============================================================

-- Insert order matters: groups before accounts
INSERT INTO gl_account_group_lu (id, code, name, description) VALUES
  (1, 'AR_LEDGER', 'AR-Customer', 'Accounts Receivable Ledger'),
  (2, 'AP_LEDGER', 'AP-Vendor', 'Accounts Payable Ledger'),
  (3, 'REVENUE_LEDGER', 'GL-Income', 'Income / Revenue Ledger'),
  (4, 'EXPENSE_LEDGER', 'GL-Expense', 'Expense Ledger'),
  (5, 'TAX_LEDGER', 'GL-Tax', 'Tax Ledger'),
  (6, 'BANK_LEDGER', 'GL-BankAccount', 'Bank Accounts Ledger'),
  (7, 'CASH_LEDGER', 'GL-Cash', 'Cash Ledger')
ON CONFLICT (id) DO NOTHING;

INSERT INTO gl_account_lu (code, name, account_type, account_group_id, currency_code) VALUES
  ('AR_CONTROL', 'Accounts Receivable Control', 'Asset', 1, 'AED'),
  ('AP_CONTROL', 'Accounts Payable Control', 'Liability', 2, 'AED'),
  ('INCOME_MAIN', 'Primary Income Account', 'Income', 3, 'AED'),
  ('EXPENSE_MAIN', 'Primary Expense Account', 'Expense', 4, 'AED'),
  ('TAX_MAIN', 'Tax Payable/Receivable', 'Liability', 5, 'AED'),
  ('BANK_MAIN', 'Bank Account', 'Asset', 6, 'AED'),
  ('CASH_MAIN', 'Cash Account', 'Asset', 7, 'AED')
ON CONFLICT (code) DO NOTHING;

INSERT INTO department_cost_center_lu (code, name, description) VALUES
  ('OPS', 'Operations', 'Operations / service delivery'),
  ('FIN', 'Finance', 'Finance & accounting'),
  ('ADM', 'Administration', 'Administrative / G&A costs')
ON CONFLICT (code) DO NOTHING;

INSERT INTO asset_category_lu (code, name, description) VALUES
  ('FA_IT', 'IT Equipment', 'Computers, servers, and network devices'),
  ('FA_VEH', 'Vehicles', 'Company cars, trucks, or mobility assets'),
  ('FA_OFF', 'Office Equipment', 'Furniture, fixtures, and general office assets'),
  ('FA_MACH', 'Machinery', 'Heavy machinery and production equipment'),
  ('FA_FAC', 'Facilities', 'Buildings, warehouses, and related improvements'),
  ('FA_LEASE', 'Leasehold Improvements', 'Fit-outs and other leasehold enhancements'),
  ('FA_OTHER', 'Other Assets', 'Catch-all category for assets not classified elsewhere')
ON CONFLICT (code) DO NOTHING;

INSERT INTO approval_status_lu (code, description) VALUES
  ('DRAFT', 'Draft'),
  ('RETURNED', 'Returned'),
  ('PENDING_APPROVAL', 'Pending Approval'),
  ('APPROVED', 'Approved'),
  ('POSTED', 'Posted')
ON CONFLICT (code) DO NOTHING;

INSERT INTO invoice_type_lu (code, label, description) VALUES
  ('REGULAR', 'Regular', 'Standard customer invoice'),
  ('PROFORMA', 'Proforma', 'Proforma invoice (non-posting)'),
  ('REVISED', 'Revised', 'Corrected or reissued invoice')
ON CONFLICT (code) DO NOTHING;

INSERT INTO receipt_type_lu (code, label, description) VALUES
  ('AGAINST_INVOICE', 'Against Invoice', 'Receipt applied to specific invoices'),
  ('ADVANCE', 'Advance', 'Advance received before invoicing'),
  ('ON_ACCOUNT', 'On Account', 'Unallocated receipt kept on account')
ON CONFLICT (code) DO NOTHING;

INSERT INTO receipt_utilization_status_lu (code, label, description) VALUES
  ('UNUTILIZED', 'Unutilized', 'Advance not yet utilized'),
  ('PARTIALLY_ADJUSTED', 'Partially Adjusted', 'Advance partially utilized/adjusted'),
  ('FULLY_UTILIZED', 'Fully Utilized', 'Advance fully utilized')
ON CONFLICT (code) DO NOTHING;

INSERT INTO credit_note_reason_lu (code, label, description) VALUES
  ('OVERBILLING', 'Overbilling', 'Invoice charged higher than agreed'),
  ('SERVICE_NOT_RENDERED', 'Service Not Rendered', 'Service not delivered or cancelled'),
  ('DISCOUNT', 'Discount', 'Commercial discount offered post-billing'),
  ('RETURN', 'Return', 'Return of goods or services'),
  ('ADJUSTMENT', 'Adjustment', 'General adjustment / correction'),
  ('OTHER', 'Other', 'Any other credit reason')
ON CONFLICT (code) DO NOTHING;

INSERT INTO ap_invoice_category_lu (code, label, description) VALUES
  ('JOB', 'Job', 'Job-linked invoice/payment'),
  ('NON_JOB', 'Non-Job', 'General expense not tied to a job'),
  ('ASSET', 'Asset', 'Asset purchase or capitalization'),
  ('LIABILITY', 'Liability', 'Liability or provision booking'),
  ('ADVANCE', 'Advance', 'Advance or prepayment')
ON CONFLICT (code) DO NOTHING;

INSERT INTO ap_payment_application_type_lu (code, label, description) VALUES
  ('AGAINST_INVOICE', 'Against Invoice', 'Payment allocated against specific invoices'),
  ('ADVANCE_PAYMENT', 'Advance Payment', 'Advance payment before invoice receipt')
ON CONFLICT (code) DO NOTHING;

INSERT INTO ap_receiver_type_lu (code, label, description) VALUES
  ('GOVT', 'Government', 'Government or regulatory authority'),
  ('PORT', 'Port', 'Port or terminal authority'),
  ('CUSTOMS', 'Customs', 'Customs department'),
  ('UTILITY', 'Utility', 'Utility or service provider'),
  ('OTHER', 'Other', 'Other receiver / payee')
ON CONFLICT (code) DO NOTHING;

INSERT INTO ap_debit_note_reason_lu (code, label, description) VALUES
  ('OVERBILLING', 'Overbilling', 'Vendor billed more than agreed'),
  ('SHORT_SUPPLY', 'Short Supply', 'Goods/services were short supplied'),
  ('SERVICE_DEFICIENCY', 'Service Deficiency', 'Quality or service deficiency'),
  ('PRICING_ERROR', 'Pricing Error', 'Incorrect pricing applied by vendor'),
  ('RETURN', 'Return', 'Returned goods/services'),
  ('OTHER', 'Other', 'Other debit note reason')
ON CONFLICT (code) DO NOTHING;

INSERT INTO payment_method_lu (id, code, label) VALUES
  (1, 'CASH', 'Cash'),
  (2, 'BANK_TRANSFER', 'Bank Transfer'),
  (3, 'CHEQUE', 'Cheque'),
  (4, 'OTHER', 'Other')
ON CONFLICT (id) DO NOTHING;

