-- Permissions for the customer module (00010).

-- +goose Up
INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'customers.read', 'Allows viewing customers (coolers, processors, hotels, buyers)', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'customers.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'customers.create', 'Allows adding new customers, e.g. while recording a sale', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'customers.create');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'customers.update', 'Allows editing and deactivating customers', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'customers.update');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'customers.payments.manage', 'Allows recording and voiding customer payments', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'customers.payments.manage');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'customers.statement.read', 'Allows viewing customer statements and outstanding balances', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'customers.statement.read');

INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'customers.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'customers.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'customers.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'customers.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'customers.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'customers.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'customers.create', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'customers.create');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'customers.create', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'customers.create');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'customers.update', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'customers.update');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'customers.payments.manage', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'customers.payments.manage');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'customers.statement.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'customers.statement.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'customers.statement.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'customers.statement.read');

-- +goose Down
DELETE FROM role_permissions WHERE permission_name IN ('customers.read', 'customers.create', 'customers.update', 'customers.payments.manage', 'customers.statement.read');
DELETE FROM permissions WHERE name IN ('customers.read', 'customers.create', 'customers.update', 'customers.payments.manage', 'customers.statement.read');
