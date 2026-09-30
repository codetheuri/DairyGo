-- Milk handed from one collector to another (for example to share a route
-- or a vehicle). It counts for both at once: it leaves the sender's balance
-- and joins the receiver's:
--   collected + received - sold - transferred out - spoiled = unaccounted
-- Across the Sacco, transfers cancel out.

-- +goose Up
CREATE TABLE IF NOT EXISTS milk_transfers (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    from_collector_id BIGINT NOT NULL,
    to_collector_id BIGINT NOT NULL,
    transfer_date DATE NOT NULL,
    quantity_litres DECIMAL(10, 2) NOT NULL,
    notes TEXT NULL,
    recorded_by_id BIGINT NOT NULL,
    voided_at TIMESTAMP NULL,
    void_reason TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,

    CONSTRAINT fk_transfer_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_transfer_from FOREIGN KEY (from_collector_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_transfer_to FOREIGN KEY (to_collector_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_transfer_recorded_by FOREIGN KEY (recorded_by_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT chk_transfer_positive CHECK (quantity_litres > 0),
    CONSTRAINT chk_transfer_two_collectors CHECK (from_collector_id <> to_collector_id)
);

CREATE INDEX IF NOT EXISTS idx_transfers_sacco_date ON milk_transfers(sacco_id, transfer_date);
CREATE INDEX IF NOT EXISTS idx_transfers_from_date ON milk_transfers(sacco_id, from_collector_id, transfer_date);
CREATE INDEX IF NOT EXISTS idx_transfers_to_date ON milk_transfers(sacco_id, to_collector_id, transfer_date);

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.transfers.read', 'Allows viewing milk transfers between collectors', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.transfers.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.transfers.create', 'Allows transferring milk to another collector, and correcting or cancelling own transfers the same day', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.transfers.create');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.transfers.manage', 'Allows recording transfers for any collector and correcting or cancelling any transfer', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.transfers.manage');

-- Administrators: all; collectors: read and create; board members: read.
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.transfers.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.transfers.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.transfers.create', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.transfers.create');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.transfers.manage', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.transfers.manage');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'milk.transfers.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'milk.transfers.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'milk.transfers.create', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'milk.transfers.create');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'milk.transfers.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'milk.transfers.read');

-- +goose Down
DELETE FROM role_permissions WHERE permission_name IN ('milk.transfers.read', 'milk.transfers.create', 'milk.transfers.manage');
DELETE FROM permissions WHERE name IN ('milk.transfers.read', 'milk.transfers.create', 'milk.transfers.manage');
DROP TABLE IF EXISTS milk_transfers;
