-- The Sacco's books (phase 2, see docs/books.md): a double-entry ledger kept
-- from the records staff already make.
--   * ledger_books: a Sacco's books once started: the date they start from
--     and the last journal number given.
--   * ledger_accounts: the chart of accounts (editable; never deleted once
--     used).
--   * ledger_links: where each kind of record posts: a cash account, an
--     expense category, a deduction, or a role such as "customers"
--     (link_key "cash_account:<id>", "expense_category:<id>",
--     "deduction_type:<id>", "role:CUSTOMERS").
--   * journals / journal_lines: balanced entries. Automatic ones follow a
--     record (source_type/source_id, and source_key when one record makes
--     more than one); a changed or voided record gets a reversal and a new
--     journal, never an edit. Manual ones are the accountant's.

-- +goose Up
CREATE TABLE IF NOT EXISTS ledger_books (
    sacco_id VARCHAR(36) PRIMARY KEY,
    start_date DATE NOT NULL,
    next_number BIGINT NOT NULL DEFAULT 0,
    synced_at TIMESTAMP NULL,
    started_by_id BIGINT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_ledger_books_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_ledger_books_started_by FOREIGN KEY (started_by_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS ledger_accounts (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(120) NOT NULL,
    type VARCHAR(10) NOT NULL,
    description TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_ledger_accounts_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT ck_ledger_accounts_type CHECK (type IN ('ASSET', 'LIABILITY', 'EQUITY', 'INCOME', 'EXPENSE'))
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_ledger_accounts_code ON ledger_accounts(sacco_id, code);

CREATE TABLE IF NOT EXISTS ledger_links (
    sacco_id VARCHAR(36) NOT NULL,
    link_key VARCHAR(80) NOT NULL,
    account_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    PRIMARY KEY (sacco_id, link_key),
    CONSTRAINT fk_ledger_links_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_ledger_links_account FOREIGN KEY (account_id) REFERENCES ledger_accounts(id)
);

CREATE TABLE IF NOT EXISTS journals (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    number BIGINT NOT NULL,
    journal_date DATE NOT NULL,
    kind VARCHAR(10) NOT NULL,              -- AUTO (from a record) or MANUAL
    source_type VARCHAR(30) NULL,
    source_id VARCHAR(80) NULL,
    source_key VARCHAR(80) NULL,
    memo TEXT NOT NULL,
    reference VARCHAR(100) NULL,
    total DECIMAL(14, 2) NOT NULL,
    reverses_id VARCHAR(36) NULL,
    reversed_by_id VARCHAR(36) NULL,
    reason TEXT NULL,
    created_by_id BIGINT NULL,
    created_at TIMESTAMP NULL,
    CONSTRAINT fk_journals_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_journals_reverses FOREIGN KEY (reverses_id) REFERENCES journals(id),
    CONSTRAINT fk_journals_reversed_by FOREIGN KEY (reversed_by_id) REFERENCES journals(id),
    CONSTRAINT fk_journals_created_by FOREIGN KEY (created_by_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT ck_journals_kind CHECK (kind IN ('AUTO', 'MANUAL'))
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_journals_number ON journals(sacco_id, number);
CREATE INDEX IF NOT EXISTS idx_journals_date ON journals(sacco_id, journal_date);
CREATE INDEX IF NOT EXISTS idx_journals_source ON journals(sacco_id, source_type, source_id);

CREATE TABLE IF NOT EXISTS journal_lines (
    id VARCHAR(36) PRIMARY KEY,
    journal_id VARCHAR(36) NOT NULL,
    sacco_id VARCHAR(36) NOT NULL,
    line_no INT NOT NULL,
    account_id VARCHAR(36) NOT NULL,
    link_key VARCHAR(80) NULL,              -- what an automatic line posted for
    journal_date DATE NOT NULL,             -- the journal's, for account ledgers
    debit DECIMAL(14, 2) NOT NULL DEFAULT 0,
    credit DECIMAL(14, 2) NOT NULL DEFAULT 0,
    memo TEXT NULL,
    CONSTRAINT fk_journal_lines_journal FOREIGN KEY (journal_id) REFERENCES journals(id) ON DELETE CASCADE,
    CONSTRAINT fk_journal_lines_account FOREIGN KEY (account_id) REFERENCES ledger_accounts(id),
    CONSTRAINT ck_journal_lines_amounts CHECK (debit >= 0 AND credit >= 0 AND (debit = 0 OR credit = 0))
);
CREATE INDEX IF NOT EXISTS idx_journal_lines_journal ON journal_lines(journal_id);
CREATE INDEX IF NOT EXISTS idx_journal_lines_account ON journal_lines(sacco_id, account_id, journal_date);

-- +goose Down
DROP TABLE IF EXISTS journal_lines;
DROP TABLE IF EXISTS journals;
DROP TABLE IF EXISTS ledger_links;
DROP TABLE IF EXISTS ledger_accounts;
DROP TABLE IF EXISTS ledger_books;
