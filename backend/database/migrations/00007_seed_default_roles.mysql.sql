-- +goose Up
INSERT INTO roles (id, name, description, created_at, updated_at) VALUES
(1, 'Sacco Administrator', 'Full administrative access to Sacco configuration, pricing, staff, and reports', NOW(), NOW()),
(2, 'Milk Collector', 'Field collection agent authorized to record milk intake, sales, and spoilage', NOW(), NOW()),
(3, 'Board Member / Executive', 'Executive board member with read-only dashboard and audit access', NOW(), NOW())
ON DUPLICATE KEY UPDATE name=VALUES(name), description=VALUES(description);

INSERT IGNORE INTO permissions (name, description, created_at, updated_at) VALUES
('dashboard.collector.read', 'Allows field collectors to view real-time mobile shift metrics', NOW(), NOW()),
('dashboard.executive.read', 'Allows viewing Sacco-wide executive summary dashboard cards and trend graphs', NOW(), NOW()),
('milk.prices.read', 'Allows viewing active and historical milk buying prices', NOW(), NOW()),
('milk.prices.manage', 'Allows setting new milk buying prices', NOW(), NOW()),
('milk.collections.create', 'Allows recording farmer milk intakes', NOW(), NOW()),
('milk.collections.read', 'Allows viewing milk collection records', NOW(), NOW()),
('milk.sales.create', 'Allows recording direct field sales', NOW(), NOW()),
('milk.sales.read', 'Allows viewing field sales records', NOW(), NOW()),
('milk.spoilage.create', 'Allows recording milk spoilage losses', NOW(), NOW()),
('milk.spoilage.read', 'Allows viewing milk spoilage records', NOW(), NOW()),
('members.read', 'Allows viewing registered Sacco farmers', NOW(), NOW()),
('members.create', 'Allows registering new Sacco farmers', NOW(), NOW()),
('reports.payout.read', 'Allows viewing farmer payroll and payout reports', NOW(), NOW()),
('reports.reconciliation.read', 'Allows viewing Sacco balancing ledgers', NOW(), NOW()),
('reports.collector.read', 'Allows viewing collector audit reports', NOW(), NOW()),
('sacco.settings.manage', 'Allows managing Sacco profile and milk buying price rates', NOW(), NOW()),
('users.read', 'Allows viewing user accounts', NOW(), NOW()),
('users.create', 'Allows registering new user accounts', NOW(), NOW());

-- Attach Permissions to Role 2: Milk Collector
INSERT IGNORE INTO role_permissions (role_id, permission_name, created_at) VALUES
(2, 'dashboard.collector.read', NOW()),
(2, 'milk.prices.read', NOW()),
(2, 'milk.collections.create', NOW()),
(2, 'milk.collections.read', NOW()),
(2, 'milk.sales.create', NOW()),
(2, 'milk.sales.read', NOW()),
(2, 'milk.spoilage.create', NOW()),
(2, 'milk.spoilage.read', NOW()),
(2, 'members.read', NOW()),
(2, 'members.create', NOW());

-- Attach Permissions to Role 3: Board Member / Executive
INSERT IGNORE INTO role_permissions (role_id, permission_name, created_at) VALUES
(3, 'dashboard.executive.read', NOW()),
(3, 'dashboard.collector.read', NOW()),
(3, 'milk.prices.read', NOW()),
(3, 'reports.payout.read', NOW()),
(3, 'reports.reconciliation.read', NOW()),
(3, 'reports.collector.read', NOW()),
(3, 'members.read', NOW()),
(3, 'milk.collections.read', NOW()),
(3, 'milk.sales.read', NOW()),
(3, 'milk.spoilage.read', NOW());

-- Attach Permissions to Role 1: Sacco Administrator
INSERT IGNORE INTO role_permissions (role_id, permission_name, created_at) VALUES
(1, 'dashboard.collector.read', NOW()),
(1, 'dashboard.executive.read', NOW()),
(1, 'milk.prices.read', NOW()),
(1, 'milk.prices.manage', NOW()),
(1, 'milk.collections.create', NOW()),
(1, 'milk.collections.read', NOW()),
(1, 'milk.sales.create', NOW()),
(1, 'milk.sales.read', NOW()),
(1, 'milk.spoilage.create', NOW()),
(1, 'milk.spoilage.read', NOW()),
(1, 'members.read', NOW()),
(1, 'members.create', NOW()),
(1, 'reports.payout.read', NOW()),
(1, 'reports.reconciliation.read', NOW()),
(1, 'reports.collector.read', NOW()),
(1, 'sacco.settings.manage', NOW()),
(1, 'users.read', NOW()),
(1, 'users.create', NOW());

-- +goose Down
DELETE FROM role_permissions WHERE role_id IN (1, 2, 3);
DELETE FROM roles WHERE id IN (1, 2, 3);
