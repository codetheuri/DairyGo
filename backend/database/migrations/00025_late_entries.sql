-- Late entries. Sacco staff record milk (intake, sales, spoilage, transfers)
-- only for today; an earlier day is entered by DairyGo support from the
-- platform console, with a reason. These columns mark such records:
--   late_reason    why the day was entered late
--   entered_by_id  the platform user who entered it (collector_id stays the
--                  collector the milk belongs to)

-- +goose Up
ALTER TABLE milk_collections ADD COLUMN IF NOT EXISTS late_reason TEXT NULL;
ALTER TABLE milk_collections ADD COLUMN IF NOT EXISTS entered_by_id BIGINT NULL;
ALTER TABLE milk_sales ADD COLUMN IF NOT EXISTS late_reason TEXT NULL;
ALTER TABLE milk_sales ADD COLUMN IF NOT EXISTS entered_by_id BIGINT NULL;
ALTER TABLE milk_spoilage ADD COLUMN IF NOT EXISTS late_reason TEXT NULL;
ALTER TABLE milk_spoilage ADD COLUMN IF NOT EXISTS entered_by_id BIGINT NULL;
ALTER TABLE milk_transfers ADD COLUMN IF NOT EXISTS late_reason TEXT NULL;
ALTER TABLE milk_transfers ADD COLUMN IF NOT EXISTS entered_by_id BIGINT NULL;

-- +goose Down
ALTER TABLE milk_transfers DROP COLUMN IF EXISTS entered_by_id;
ALTER TABLE milk_transfers DROP COLUMN IF EXISTS late_reason;
ALTER TABLE milk_spoilage DROP COLUMN IF EXISTS entered_by_id;
ALTER TABLE milk_spoilage DROP COLUMN IF EXISTS late_reason;
ALTER TABLE milk_sales DROP COLUMN IF EXISTS entered_by_id;
ALTER TABLE milk_sales DROP COLUMN IF EXISTS late_reason;
ALTER TABLE milk_collections DROP COLUMN IF EXISTS entered_by_id;
ALTER TABLE milk_collections DROP COLUMN IF EXISTS late_reason;
