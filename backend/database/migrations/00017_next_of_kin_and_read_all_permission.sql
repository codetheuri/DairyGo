-- +goose Up
-- A farmer's next of kin: who the Sacco contacts, and who can claim the
-- farmer's dues, if the farmer cannot be reached. Required for new farmers;
-- farmers registered earlier keep NULL until their profile is edited.
ALTER TABLE members ADD COLUMN IF NOT EXISTS next_of_kin_name VARCHAR(191) NULL;
ALTER TABLE members ADD COLUMN IF NOT EXISTS next_of_kin_relationship VARCHAR(50) NULL;
ALTER TABLE members ADD COLUMN IF NOT EXISTS next_of_kin_phone VARCHAR(50) NULL;

-- Who sees every collector's records (collections, sales, spoilage,
-- transfers, reconciliation) instead of only their own. This used to be
-- decided by the role's name; it is now a permission like any other.
INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.records.read_all', 'Allows seeing every collector''s records, not only your own', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.records.read_all');

-- Administrators and board members, as before.
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.records.read_all', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.records.read_all');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'milk.records.read_all', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'milk.records.read_all');

-- +goose Down
DELETE FROM role_permissions WHERE permission_name = 'milk.records.read_all';
DELETE FROM permissions WHERE name = 'milk.records.read_all';
ALTER TABLE members DROP COLUMN IF EXISTS next_of_kin_phone;
ALTER TABLE members DROP COLUMN IF EXISTS next_of_kin_relationship;
ALTER TABLE members DROP COLUMN IF EXISTS next_of_kin_name;
