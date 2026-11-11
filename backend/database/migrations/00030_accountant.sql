-- The Sacco's accountant (phase 1 of the books, see docs/finance.md):
--   * role 4 "Accountant": money and books, no milk recording. The app shows
--     them their own layout from these permissions, never from the role name.
--     They prepare and pay pay runs but do not approve them, so the person who
--     prepares is never the one who approves.
--   * books.read / books.manage: the books (financial year now; the ledger,
--     journals and statements come in the next phases).
--   * sacco_settings.financial_year_start_month: when the Sacco's financial
--     year starts (1 = January), changeable at any time.

-- +goose Up
-- +goose StatementBegin
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM roles WHERE id = 4 AND name <> 'Accountant') THEN
        RAISE EXCEPTION 'role 4 is already used by "%"; move it before adding the Accountant role',
            (SELECT name FROM roles WHERE id = 4);
    END IF;
END $$;
-- +goose StatementEnd

INSERT INTO roles (id, name, description, created_at, updated_at)
SELECT 4, 'Accountant', 'Keeps the Sacco''s books: money in and out, farmer pay (prepares and pays, does not approve), customer payments and reports', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE id = 4);
SELECT setval(pg_get_serial_sequence('roles', 'id'), GREATEST((SELECT MAX(id) FROM roles), 4));

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT p.name, p.description, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM (VALUES
    ('books.read', 'Allows viewing the books: financial year, ledger, journals and statements'),
    ('books.manage', 'Allows keeping the books: setting the financial year, journals and closing periods')
) AS p(name, description)
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE permissions.name = p.name);

INSERT INTO role_permissions (role_id, permission_name, created_at)
SELECT g.role_id, g.name, CURRENT_TIMESTAMP
FROM (VALUES
    (1, 'books.read'), (1, 'books.manage'),
    (4, 'books.read'), (4, 'books.manage'),
    (4, 'finance.read'), (4, 'finance.expenses.manage'), (4, 'finance.accounts.manage'),
    (4, 'payouts.read'), (4, 'payouts.runs.manage'), (4, 'payouts.runs.pay'),
    (4, 'payouts.advances.manage'), (4, 'payouts.charges.manage'),
    (4, 'customers.read'), (4, 'customers.statement.read'), (4, 'customers.payments.manage'),
    (4, 'reports.payout.read'), (4, 'reports.reconciliation.read'),
    (4, 'members.read'), (4, 'milk.prices.read'), (4, 'sacco.settings.read')
) AS g(role_id, name)
WHERE NOT EXISTS (SELECT 1 FROM role_permissions r WHERE r.role_id = g.role_id AND r.permission_name = g.name);

ALTER TABLE sacco_settings ADD COLUMN IF NOT EXISTS financial_year_start_month INT NOT NULL DEFAULT 1;
ALTER TABLE sacco_settings DROP CONSTRAINT IF EXISTS ck_sacco_settings_fy_month;
ALTER TABLE sacco_settings ADD CONSTRAINT ck_sacco_settings_fy_month CHECK (financial_year_start_month BETWEEN 1 AND 12);

-- +goose Down
ALTER TABLE sacco_settings DROP CONSTRAINT IF EXISTS ck_sacco_settings_fy_month;
ALTER TABLE sacco_settings DROP COLUMN IF EXISTS financial_year_start_month;
DELETE FROM role_permissions WHERE role_id = 4 OR permission_name LIKE 'books.%';
DELETE FROM permissions WHERE name LIKE 'books.%';
-- Staff holding the role keep their accounts but lose it; move them first.
DELETE FROM user_roles WHERE role_id = 4;
DELETE FROM roles WHERE id = 4 AND name = 'Accountant';
