-- Reconciliation now balances collected milk against sales and spoilage
-- (unaccounted = collected - sold - spoiled). Each Sacco can tolerate a small
-- measuring difference, in litres per collector per day.

-- +goose Up
ALTER TABLE sacco_settings ADD COLUMN IF NOT EXISTS reconciliation_tolerance_litres DECIMAL(10, 2) NOT NULL DEFAULT 0;

-- +goose Down
ALTER TABLE sacco_settings DROP COLUMN IF EXISTS reconciliation_tolerance_litres;
