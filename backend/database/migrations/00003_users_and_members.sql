-- +goose Up
CREATE TABLE IF NOT EXISTS members (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    membership_number VARCHAR(50) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    national_id VARCHAR(50) NULL,
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(191) NULL,
    gender VARCHAR(20) NULL DEFAULT 'OTHER',
    location VARCHAR(191) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    mpesa_number VARCHAR(50) NULL,
    mpesa_name VARCHAR(100) NULL,
    bank_name VARCHAR(100) NULL,
    bank_account_number VARCHAR(50) NULL,
    bank_branch VARCHAR(100) NULL,
    registered_by_id BIGINT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,
    CONSTRAINT fk_members_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_members_registered_by FOREIGN KEY (registered_by_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT uq_sacco_membership UNIQUE (sacco_id, membership_number)
);

CREATE INDEX IF NOT EXISTS idx_members_sacco_status ON members(sacco_id, status);
CREATE INDEX IF NOT EXISTS idx_members_phone ON members(sacco_id, phone);
CREATE INDEX IF NOT EXISTS idx_members_national_id ON members(sacco_id, national_id);

-- +goose Down
DROP TABLE IF EXISTS members;
