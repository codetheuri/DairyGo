-- +goose Up
-- Removing a staff account keeps the row, so the collections, sales and
-- transfers they recorded still show their name. A removed account cannot sign
-- in and is left out of staff lists.
ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_by_id BIGINT NULL;

-- Usernames, emails and phones are unique among accounts that still exist, so
-- a removed person's details can be used again (e.g. a collector who returns).
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_username_key;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_phone_key;
DROP INDEX IF EXISTS idx_users_username;
DROP INDEX IF EXISTS idx_users_email;
DROP INDEX IF EXISTS idx_users_phone;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username_live ON users(username) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_live ON users(email) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone_live ON users(phone) WHERE deleted_at IS NULL;

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'users.update', 'Allows changing a staff account''s role', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'users.update');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'users.delete', 'Allows removing staff accounts', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'users.delete');

-- Sacco administrators only.
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'users.update', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'users.update');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'users.delete', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'users.delete');

-- +goose Down
DELETE FROM role_permissions WHERE role_id = 1 AND permission_name IN ('users.update', 'users.delete');

-- Removed accounts may share details with newer ones; make them distinct
-- before the plain unique constraints return.
UPDATE users SET
    username = LEFT(username, 150) || '#removed' || id,
    email = LEFT(email, 150) || '#removed' || id,
    phone = CASE WHEN phone IS NULL THEN NULL ELSE LEFT(phone, 30) || '#' || id END
WHERE deleted_at IS NOT NULL;

DROP INDEX IF EXISTS idx_users_username_live;
DROP INDEX IF EXISTS idx_users_email_live;
DROP INDEX IF EXISTS idx_users_phone_live;
ALTER TABLE users ADD CONSTRAINT users_username_key UNIQUE (username);
ALTER TABLE users ADD CONSTRAINT users_email_key UNIQUE (email);
ALTER TABLE users ADD CONSTRAINT users_phone_key UNIQUE (phone);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);

ALTER TABLE users DROP COLUMN IF EXISTS deleted_by_id;
ALTER TABLE users DROP COLUMN IF EXISTS deleted_at;
