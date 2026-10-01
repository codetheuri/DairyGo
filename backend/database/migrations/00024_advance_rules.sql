-- Two more rules for advances, both set per Sacco and both optional:
--   advance_last_day      advances are given only from the 1st up to this day
--                         of the month (e.g. 15)
--   advance_milk_percent  an advance may not go past this share of the milk a
--                         farmer has delivered since the last pay run, less
--                         what they already owe (100 = the full milk value)
-- Payslip SMS were taken out of the app for now, so sms_sent_at goes.

-- +goose Up
ALTER TABLE sacco_settings ADD COLUMN IF NOT EXISTS advance_last_day INT NULL;
ALTER TABLE sacco_settings ADD COLUMN IF NOT EXISTS advance_milk_percent INT NULL;
ALTER TABLE pay_runs DROP COLUMN IF EXISTS sms_sent_at;

-- +goose Down
ALTER TABLE pay_runs ADD COLUMN IF NOT EXISTS sms_sent_at TIMESTAMP NULL;
ALTER TABLE sacco_settings DROP COLUMN IF EXISTS advance_milk_percent;
ALTER TABLE sacco_settings DROP COLUMN IF EXISTS advance_last_day;
