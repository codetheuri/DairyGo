-- +goose Up
CREATE TABLE IF NOT EXISTS saccos (
    id VARCHAR(36) PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(191) NOT NULL,
    email VARCHAR(191) NULL,
    phone VARCHAR(50) NULL,
    address TEXT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX IF NOT EXISTS idx_saccos_status ON saccos(status);
CREATE INDEX IF NOT EXISTS idx_saccos_code ON saccos(code);

CREATE TABLE IF NOT EXISTS sacco_settings (
    sacco_id VARCHAR(36) PRIMARY KEY,
    currency VARCHAR(10) NOT NULL DEFAULT 'KES',
    milk_unit VARCHAR(10) NOT NULL DEFAULT 'LITRES',
    morning_cutoff_time TIME NULL DEFAULT '12:00:00',
    evening_cutoff_time TIME NULL DEFAULT '20:00:00',
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_sacco_settings_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE
);

ALTER TABLE users 
    ADD COLUMN sacco_id VARCHAR(36) NULL;

ALTER TABLE users
    ADD CONSTRAINT fk_users_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_users_sacco_id ON users(sacco_id);

-- +goose Down
ALTER TABLE users DROP CONSTRAINT fk_users_sacco;
DROP INDEX IF EXISTS idx_users_sacco_id;
ALTER TABLE users DROP COLUMN sacco_id;

DROP TABLE IF EXISTS sacco_settings;
DROP TABLE IF EXISTS saccos;
