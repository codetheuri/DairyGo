-- A customer's selling price over time. The latest active row on or before a
-- day sets the price of a sale that day; customers.default_price_per_litre
-- follows the row in force today. The first change also saves the price
-- agreed before it as a row from the customer's first day, so earlier sales
-- keep a known price. Adding or voiding a row reprices the customer's sales
-- from its date that were sold at the agreed price (not hand-typed ones),
-- optionally including sales paid in full; see
-- internal/collection/customer_price.go.

-- +goose Up
CREATE TABLE IF NOT EXISTS customer_prices (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    customer_id VARCHAR(36) NOT NULL,
    price_per_litre DECIMAL(10, 2) NOT NULL,
    effective_date DATE NOT NULL,
    reason TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    voided_at TIMESTAMP NULL,
    void_reason TEXT NULL,
    created_by_id BIGINT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_customer_prices_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_customer_prices_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    CONSTRAINT fk_customer_prices_created_by FOREIGN KEY (created_by_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_customer_prices_customer ON customer_prices(customer_id, effective_date);

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'customers.prices.manage', 'Allows changing a customer''s price from a date, repricing their sales from then', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'customers.prices.manage');

-- Sacco administrators.
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'customers.prices.manage', CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'customers.prices.manage');

-- +goose Down
DELETE FROM role_permissions WHERE permission_name = 'customers.prices.manage';
DELETE FROM permissions WHERE name = 'customers.prices.manage';
DROP TABLE IF EXISTS customer_prices;
