-- Generic audit history for business records (collections now; sales,
-- customers and payments later), and the switch to effective-date pricing.

-- +goose Up
CREATE TABLE IF NOT EXISTS audit_logs (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(36) NOT NULL,
    action VARCHAR(20) NOT NULL, -- CREATE, UPDATE, STATUS, VOID
    actor_id BIGINT NULL,
    reason TEXT NULL,
    old_values TEXT NULL, -- JSON
    new_values TEXT NULL, -- JSON
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_logs_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_audit_logs_actor FOREIGN KEY (actor_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(sacco_id, entity_type, entity_id, created_at);

-- Prices are now chosen by effective_date, and is_active only marks a price
-- row as voided. Setting a new price used to deactivate the previous one, so
-- every existing row is valid history and must be active again.
UPDATE milk_prices SET is_active = TRUE WHERE is_active = FALSE;

-- +goose Down
DROP TABLE IF EXISTS audit_logs;
