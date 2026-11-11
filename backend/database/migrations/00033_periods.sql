-- Periods and bank reconciliation (phase 5, see docs/books.md and
-- docs/finance.md):
--   * ledger_books.closed_through: the books are closed through this day (the
--     end of a month). Nothing is dated in a closed month: a record changed
--     there posts its correction on the first open day. year_closed_through:
--     the last financial year whose income and expenses were moved to
--     retained surplus by a year-end journal.
--   * ledger_period_events: every close, reopen and year end, with who and
--     why (reopening needs a reason).
--   * bank_statements / bank_statement_lines: a bank or M-Pesa statement
--     imported for one of the Sacco's accounts; each line can be matched to
--     one movement in the account's cashbook (match_key names the movement:
--     source|record id|date).

-- +goose Up
ALTER TABLE ledger_books ADD COLUMN IF NOT EXISTS closed_through DATE NULL;
ALTER TABLE ledger_books ADD COLUMN IF NOT EXISTS year_closed_through DATE NULL;

CREATE TABLE IF NOT EXISTS ledger_period_events (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    action VARCHAR(12) NOT NULL,            -- CLOSE, REOPEN, YEAR_END
    through_date DATE NULL,                 -- closed through after the event (NULL: nothing closed)
    previous_date DATE NULL,                -- closed through before it
    amount DECIMAL(14, 2) NULL,             -- YEAR_END: the year's surplus moved
    journal_id VARCHAR(36) NULL,            -- YEAR_END: the closing journal
    reason TEXT NULL,
    created_by_id BIGINT NULL,
    created_at TIMESTAMP NOT NULL,
    CONSTRAINT fk_ledger_period_events_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_ledger_period_events_journal FOREIGN KEY (journal_id) REFERENCES journals(id) ON DELETE SET NULL,
    CONSTRAINT fk_ledger_period_events_created_by FOREIGN KEY (created_by_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT ck_ledger_period_events_action CHECK (action IN ('CLOSE', 'REOPEN', 'YEAR_END'))
);
CREATE INDEX IF NOT EXISTS idx_ledger_period_events_sacco ON ledger_period_events(sacco_id, created_at);

CREATE TABLE IF NOT EXISTS bank_statements (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    cash_account_id VARCHAR(36) NOT NULL,
    file_name VARCHAR(200) NULL,
    from_date DATE NOT NULL,
    to_date DATE NOT NULL,
    lines INT NOT NULL DEFAULT 0,
    closing_balance DECIMAL(14, 2) NULL,    -- the statement's last balance, when it has a balance column
    imported_by_id BIGINT NULL,
    created_at TIMESTAMP NOT NULL,
    CONSTRAINT fk_bank_statements_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_bank_statements_account FOREIGN KEY (cash_account_id) REFERENCES cash_accounts(id),
    CONSTRAINT fk_bank_statements_imported_by FOREIGN KEY (imported_by_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_bank_statements_account ON bank_statements(sacco_id, cash_account_id);

CREATE TABLE IF NOT EXISTS bank_statement_lines (
    id VARCHAR(36) PRIMARY KEY,
    statement_id VARCHAR(36) NOT NULL,
    sacco_id VARCHAR(36) NOT NULL,
    cash_account_id VARCHAR(36) NOT NULL,
    line_no INT NOT NULL,
    line_date DATE NOT NULL,
    description TEXT NOT NULL,
    reference VARCHAR(100) NULL,
    amount DECIMAL(14, 2) NOT NULL,         -- signed: positive is money into the account
    balance DECIMAL(14, 2) NULL,
    match_key VARCHAR(160) NULL,
    matched_by_id BIGINT NULL,
    matched_at TIMESTAMP NULL,
    CONSTRAINT fk_bank_statement_lines_statement FOREIGN KEY (statement_id) REFERENCES bank_statements(id) ON DELETE CASCADE,
    CONSTRAINT fk_bank_statement_lines_matched_by FOREIGN KEY (matched_by_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT ck_bank_statement_lines_amount CHECK (amount <> 0)
);
CREATE INDEX IF NOT EXISTS idx_bank_statement_lines_statement ON bank_statement_lines(statement_id, line_no);
CREATE UNIQUE INDEX IF NOT EXISTS uq_bank_statement_lines_match ON bank_statement_lines(cash_account_id, match_key) WHERE match_key IS NOT NULL;

-- +goose Down
DROP TABLE IF EXISTS bank_statement_lines;
DROP TABLE IF EXISTS bank_statements;
DROP TABLE IF EXISTS ledger_period_events;
ALTER TABLE ledger_books DROP COLUMN IF EXISTS year_closed_through;
ALTER TABLE ledger_books DROP COLUMN IF EXISTS closed_through;
