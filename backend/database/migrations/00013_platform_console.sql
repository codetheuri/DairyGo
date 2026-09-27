-- Platform console: failed API requests for operators to review, and the
-- permission that guards platform-only endpoints. No Sacco role receives it;
-- only platform super users (who bypass permission checks) can use them.

-- +goose Up
CREATE TABLE IF NOT EXISTS system_logs (
    id VARCHAR(36) PRIMARY KEY,
    level VARCHAR(10) NOT NULL, -- WARN (4xx), ERROR (5xx)
    method VARCHAR(10) NOT NULL,
    path VARCHAR(255) NOT NULL,
    query TEXT NULL,
    status INT NOT NULL,
    message TEXT NULL,
    request_id VARCHAR(64) NULL,
    user_id BIGINT NULL,
    sacco_id VARCHAR(36) NULL,
    duration_ms BIGINT NOT NULL DEFAULT 0,
    ip VARCHAR(64) NULL,
    user_agent TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_system_logs_created ON system_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_system_logs_sacco_created ON system_logs(sacco_id, created_at);

INSERT INTO permissions (name, description, created_at, updated_at)
SELECT 'platform.manage', 'Platform console: manage all Saccos, their staff and farmers, and review logs', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'platform.manage');

-- +goose Down
DELETE FROM role_permissions WHERE permission_name = 'platform.manage';
DELETE FROM permissions WHERE name = 'platform.manage';
DROP TABLE IF EXISTS system_logs;
