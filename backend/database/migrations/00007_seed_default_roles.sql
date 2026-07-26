-- +goose Up
INSERT INTO roles (id, name, description, created_at, updated_at)
SELECT 1, 'Sacco Administrator', 'Full administrative access to Sacco configuration, pricing, staff, and reports', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE id = 1);

INSERT INTO roles (id, name, description, created_at, updated_at)
SELECT 2, 'Milk Collector', 'Field collection agent authorized to record milk intake, sales, and spoilage', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE id = 2);

INSERT INTO roles (id, name, description, created_at, updated_at)
SELECT 3, 'Board Member / Executive', 'Executive board member with read-only dashboard and audit access', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE id = 3);

-- Seed Permissions
INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'dashboard.collector.read', 'Allows field collectors to view real-time mobile shift metrics', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'dashboard.collector.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'dashboard.executive.read', 'Allows viewing Sacco-wide executive summary dashboard cards and trend graphs', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'dashboard.executive.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.prices.read', 'Allows viewing active and historical milk buying prices', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.prices.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.prices.manage', 'Allows setting new milk buying prices', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.prices.manage');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.collections.create', 'Allows recording farmer milk intakes', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.collections.create');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.collections.read', 'Allows viewing milk collection records', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.collections.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.sales.create', 'Allows recording direct field sales', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.sales.create');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.sales.read', 'Allows viewing field sales records', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.sales.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.spoilage.create', 'Allows recording milk spoilage losses', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.spoilage.create');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'milk.spoilage.read', 'Allows viewing milk spoilage records', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'milk.spoilage.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'members.read', 'Allows viewing registered Sacco farmers', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'members.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'members.create', 'Allows registering new Sacco farmers', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'members.create');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'reports.payout.read', 'Allows viewing farmer payroll and payout reports', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'reports.payout.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'reports.reconciliation.read', 'Allows viewing Sacco balancing ledgers', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'reports.reconciliation.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'reports.collector.read', 'Allows viewing collector audit reports', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'reports.collector.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'sacco.settings.manage', 'Allows managing Sacco profile and milk buying price rates', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'sacco.settings.manage');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'users.read', 'Allows viewing user accounts', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'users.read');

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'users.create', 'Allows registering new user accounts', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'users.create');

-- Attach Permissions to Role 2: Milk Collector
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'dashboard.collector.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'dashboard.collector.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'milk.prices.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'milk.prices.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'milk.collections.create', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'milk.collections.create');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'milk.collections.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'milk.collections.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'milk.sales.create', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'milk.sales.create');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'milk.sales.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'milk.sales.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'milk.spoilage.create', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'milk.spoilage.create');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'milk.spoilage.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'milk.spoilage.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'members.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'members.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 2, 'members.create', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 2 AND permission_name = 'members.create');

-- Attach Permissions to Role 3: Board Member / Executive
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'dashboard.executive.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'dashboard.executive.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'dashboard.collector.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'dashboard.collector.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'milk.prices.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'milk.prices.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'reports.payout.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'reports.payout.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'reports.reconciliation.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'reports.reconciliation.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'reports.collector.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'reports.collector.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'members.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'members.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'milk.collections.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'milk.collections.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'milk.sales.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'milk.sales.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 3, 'milk.spoilage.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 3 AND permission_name = 'milk.spoilage.read');

-- Attach Permissions to Role 1: Sacco Administrator
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'dashboard.collector.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'dashboard.collector.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'dashboard.executive.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'dashboard.executive.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.prices.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.prices.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.prices.manage', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.prices.manage');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.collections.create', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.collections.create');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.collections.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.collections.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.sales.create', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.sales.create');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.sales.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.sales.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.spoilage.create', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.spoilage.create');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'milk.spoilage.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'milk.spoilage.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'members.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'members.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'members.create', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'members.create');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'reports.payout.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'reports.payout.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'reports.reconciliation.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'reports.reconciliation.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'reports.collector.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'reports.collector.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'sacco.settings.manage', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'sacco.settings.manage');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'users.read', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'users.read');
INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT 1, 'users.create', CURRENT_TIMESTAMP WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role_id = 1 AND permission_name = 'users.create');

-- +goose Down
DELETE FROM role_permissions WHERE role_id IN (1, 2, 3);
DELETE FROM roles WHERE id IN (1, 2, 3);
