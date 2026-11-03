-- How each farmer is paid: MPESA (their M-Pesa number, or their phone when
-- none is set) or BANK (bank, account, branch). Each farmer is on exactly one
-- payment list. Existing farmers: BANK when a bank account is on file, else
-- MPESA. Pay run lines keep the method in force when the run was worked out.

-- +goose Up
ALTER TABLE members ADD COLUMN IF NOT EXISTS payout_method VARCHAR(10) NOT NULL DEFAULT 'MPESA';
UPDATE members SET payout_method = 'BANK'
 WHERE COALESCE(TRIM(bank_account_number), '') <> '';

ALTER TABLE pay_run_lines ADD COLUMN IF NOT EXISTS payout_method VARCHAR(10) NOT NULL DEFAULT 'MPESA';
UPDATE pay_run_lines SET payout_method = 'BANK'
 WHERE COALESCE(TRIM(bank_account_number), '') <> '';

-- +goose Down
ALTER TABLE pay_run_lines DROP COLUMN IF EXISTS payout_method;
ALTER TABLE members DROP COLUMN IF EXISTS payout_method;
