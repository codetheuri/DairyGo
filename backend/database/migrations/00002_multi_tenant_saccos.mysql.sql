-- +goose Up
CREATE TABLE IF NOT EXISTS saccos (
    id VARCHAR(36) PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(191) NOT NULL,
    email VARCHAR(191) NULL,
    phone VARCHAR(50) NULL,
    address TEXT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME(3) NULL,
    updated_at DATETIME(3) NULL,
    deleted_at DATETIME(3) NULL
);

CREATE INDEX idx_saccos_status ON saccos(status);
CREATE INDEX idx_saccos_code ON saccos(code);

CREATE TABLE IF NOT EXISTS sacco_settings (
    sacco_id VARCHAR(36) PRIMARY KEY,
    currency VARCHAR(10) NOT NULL DEFAULT 'KES',
    milk_unit VARCHAR(10) NOT NULL DEFAULT 'LITRES',
    morning_cutoff_time TIME NULL DEFAULT '12:00:00',
    evening_cutoff_time TIME NULL DEFAULT '20:00:00',
    created_at DATETIME(3) NULL,
    updated_at DATETIME(3) NULL,
    CONSTRAINT fk_sacco_settings_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE
);

ALTER TABLE users 
    ADD COLUMN sacco_id VARCHAR(36) NULL AFTER id,
    ADD CONSTRAINT fk_users_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE SET NULL,
    ADD INDEX idx_users_sacco_id (sacco_id);

-- +goose Down
ALTER TABLE users 
    DROP FOREIGN KEY fk_users_sacco,
    DROP INDEX idx_users_sacco_id,
    DROP COLUMN sacco_id;

DROP TABLE IF EXISTS sacco_settings;
DROP TABLE IF EXISTS saccos;
