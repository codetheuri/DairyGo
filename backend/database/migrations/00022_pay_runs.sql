-- Pay runs: every farmer's pay for a period, worked out from their milk and
-- the Sacco's deductions. Approving a run writes it to farmers' accounts and
-- closes the period; each farmer is then marked paid with a reference.

-- +goose Up
CREATE TABLE IF NOT EXISTS pay_runs (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    from_date DATE NOT NULL,
    to_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT', -- DRAFT, APPROVED, PAID, CANCELLED
    farmers INT NOT NULL DEFAULT 0,
    total_litres DECIMAL(14, 2) NOT NULL DEFAULT 0,
    total_gross DECIMAL(14, 2) NOT NULL DEFAULT 0,
    total_deductions DECIMAL(14, 2) NOT NULL DEFAULT 0,
    total_net DECIMAL(14, 2) NOT NULL DEFAULT 0,
    total_paid DECIMAL(14, 2) NOT NULL DEFAULT 0,
    paid_count INT NOT NULL DEFAULT 0,
    notes TEXT NULL,
    created_by_id BIGINT NULL,
    approved_by_id BIGINT NULL,
    approved_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    cancel_reason TEXT NULL,
    previous_closed_to DATE NULL, -- the closed-through date before approval, restored on cancel
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_pay_runs_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_pay_runs_created_by FOREIGN KEY (created_by_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_pay_runs_approved_by FOREIGN KEY (approved_by_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT ck_pay_runs_dates CHECK (from_date <= to_date)
);
CREATE INDEX IF NOT EXISTS idx_pay_runs_sacco ON pay_runs(sacco_id, to_date);
-- One run being worked on at a time.
CREATE UNIQUE INDEX IF NOT EXISTS uq_pay_runs_one_draft ON pay_runs(sacco_id) WHERE status = 'DRAFT';

CREATE TABLE IF NOT EXISTS pay_run_lines (
    id VARCHAR(36) PRIMARY KEY,
    pay_run_id VARCHAR(36) NOT NULL,
    sacco_id VARCHAR(36) NOT NULL,
    member_id VARCHAR(36) NOT NULL,
    membership_number VARCHAR(50) NOT NULL DEFAULT '',
    farmer_name VARCHAR(200) NOT NULL DEFAULT '',
    phone VARCHAR(50) NOT NULL DEFAULT '',
    mpesa_number VARCHAR(50) NULL,
    bank_name VARCHAR(100) NULL,
    bank_account_number VARCHAR(100) NULL,
    litres DECIMAL(12, 2) NOT NULL DEFAULT 0,
    gross DECIMAL(12, 2) NOT NULL DEFAULT 0,
    opening DECIMAL(12, 2) NOT NULL DEFAULT 0,
    entries DECIMAL(12, 2) NOT NULL DEFAULT 0,
    deductions DECIMAL(12, 2) NOT NULL DEFAULT 0,
    net DECIMAL(12, 2) NOT NULL DEFAULT 0,
    closing DECIMAL(12, 2) NOT NULL DEFAULT 0,
    paid_at TIMESTAMP NULL,
    paid_method VARCHAR(20) NULL,
    paid_reference VARCHAR(100) NULL,
    paid_by_id BIGINT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_pay_run_lines_run FOREIGN KEY (pay_run_id) REFERENCES pay_runs(id) ON DELETE CASCADE,
    CONSTRAINT fk_pay_run_lines_member FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
    CONSTRAINT fk_pay_run_lines_paid_by FOREIGN KEY (paid_by_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_pay_run_lines_member ON pay_run_lines(pay_run_id, member_id);

CREATE TABLE IF NOT EXISTS pay_run_items (
    id VARCHAR(36) PRIMARY KEY,
    line_id VARCHAR(36) NOT NULL,
    deduction_type_id VARCHAR(36) NULL,
    name VARCHAR(100) NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    is_savings BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_pay_run_items_line FOREIGN KEY (line_id) REFERENCES pay_run_lines(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_pay_run_items_line ON pay_run_items(line_id);

ALTER TABLE member_transactions ADD CONSTRAINT fk_member_transactions_pay_run
    FOREIGN KEY (pay_run_id) REFERENCES pay_runs(id) ON DELETE SET NULL;

-- Permissions (also synced from code at start-up); grants for role 1 (Sacco
-- administrator) and role 3 (board).
INSERT INTO permissions (name, description, created_at, updated_at)
SELECT p.name, p.description, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM (VALUES
    ('payouts.read', 'Allows viewing pay runs, payslips and farmer accounts'),
    ('payouts.deductions.manage', 'Allows setting up deductions and which farmers pay them'),
    ('payouts.advances.manage', 'Allows giving and voiding farmer advances'),
    ('payouts.charges.manage', 'Allows recording charges and adjustments on farmer accounts'),
    ('payouts.runs.manage', 'Allows preparing and cancelling pay runs'),
    ('payouts.runs.approve', 'Allows approving pay runs, which closes the period'),
    ('payouts.runs.pay', 'Allows marking farmers as paid')
) AS p(name, description)
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permissions.name = p.name);

INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT g.role_id, g.name, CURRENT_TIMESTAMP
FROM (VALUES
    (1, 'payouts.read'), (1, 'payouts.deductions.manage'), (1, 'payouts.advances.manage'),
    (1, 'payouts.charges.manage'), (1, 'payouts.runs.manage'), (1, 'payouts.runs.approve'),
    (1, 'payouts.runs.pay'),
    (3, 'payouts.read'), (3, 'payouts.runs.approve')
) AS g(role_id, name)
WHERE NOT EXISTS (SELECT 1 FROM role_permissions r WHERE r.role_id = g.role_id AND r.permission_name = g.name);

-- +goose Down
DELETE FROM role_permissions WHERE permission_name LIKE 'payouts.%';
DELETE FROM permissions WHERE name LIKE 'payouts.%';
ALTER TABLE member_transactions DROP CONSTRAINT IF EXISTS fk_member_transactions_pay_run;
DROP TABLE IF EXISTS pay_run_items;
DROP TABLE IF EXISTS pay_run_lines;
DROP TABLE IF EXISTS pay_runs;
