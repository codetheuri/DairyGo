-- Late customer payments. Recorded when a payment was received on an earlier
-- day or unrecorded, with late_reason and entered_by_id.

-- +goose Up
ALTER TABLE customer_payments ADD COLUMN IF NOT EXISTS late_reason TEXT NULL;
ALTER TABLE customer_payments ADD COLUMN IF NOT EXISTS entered_by_id BIGINT NULL;

-- +goose Down
ALTER TABLE customer_payments DROP COLUMN IF EXISTS entered_by_id;
ALTER TABLE customer_payments DROP COLUMN IF EXISTS late_reason;
