-- +goose Up
-- When a farmer's status last changed (by staff, by bringing milk after being
-- inactive, or automatically). A farmer made active is given the full
-- inactivity period again before being marked inactive.
ALTER TABLE members ADD COLUMN IF NOT EXISTS status_changed_at TIMESTAMP NULL;

-- Days without milk after which an active farmer is marked inactive
-- automatically; 0 turns it off. Each Sacco sets its own.
ALTER TABLE sacco_settings ADD COLUMN IF NOT EXISTS inactive_after_days INT NOT NULL DEFAULT 60;

-- +goose Down
ALTER TABLE sacco_settings DROP COLUMN IF EXISTS inactive_after_days;
ALTER TABLE members DROP COLUMN IF EXISTS status_changed_at;
