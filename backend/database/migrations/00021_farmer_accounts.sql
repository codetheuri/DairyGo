-- Farmer accounts and deductions. Every farmer has an account
-- (member_transactions) whose balance is what the Sacco owes them; advances,
-- charges, deductions and net pay are entries in it. Deductions are rules a
-- Sacco sets itself (deduction_types), so new ones need no code changes.

-- +goose Up
CREATE TABLE IF NOT EXISTS deduction_types (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT NULL,
    method VARCHAR(20) NOT NULL DEFAULT 'FIXED',     -- FIXED, PERCENT, PER_LITRE, TIERED
    base VARCHAR(10) NOT NULL DEFAULT 'GROSS',       -- GROSS, NET (what PERCENT/TIERED are worked out on)
    amount DECIMAL(12, 2) NOT NULL DEFAULT 0,        -- KES, percent or KES per litre
    tiers TEXT NULL,                                 -- TIERED: JSON [{"up_to": 1500, "fee": 5}, {"fee": 23}]
    frequency VARCHAR(20) NOT NULL DEFAULT 'EVERY_RUN', -- EVERY_RUN, ONCE_PER_MEMBER, ONCE_PER_YEAR, UNTIL_TARGET
    target_amount DECIMAL(12, 2) NULL,               -- UNTIL_TARGET
    applies_to VARCHAR(10) NOT NULL DEFAULT 'ALL',   -- ALL, ENROLLED
    priority INT NOT NULL DEFAULT 50,
    is_savings BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by_id BIGINT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,
    CONSTRAINT fk_deduction_types_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_deduction_types_created_by FOREIGN KEY (created_by_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_deduction_types_name ON deduction_types(sacco_id, LOWER(name)) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS member_deductions (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    member_id VARCHAR(36) NOT NULL,
    deduction_type_id VARCHAR(36) NOT NULL,
    amount DECIMAL(12, 2) NULL,          -- this farmer's amount instead of the usual one
    target_amount DECIMAL(12, 2) NULL,   -- this farmer's target (e.g. a loan)
    is_active BOOLEAN NOT NULL DEFAULT TRUE, -- false exempts the farmer
    notes TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_member_deductions_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_member_deductions_member FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
    CONSTRAINT fk_member_deductions_type FOREIGN KEY (deduction_type_id) REFERENCES deduction_types(id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_member_deductions ON member_deductions(member_id, deduction_type_id);

CREATE TABLE IF NOT EXISTS member_transactions (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    member_id VARCHAR(36) NOT NULL,
    kind VARCHAR(20) NOT NULL,           -- MILK, ADVANCE, CHARGE, ADJUSTMENT, DEDUCTION, PAYOUT
    entry_date DATE NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,      -- signed: + the Sacco owes the farmer more
    description VARCHAR(255) NOT NULL DEFAULT '',
    deduction_type_id VARCHAR(36) NULL,
    is_savings BOOLEAN NOT NULL DEFAULT FALSE,
    pay_run_id VARCHAR(36) NULL,         -- the run that settled it; NULL = waiting for the next run
    method VARCHAR(20) NULL,             -- CASH, MPESA, BANK_TRANSFER, CHEQUE
    reference VARCHAR(100) NULL,
    recorded_by_id BIGINT NULL,
    voided_at TIMESTAMP NULL,
    void_reason TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_member_transactions_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_member_transactions_member FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
    CONSTRAINT fk_member_transactions_type FOREIGN KEY (deduction_type_id) REFERENCES deduction_types(id) ON DELETE SET NULL,
    CONSTRAINT fk_member_transactions_recorded_by FOREIGN KEY (recorded_by_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_member_transactions_member ON member_transactions(sacco_id, member_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_member_transactions_open ON member_transactions(sacco_id, member_id) WHERE pay_run_id IS NULL AND voided_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_member_transactions_kind ON member_transactions(sacco_id, kind, entry_date);

-- NULL = no limit.
ALTER TABLE sacco_settings ADD COLUMN IF NOT EXISTS advance_max_per_period DECIMAL(12, 2) NULL;
-- Milk records dated on or before this day are paid for and locked.
ALTER TABLE sacco_settings ADD COLUMN IF NOT EXISTS payroll_closed_through DATE NULL;

-- The deductions Maru listed, as switched-off examples for every Sacco to
-- complete (amounts) and switch on. Nothing is taken until they do.
INSERT INTO deduction_types (id, sacco_id, name, description, method, base, amount, frequency, applies_to, priority, is_savings, is_active, created_at, updated_at)
SELECT gen_random_uuid()::text, s.id, d.name, d.description, d.method, d.base, 0, d.frequency, 'ALL', d.priority, d.is_savings, FALSE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM saccos s
CROSS JOIN (VALUES
    ('Registration fee', 'Paid once when a farmer joins', 'FIXED', 'GROSS', 'ONCE_PER_MEMBER', 10, FALSE),
    ('Annual subscription', 'Paid once a year', 'FIXED', 'GROSS', 'ONCE_PER_YEAR', 20, FALSE),
    ('Shares', 'Share capital, taken each pay run until the target is reached', 'FIXED', 'GROSS', 'UNTIL_TARGET', 30, TRUE),
    ('Transaction cost', 'M-Pesa or bank charge for sending the pay', 'TIERED', 'NET', 'EVERY_RUN', 100, FALSE)
) AS d(name, description, method, base, frequency, priority, is_savings)
WHERE NOT EXISTS (
    SELECT 1 FROM deduction_types t WHERE t.sacco_id = s.id AND LOWER(t.name) = LOWER(d.name) AND t.deleted_at IS NULL
);

-- +goose Down
ALTER TABLE sacco_settings DROP COLUMN IF EXISTS payroll_closed_through;
ALTER TABLE sacco_settings DROP COLUMN IF EXISTS advance_max_per_period;
DROP TABLE IF EXISTS member_transactions;
DROP TABLE IF EXISTS member_deductions;
DROP TABLE IF EXISTS deduction_types;
