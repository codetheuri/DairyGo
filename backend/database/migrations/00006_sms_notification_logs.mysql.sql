-- +goose Up
CREATE TABLE IF NOT EXISTS sms_logs (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NULL,
    recipient_phone VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    provider VARCHAR(50) NOT NULL, -- HTTPSMS, AFRICAS_TALKING, CONSOLE
    status VARCHAR(30) NOT NULL DEFAULT 'SENT', -- SENT, QUEUED, FAILED
    error_message TEXT NULL,
    created_at DATETIME(3) NULL,
    
    CONSTRAINT fk_sms_logs_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE SET NULL,
    INDEX idx_sms_logs_sacco_date (sacco_id, created_at),
    INDEX idx_sms_logs_phone (recipient_phone)
);

-- +goose Down
DROP TABLE IF EXISTS sms_logs;
