-- +goose Up
CREATE TABLE IF NOT EXISTS sms_logs (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NULL,
    recipient_phone VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    provider VARCHAR(50) NOT NULL, -- HTTPSMS, AFRICAS_TALKING, CONSOLE
    status VARCHAR(30) NOT NULL DEFAULT 'SENT', -- SENT, QUEUED, FAILED
    error_message TEXT NULL,
    created_at TIMESTAMP NULL,
    
    CONSTRAINT fk_sms_logs_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_sms_logs_sacco_date ON sms_logs(sacco_id, created_at);
CREATE INDEX IF NOT EXISTS idx_sms_logs_phone ON sms_logs(recipient_phone);

-- +goose Down
DROP TABLE IF EXISTS sms_logs;
