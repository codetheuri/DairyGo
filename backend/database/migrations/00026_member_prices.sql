-- A farmer's own buying price. Most farmers are paid the Sacco's price
-- (milk_prices); some are agreed a different one (e.g. 45 instead of 42)
-- from a date. Rows form the farmer's schedule: the latest row on or before
-- a day sets that day's price; price_per_litre NULL means "back to the
-- Sacco's price" from that date. Adding or voiding a row reprices the
-- farmer's milk from its date that is not yet paid (see
-- internal/collection/member_price.go); paid months never change.

-- +goose Up
CREATE TABLE IF NOT EXISTS member_prices (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    member_id VARCHAR(36) NOT NULL,
    price_per_litre DECIMAL(10, 2) NULL,   -- NULL: the Sacco's price again
    effective_date DATE NOT NULL,
    reason TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    voided_at TIMESTAMP NULL,
    void_reason TEXT NULL,
    created_by_id BIGINT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_member_prices_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_member_prices_member FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
    CONSTRAINT fk_member_prices_created_by FOREIGN KEY (created_by_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_member_prices_member ON member_prices(member_id, effective_date);

-- +goose Down
DROP TABLE IF EXISTS member_prices;
