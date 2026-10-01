-- +goose Up
-- A Sacco's logo, printed on its reports (PNG or JPEG, at most 512 KB).
-- Kept in the database so it is backed up with everything else and needs
-- no file storage on the server.
ALTER TABLE saccos ADD COLUMN IF NOT EXISTS logo BYTEA NULL;
ALTER TABLE saccos ADD COLUMN IF NOT EXISTS logo_type VARCHAR(32) NULL;

-- +goose Down
ALTER TABLE saccos DROP COLUMN IF EXISTS logo_type;
ALTER TABLE saccos DROP COLUMN IF EXISTS logo;
