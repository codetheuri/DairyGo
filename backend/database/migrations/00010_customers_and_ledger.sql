-- Customers and the customer ledger. Every litre leaving a collector is now a
-- sale to a customer (coolers, processors, hotels, shops, individuals), and
-- credit sales are settled through customer payments on a running balance.

-- +goose Up
CREATE TABLE IF NOT EXISTS customers (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(50) NULL,
    customer_type VARCHAR(20) NOT NULL DEFAULT 'OTHER', -- COOLER, PROCESSOR, HOTEL, SHOP, INDIVIDUAL, OTHER
    default_price_per_litre DECIMAL(10, 2) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, INACTIVE
    notes TEXT NULL,
    created_by_id BIGINT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,
    CONSTRAINT fk_customers_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_customers_created_by FOREIGN KEY (created_by_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_customers_sacco_phone ON customers(sacco_id, phone) WHERE phone IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_customers_sacco_name ON customers(sacco_id, name);

CREATE TABLE IF NOT EXISTS customer_payments (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    customer_id VARCHAR(36) NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    payment_date DATE NOT NULL,
    method VARCHAR(20) NOT NULL DEFAULT 'CASH', -- CASH, MPESA, BANK_TRANSFER, CHEQUE
    reference VARCHAR(100) NULL, -- e.g. M-Pesa transaction code
    notes TEXT NULL,
    recorded_by_id BIGINT NULL,
    voided_at TIMESTAMP NULL,
    void_reason TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_customer_payments_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_customer_payments_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT,
    CONSTRAINT fk_customer_payments_recorded_by FOREIGN KEY (recorded_by_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_customer_payments_customer ON customer_payments(sacco_id, customer_id, payment_date);

-- Sales now belong to a customer and record what was paid at the time of sale.
ALTER TABLE milk_sales ADD COLUMN IF NOT EXISTS customer_id VARCHAR(36) NULL;
ALTER TABLE milk_sales ADD COLUMN IF NOT EXISTS amount_paid DECIMAL(12, 2) NOT NULL DEFAULT 0;
ALTER TABLE milk_sales ADD COLUMN IF NOT EXISTS voided_at TIMESTAMP NULL;
ALTER TABLE milk_sales ADD COLUMN IF NOT EXISTS void_reason TEXT NULL;

-- Backfill: one customer per distinct buyer in each Sacco. Buyers with a phone
-- are grouped by phone (phone is unique per Sacco); the rest by name,
-- ignoring case. The most recently used spelling becomes the customer name.
INSERT INTO customers (id, sacco_id, name, phone, customer_type, status, created_at, updated_at)
SELECT gen_random_uuid()::text, b.sacco_id, (ARRAY_AGG(b.name ORDER BY b.created_at DESC NULLS LAST))[1], b.phone, 'OTHER', 'ACTIVE', MIN(b.created_at), CURRENT_TIMESTAMP
FROM (
    SELECT sacco_id,
           TRIM(buyer_name) AS name,
           NULLIF(TRIM(buyer_phone), '') AS phone,
           COALESCE(NULLIF(TRIM(buyer_phone), ''), 'name:' || LOWER(TRIM(buyer_name))) AS buyer_key,
           created_at
    FROM milk_sales
    WHERE customer_id IS NULL
) b
GROUP BY b.sacco_id, b.buyer_key, b.phone;

UPDATE milk_sales s
SET customer_id = c.id
FROM customers c
WHERE s.customer_id IS NULL
  AND c.sacco_id = s.sacco_id
  AND (
        (NULLIF(TRIM(s.buyer_phone), '') IS NOT NULL AND c.phone = NULLIF(TRIM(s.buyer_phone), ''))
     OR (NULLIF(TRIM(s.buyer_phone), '') IS NULL AND c.phone IS NULL AND LOWER(c.name) = LOWER(TRIM(s.buyer_name)))
  );

-- Only PAID sales are known to be fully settled. PENDING and PARTIAL amounts
-- were never captured, so they start as owed; admins record payments against them.
UPDATE milk_sales SET amount_paid = total_amount WHERE payment_status = 'PAID';

ALTER TABLE milk_sales ALTER COLUMN customer_id SET NOT NULL;
ALTER TABLE milk_sales ADD CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS idx_sales_customer_date ON milk_sales(sacco_id, customer_id, sale_date);

-- +goose Down
DROP INDEX IF EXISTS idx_sales_customer_date;
ALTER TABLE milk_sales DROP CONSTRAINT IF EXISTS fk_sales_customer;
ALTER TABLE milk_sales DROP COLUMN IF EXISTS void_reason;
ALTER TABLE milk_sales DROP COLUMN IF EXISTS voided_at;
ALTER TABLE milk_sales DROP COLUMN IF EXISTS amount_paid;
ALTER TABLE milk_sales DROP COLUMN IF EXISTS customer_id;
DROP TABLE IF EXISTS customer_payments;
DROP TABLE IF EXISTS customers;
