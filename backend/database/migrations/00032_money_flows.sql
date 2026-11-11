-- Money the books could not see yet (phase 4, see docs/finance.md and
-- docs/books.md):
--   * income_categories / other_income: money the Sacco receives besides milk
--     sales (interest, rent, sale of items, grants), into one of its accounts.
--   * suppliers: people and businesses the Sacco pays. One list serves both
--     bills (owed for goods and services) and deductions taken from farmers
--     for someone else (an insurer, a union, an agrovet), which are paid over.
--   * bills: an expense recorded now and paid later; supplier_payments pay a
--     bill (in parts if need be) or pay over money held for a supplier.
--   * deduction_types.goes_to: where a deduction's money goes: the Sacco's
--     income, the farmer's shares or savings, or owed to a supplier (payee_id).
--     member_transactions.payee_id keeps where each deduction went when it was
--     taken, so changing the deduction later never moves money already taken.
--   * share_entries: shares moved outside pay runs: opening balances, refunds
--     to members who leave, transfers between members.
--   * ledger_opening_lines: the accountant's opening balances for things no
--     record holds (fixed assets, loans), in the books' opening journal.
--   * payouts.shares.manage: record opening shares, refunds and transfers.

-- +goose Up
CREATE TABLE IF NOT EXISTS income_categories (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_income_categories_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_income_categories_name ON income_categories(sacco_id, name);

INSERT INTO income_categories (id, sacco_id, name, is_active, created_at, updated_at)
SELECT gen_random_uuid()::text, s.id, c.name, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
  FROM saccos s
 CROSS JOIN (VALUES ('Interest received'), ('Rent received'), ('Sale of items'), ('Grants and donations'), ('Other income')) AS c(name)
 WHERE NOT EXISTS (SELECT 1 FROM income_categories i WHERE i.sacco_id = s.id AND i.name = c.name);

CREATE TABLE IF NOT EXISTS other_income (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    category_id VARCHAR(36) NOT NULL,
    cash_account_id VARCHAR(36) NOT NULL,
    income_date DATE NOT NULL,
    amount DECIMAL(14, 2) NOT NULL,
    payer VARCHAR(150) NOT NULL,
    reference VARCHAR(100) NULL,
    description TEXT NULL,
    recorded_by_id BIGINT NULL,
    voided_at TIMESTAMP NULL,
    void_reason TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_other_income_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_other_income_category FOREIGN KEY (category_id) REFERENCES income_categories(id),
    CONSTRAINT fk_other_income_account FOREIGN KEY (cash_account_id) REFERENCES cash_accounts(id),
    CONSTRAINT fk_other_income_recorded_by FOREIGN KEY (recorded_by_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT ck_other_income_amount CHECK (amount > 0)
);
CREATE INDEX IF NOT EXISTS idx_other_income_date ON other_income(sacco_id, income_date);

CREATE TABLE IF NOT EXISTS suppliers (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NULL,
    notes TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by_id BIGINT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_suppliers_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_suppliers_created_by FOREIGN KEY (created_by_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_suppliers_name ON suppliers(sacco_id, name);

CREATE TABLE IF NOT EXISTS bills (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    supplier_id VARCHAR(36) NOT NULL,
    category_id VARCHAR(36) NOT NULL,       -- an expense category
    bill_date DATE NOT NULL,
    due_date DATE NULL,
    amount DECIMAL(14, 2) NOT NULL,
    reference VARCHAR(100) NULL,
    description TEXT NULL,
    recorded_by_id BIGINT NULL,
    voided_at TIMESTAMP NULL,
    void_reason TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_bills_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_bills_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
    CONSTRAINT fk_bills_category FOREIGN KEY (category_id) REFERENCES expense_categories(id),
    CONSTRAINT fk_bills_recorded_by FOREIGN KEY (recorded_by_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT ck_bills_amount CHECK (amount > 0)
);
CREATE INDEX IF NOT EXISTS idx_bills_supplier ON bills(sacco_id, supplier_id);
CREATE INDEX IF NOT EXISTS idx_bills_date ON bills(sacco_id, bill_date);

CREATE TABLE IF NOT EXISTS supplier_payments (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    supplier_id VARCHAR(36) NOT NULL,
    kind VARCHAR(10) NOT NULL,              -- BILL (pays bill_id) or PAY_OVER (deductions held)
    bill_id VARCHAR(36) NULL,
    cash_account_id VARCHAR(36) NOT NULL,
    payment_date DATE NOT NULL,
    amount DECIMAL(14, 2) NOT NULL,
    reference VARCHAR(100) NULL,
    notes TEXT NULL,
    recorded_by_id BIGINT NULL,
    voided_at TIMESTAMP NULL,
    void_reason TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_supplier_payments_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_supplier_payments_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
    CONSTRAINT fk_supplier_payments_bill FOREIGN KEY (bill_id) REFERENCES bills(id),
    CONSTRAINT fk_supplier_payments_account FOREIGN KEY (cash_account_id) REFERENCES cash_accounts(id),
    CONSTRAINT fk_supplier_payments_recorded_by FOREIGN KEY (recorded_by_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT ck_supplier_payments_kind CHECK ((kind = 'BILL' AND bill_id IS NOT NULL) OR (kind = 'PAY_OVER' AND bill_id IS NULL)),
    CONSTRAINT ck_supplier_payments_amount CHECK (amount > 0)
);
CREATE INDEX IF NOT EXISTS idx_supplier_payments_supplier ON supplier_payments(sacco_id, supplier_id);
CREATE INDEX IF NOT EXISTS idx_supplier_payments_bill ON supplier_payments(bill_id);

ALTER TABLE deduction_types ADD COLUMN IF NOT EXISTS goes_to VARCHAR(10) NOT NULL DEFAULT 'INCOME';
ALTER TABLE deduction_types ADD COLUMN IF NOT EXISTS payee_id VARCHAR(36) NULL;
UPDATE deduction_types SET goes_to = 'SAVINGS' WHERE is_savings;
ALTER TABLE deduction_types ADD CONSTRAINT ck_deduction_types_goes_to
    CHECK ((goes_to = 'PAYEE' AND payee_id IS NOT NULL) OR (goes_to IN ('INCOME', 'SAVINGS') AND payee_id IS NULL));
ALTER TABLE deduction_types ADD CONSTRAINT fk_deduction_types_payee FOREIGN KEY (payee_id) REFERENCES suppliers(id);

ALTER TABLE member_transactions ADD COLUMN IF NOT EXISTS payee_id VARCHAR(36) NULL;
ALTER TABLE member_transactions ADD CONSTRAINT fk_member_transactions_payee FOREIGN KEY (payee_id) REFERENCES suppliers(id);
CREATE INDEX IF NOT EXISTS idx_member_transactions_payee ON member_transactions(sacco_id, payee_id) WHERE payee_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS share_entries (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    member_id VARCHAR(36) NOT NULL,
    deduction_type_id VARCHAR(36) NULL,     -- the savings deduction these shares count towards
    kind VARCHAR(15) NOT NULL,              -- OPENING, REFUND, TRANSFER_IN, TRANSFER_OUT
    entry_date DATE NOT NULL,
    amount DECIMAL(14, 2) NOT NULL,         -- signed: positive adds to the member's shares
    cash_account_id VARCHAR(36) NULL,       -- a refund: the account it was paid from
    reference VARCHAR(100) NULL,
    notes TEXT NULL,
    transfer_id VARCHAR(36) NULL,           -- the two sides of a transfer share it
    other_member_id VARCHAR(36) NULL,       -- a transfer: the member on the other side
    recorded_by_id BIGINT NULL,
    voided_at TIMESTAMP NULL,
    void_reason TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_share_entries_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_share_entries_member FOREIGN KEY (member_id) REFERENCES members(id),
    CONSTRAINT fk_share_entries_other FOREIGN KEY (other_member_id) REFERENCES members(id),
    CONSTRAINT fk_share_entries_type FOREIGN KEY (deduction_type_id) REFERENCES deduction_types(id),
    CONSTRAINT fk_share_entries_account FOREIGN KEY (cash_account_id) REFERENCES cash_accounts(id),
    CONSTRAINT fk_share_entries_recorded_by FOREIGN KEY (recorded_by_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT ck_share_entries_kind CHECK (kind IN ('OPENING', 'REFUND', 'TRANSFER_IN', 'TRANSFER_OUT')),
    CONSTRAINT ck_share_entries_amount CHECK (amount <> 0)
);
CREATE INDEX IF NOT EXISTS idx_share_entries_member ON share_entries(sacco_id, member_id);
CREATE INDEX IF NOT EXISTS idx_share_entries_transfer ON share_entries(transfer_id) WHERE transfer_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS ledger_opening_lines (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    account_id VARCHAR(36) NOT NULL,
    debit DECIMAL(14, 2) NOT NULL DEFAULT 0,
    credit DECIMAL(14, 2) NOT NULL DEFAULT 0,
    memo TEXT NULL,
    created_by_id BIGINT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_ledger_opening_lines_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_ledger_opening_lines_account FOREIGN KEY (account_id) REFERENCES ledger_accounts(id),
    CONSTRAINT fk_ledger_opening_lines_created_by FOREIGN KEY (created_by_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT ck_ledger_opening_lines_amounts CHECK (debit >= 0 AND credit >= 0 AND (debit = 0) <> (credit = 0))
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_ledger_opening_lines_account ON ledger_opening_lines(sacco_id, account_id);

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'payouts.shares.manage', 'Allows recording opening shares, refunding shares to members who leave and moving shares between members',
       CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'payouts.shares.manage');

INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT g.role_id, 'payouts.shares.manage', CURRENT_TIMESTAMP
  FROM (VALUES (1), (4)) AS g(role_id)
 WHERE EXISTS (SELECT 1 FROM roles r WHERE r.id = g.role_id)
   AND NOT EXISTS (SELECT 1 FROM role_permissions r WHERE r.role_id = g.role_id AND r.permission_name = 'payouts.shares.manage');

-- +goose Down
DELETE FROM role_permissions WHERE permission_name = 'payouts.shares.manage';
DELETE FROM permissions WHERE name = 'payouts.shares.manage';
DROP TABLE IF EXISTS ledger_opening_lines;
DROP TABLE IF EXISTS share_entries;
DROP INDEX IF EXISTS idx_member_transactions_payee;
ALTER TABLE member_transactions DROP CONSTRAINT IF EXISTS fk_member_transactions_payee;
ALTER TABLE member_transactions DROP COLUMN IF EXISTS payee_id;
ALTER TABLE deduction_types DROP CONSTRAINT IF EXISTS fk_deduction_types_payee;
ALTER TABLE deduction_types DROP CONSTRAINT IF EXISTS ck_deduction_types_goes_to;
ALTER TABLE deduction_types DROP COLUMN IF EXISTS payee_id;
ALTER TABLE deduction_types DROP COLUMN IF EXISTS goes_to;
DROP TABLE IF EXISTS supplier_payments;
DROP TABLE IF EXISTS bills;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS other_income;
DROP TABLE IF EXISTS income_categories;
