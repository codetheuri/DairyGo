-- The cooperative's own money: where it is kept (cash accounts: petty cash,
-- bank, M-Pesa), what it spends (expenses by category) and moves between
-- accounts (transfers). Money received or paid elsewhere in the system
-- (customer payments, cash at sales, advances, farmers' pay) can name the
-- account it went through, so each account has a cashbook and a balance.

-- +goose Up
CREATE TABLE IF NOT EXISTS cash_accounts (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL,
    kind VARCHAR(10) NOT NULL DEFAULT 'CASH',   -- CASH, BANK, MPESA
    account_number VARCHAR(100) NULL,           -- bank account, till or paybill
    opening_balance DECIMAL(14, 2) NOT NULL DEFAULT 0,
    opening_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by_id BIGINT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_cash_accounts_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_cash_accounts_created_by FOREIGN KEY (created_by_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_cash_accounts_name ON cash_accounts(sacco_id, LOWER(name));

CREATE TABLE IF NOT EXISTS expense_categories (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_expense_categories_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_expense_categories_name ON expense_categories(sacco_id, LOWER(name));

CREATE TABLE IF NOT EXISTS expenses (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    category_id VARCHAR(36) NOT NULL,
    cash_account_id VARCHAR(36) NOT NULL,
    expense_date DATE NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    payee VARCHAR(150) NOT NULL,
    reference VARCHAR(100) NULL,
    description TEXT NULL,
    recorded_by_id BIGINT NULL,
    voided_at TIMESTAMP NULL,
    void_reason TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_expenses_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_expenses_category FOREIGN KEY (category_id) REFERENCES expense_categories(id),
    CONSTRAINT fk_expenses_account FOREIGN KEY (cash_account_id) REFERENCES cash_accounts(id),
    CONSTRAINT fk_expenses_recorded_by FOREIGN KEY (recorded_by_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT ck_expenses_amount CHECK (amount > 0)
);
CREATE INDEX IF NOT EXISTS idx_expenses_sacco_date ON expenses(sacco_id, expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_account ON expenses(cash_account_id, expense_date);

CREATE TABLE IF NOT EXISTS account_transfers (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    from_account_id VARCHAR(36) NOT NULL,
    to_account_id VARCHAR(36) NOT NULL,
    transfer_date DATE NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    reference VARCHAR(100) NULL,
    notes TEXT NULL,
    recorded_by_id BIGINT NULL,
    voided_at TIMESTAMP NULL,
    void_reason TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_account_transfers_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_account_transfers_from FOREIGN KEY (from_account_id) REFERENCES cash_accounts(id),
    CONSTRAINT fk_account_transfers_to FOREIGN KEY (to_account_id) REFERENCES cash_accounts(id),
    CONSTRAINT fk_account_transfers_recorded_by FOREIGN KEY (recorded_by_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT ck_account_transfers CHECK (amount > 0 AND from_account_id <> to_account_id)
);
CREATE INDEX IF NOT EXISTS idx_account_transfers_sacco_date ON account_transfers(sacco_id, transfer_date);

-- Money elsewhere names the account it went through (optional: older
-- records have none).
ALTER TABLE customer_payments ADD COLUMN IF NOT EXISTS cash_account_id VARCHAR(36) NULL REFERENCES cash_accounts(id);
ALTER TABLE milk_sales ADD COLUMN IF NOT EXISTS cash_account_id VARCHAR(36) NULL REFERENCES cash_accounts(id);
ALTER TABLE member_transactions ADD COLUMN IF NOT EXISTS cash_account_id VARCHAR(36) NULL REFERENCES cash_accounts(id);
ALTER TABLE pay_run_lines ADD COLUMN IF NOT EXISTS cash_account_id VARCHAR(36) NULL REFERENCES cash_accounts(id);
CREATE INDEX IF NOT EXISTS idx_customer_payments_account ON customer_payments(cash_account_id) WHERE cash_account_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_milk_sales_account ON milk_sales(cash_account_id) WHERE cash_account_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_member_transactions_account ON member_transactions(cash_account_id) WHERE cash_account_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_pay_run_lines_account ON pay_run_lines(cash_account_id) WHERE cash_account_id IS NOT NULL;

-- Usual expense categories for every Sacco (new ones get them at onboarding).
INSERT INTO expense_categories (id, sacco_id, name, is_active, created_at, updated_at)
SELECT gen_random_uuid()::text, s.id, c.name, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM saccos s
CROSS JOIN (VALUES ('Salaries and wages'), ('Petty cash spending'), ('Transport and fuel'), ('Rent'),
    ('Electricity and water'), ('Repairs and maintenance'), ('Stationery and printing'),
    ('Bank and M-Pesa charges'), ('Meetings and AGM'), ('Other')) AS c(name)
WHERE NOT EXISTS (SELECT 1 FROM expense_categories e WHERE e.sacco_id = s.id AND LOWER(e.name) = LOWER(c.name));

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT p.name, p.description, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM (VALUES
    ('finance.read', 'Allows viewing expenses, cash accounts, cashbooks and the income and expenditure'),
    ('finance.expenses.manage', 'Allows recording and voiding expenses'),
    ('finance.accounts.manage', 'Allows setting up cash accounts and expense categories and moving money between accounts')
) AS p(name, description)
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permissions.name = p.name);

INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT g.role_id, g.name, CURRENT_TIMESTAMP
FROM (VALUES (1, 'finance.read'), (1, 'finance.expenses.manage'), (1, 'finance.accounts.manage'), (3, 'finance.read')) AS g(role_id, name)
WHERE NOT EXISTS (SELECT 1 FROM role_permissions r WHERE r.role_id = g.role_id AND r.permission_name = g.name);

-- +goose Down
DELETE FROM role_permissions WHERE permission_name LIKE 'finance.%';
DELETE FROM permissions WHERE name LIKE 'finance.%';
DROP INDEX IF EXISTS idx_pay_run_lines_account;
DROP INDEX IF EXISTS idx_member_transactions_account;
DROP INDEX IF EXISTS idx_milk_sales_account;
DROP INDEX IF EXISTS idx_customer_payments_account;
ALTER TABLE pay_run_lines DROP COLUMN IF EXISTS cash_account_id;
ALTER TABLE member_transactions DROP COLUMN IF EXISTS cash_account_id;
ALTER TABLE milk_sales DROP COLUMN IF EXISTS cash_account_id;
ALTER TABLE customer_payments DROP COLUMN IF EXISTS cash_account_id;
DROP TABLE IF EXISTS account_transfers;
DROP TABLE IF EXISTS expenses;
DROP TABLE IF EXISTS expense_categories;
DROP TABLE IF EXISTS cash_accounts;
