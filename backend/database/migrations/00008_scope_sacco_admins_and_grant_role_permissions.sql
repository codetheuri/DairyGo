-- Sacco admins were created as platform super users, which let them manage every
-- Sacco on the platform. This migration turns them into regular Sacco
-- Administrators (role 1) and grants the Sacco roles the permissions they
-- previously only reached through the super-user bypass.

-- +goose Up

-- Permissions must exist before they can be granted (role_permissions FK).
INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'members.update', 'Allows editing farmer member profiles', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'members.update');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'members.update_status', 'Allows activating, deactivating or suspending farmer members', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'members.update_status');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.collections.manage', 'Allows verifying, rejecting, or adjusting milk collection entries', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.collections.manage');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.sales.manage', 'Allows managing direct milk sales records', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.sales.manage');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.reconciliation.read', 'Allows viewing collector daily milk reconciliation summaries', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.reconciliation.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'notifications.sms.send', 'Allows sending SMS notifications', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'notifications.sms.send');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'notifications.sms.read', 'Allows viewing SMS notification logs', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'notifications.sms.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'sacco.settings.read', 'Allows viewing Sacco operational settings', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'sacco.settings.read');

-- Role 1: Sacco Administrator
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'members.update', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'members.update');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'members.update_status', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'members.update_status');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.collections.manage', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.collections.manage');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.sales.manage', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.sales.manage');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.reconciliation.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.reconciliation.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'notifications.sms.send', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'notifications.sms.send');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'notifications.sms.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'notifications.sms.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'sacco.settings.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'sacco.settings.read');

-- Role 2: Milk Collector (own daily reconciliation in the field operations screen)
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'milk.reconciliation.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'milk.reconciliation.read');

-- Role 3: Board Member / Executive (read-only)
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'milk.reconciliation.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'milk.reconciliation.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'sacco.settings.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'sacco.settings.read');

-- Existing Sacco-bound super users become Sacco Administrators.
INSERT INTO user_roles (user_id, role_id, created_at)
SELECT u.id, 1, CURRENT_TIMESTAMP
FROM users u
WHERE u.is_super_user = TRUE
  AND u.sacco_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM user_roles ur WHERE ur.user_id = u.id AND ur.role_id = 1);

UPDATE users SET is_super_user = FALSE WHERE is_super_user = TRUE AND sacco_id IS NOT NULL;

-- +goose Down
-- The super-user downgrade is intentionally not reverted: restoring it would
-- reopen cross-Sacco access. Only the permission grants are removed.
DELETE FROM role_permissions WHERE role_id = 1 AND permission_name IN (
    'members.update', 'members.update_status', 'milk.collections.manage', 'milk.sales.manage',
    'milk.reconciliation.read', 'notifications.sms.send', 'notifications.sms.read', 'sacco.settings.read'
);
DELETE FROM role_permissions WHERE role_id = 2 AND permission_name = 'milk.reconciliation.read';
DELETE FROM role_permissions WHERE role_id = 3 AND permission_name IN ('milk.reconciliation.read', 'sacco.settings.read');
