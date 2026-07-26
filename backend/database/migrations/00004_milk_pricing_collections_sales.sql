-- +goose Up
-- 1. Milk Pricing Rates Table
CREATE TABLE IF NOT EXISTS milk_prices (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    price_per_litre DECIMAL(10, 2) NOT NULL,
    effective_date TIMESTAMP NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by_id BIGINT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT fk_milk_prices_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_milk_prices_created_by FOREIGN KEY (created_by_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_milk_prices_sacco_active ON milk_prices(sacco_id, is_active);
CREATE INDEX IF NOT EXISTS idx_milk_prices_effective ON milk_prices(sacco_id, effective_date);

-- 2. Milk Collections Table (Farmer intake)
CREATE TABLE IF NOT EXISTS milk_collections (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    member_id VARCHAR(36) NOT NULL,
    collector_id BIGINT NOT NULL,
    collection_date DATE NOT NULL,
    shift VARCHAR(20) NOT NULL DEFAULT 'MORNING', -- MORNING, EVENING, FULL_DAY
    quantity_litres DECIMAL(10, 2) NOT NULL,
    price_per_litre DECIMAL(10, 2) NOT NULL, -- Immutable snapshot buying price
    total_amount DECIMAL(12, 2) NOT NULL,   -- Immutable snapshot (quantity * price)
    status VARCHAR(20) NOT NULL DEFAULT 'SUBMITTED', -- SUBMITTED, VERIFIED, REJECTED, ADJUSTED
    notes TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,
    
    CONSTRAINT fk_collections_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_collections_member FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE RESTRICT,
    CONSTRAINT fk_collections_collector FOREIGN KEY (collector_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_collections_sacco_date ON milk_collections(sacco_id, collection_date);
CREATE INDEX IF NOT EXISTS idx_collections_member_date ON milk_collections(sacco_id, member_id, collection_date);
CREATE INDEX IF NOT EXISTS idx_collections_collector ON milk_collections(sacco_id, collector_id, collection_date);

-- 3. Milk Sales Table (Direct field sales to hotels, processors, or consumers)
CREATE TABLE IF NOT EXISTS milk_sales (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    collector_id BIGINT NOT NULL,
    sale_date DATE NOT NULL,
    buyer_name VARCHAR(191) NOT NULL, -- e.g. "Hotel B", "Processor X", "Walk-in Customer"
    buyer_phone VARCHAR(50) NULL,
    quantity_litres DECIMAL(10, 2) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_amount DECIMAL(12, 2) NOT NULL,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PAID', -- PAID, PENDING, PARTIAL
    payment_method VARCHAR(30) NOT NULL DEFAULT 'CASH', -- CASH, MPESA, BANK_TRANSFER, CREDIT
    notes TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,

    CONSTRAINT fk_sales_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_sales_collector FOREIGN KEY (collector_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_sales_sacco_date ON milk_sales(sacco_id, sale_date);
CREATE INDEX IF NOT EXISTS idx_sales_collector_date ON milk_sales(sacco_id, collector_id, sale_date);

-- 4. Milk Spoilage / Loss Records Table
CREATE TABLE IF NOT EXISTS milk_spoilage (
    id VARCHAR(36) PRIMARY KEY,
    sacco_id VARCHAR(36) NOT NULL,
    collector_id BIGINT NOT NULL,
    spoilage_date DATE NOT NULL,
    quantity_litres DECIMAL(10, 2) NOT NULL,
    reason VARCHAR(255) NOT NULL, -- e.g. "Spillage", "Sour Milk / Acidic test failure", "Transport damage"
    notes TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,

    CONSTRAINT fk_spoilage_sacco FOREIGN KEY (sacco_id) REFERENCES saccos(id) ON DELETE CASCADE,
    CONSTRAINT fk_spoilage_collector FOREIGN KEY (collector_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_spoilage_sacco_date ON milk_spoilage(sacco_id, spoilage_date);
CREATE INDEX IF NOT EXISTS idx_spoilage_collector_date ON milk_spoilage(sacco_id, collector_id, spoilage_date);

-- +goose Down
DROP TABLE IF EXISTS milk_spoilage;
DROP TABLE IF EXISTS milk_sales;
DROP TABLE IF EXISTS milk_collections;
DROP TABLE IF EXISTS milk_prices;
