package collection

import (
	"time"

	"gorm.io/gorm"
)

// Shift represents milk collection shift.
type Shift string

const (
	ShiftMorning Shift = "MORNING"
	ShiftEvening Shift = "EVENING"
	ShiftFullDay Shift = "FULL_DAY"
)

// CollectionStatus defines collection record state.
type CollectionStatus string

const (
	StatusSubmitted CollectionStatus = "SUBMITTED"
	StatusVerified  CollectionStatus = "VERIFIED"
	StatusRejected  CollectionStatus = "REJECTED"
	StatusAdjusted  CollectionStatus = "ADJUSTED"
)

// MilkPrice represents the Sacco buying price per litre over time.
type MilkPrice struct {
	ID            string    `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID       string    `json:"sacco_id" gorm:"index;type:varchar(36);not null"`
	PricePerLitre float64   `json:"price_per_litre" gorm:"type:decimal(10,2);not null"`
	EffectiveDate time.Time `json:"effective_date" gorm:"not null"`
	IsActive      bool      `json:"is_active" gorm:"default:true;index"`
	CreatedByID   *uint     `json:"created_by_id,omitempty"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

func (MilkPrice) TableName() string {
	return "milk_prices"
}

// MilkCollection represents a single farmer milk intake entry.
type MilkCollection struct {
	ID             string           `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID        string           `json:"sacco_id" gorm:"index;type:varchar(36);not null"`
	MemberID       string           `json:"member_id" gorm:"index;type:varchar(36);not null"`
	CollectorID    uint             `json:"collector_id" gorm:"index;not null"`
	CollectionDate time.Time        `json:"collection_date" gorm:"type:date;not null;index"`
	Shift          Shift            `json:"shift" gorm:"default:'MORNING';not null"`
	QuantityLitres float64          `json:"quantity_litres" gorm:"type:decimal(10,2);not null"`
	PricePerLitre  float64          `json:"price_per_litre" gorm:"type:decimal(10,2);not null"` // Snapshot price
	TotalAmount    float64          `json:"total_amount" gorm:"type:decimal(12,2);not null"`   // Snapshot total
	Status         CollectionStatus `json:"status" gorm:"default:'SUBMITTED';index"`
	Notes          *string          `json:"notes,omitempty"`
	CreatedAt      time.Time        `json:"created_at"`
	UpdatedAt      time.Time        `json:"updated_at"`
	DeletedAt      gorm.DeletedAt   `json:"deleted_at,omitempty" gorm:"index"`
}

func (MilkCollection) TableName() string {
	return "milk_collections"
}

// MilkSale represents direct field sales (e.g. to hotels, processors, local buyers).
type MilkSale struct {
	ID             string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID        string         `json:"sacco_id" gorm:"index;type:varchar(36);not null"`
	CollectorID    uint           `json:"collector_id" gorm:"index;not null"`
	SaleDate       time.Time      `json:"sale_date" gorm:"type:date;not null;index"`
	BuyerName      string         `json:"buyer_name" gorm:"not null"`
	BuyerPhone     *string        `json:"buyer_phone,omitempty"`
	QuantityLitres float64        `json:"quantity_litres" gorm:"type:decimal(10,2);not null"`
	UnitPrice      float64        `json:"unit_price" gorm:"type:decimal(10,2);not null"`
	TotalAmount    float64        `json:"total_amount" gorm:"type:decimal(12,2);not null"`
	PaymentStatus  string         `json:"payment_status" gorm:"default:'PAID'"` // PAID, PENDING, PARTIAL
	PaymentMethod  string         `json:"payment_method" gorm:"default:'CASH'"` // CASH, MPESA, BANK_TRANSFER, CREDIT
	Notes          *string        `json:"notes,omitempty"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
	DeletedAt      gorm.DeletedAt `json:"deleted_at,omitempty" gorm:"index"`
}

func (MilkSale) TableName() string {
	return "milk_sales"
}

// MilkSpoilage represents milk loss or damage in transit.
type MilkSpoilage struct {
	ID             string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID        string         `json:"sacco_id" gorm:"index;type:varchar(36);not null"`
	CollectorID    uint           `json:"collector_id" gorm:"index;not null"`
	SpoilageDate   time.Time      `json:"spoilage_date" gorm:"type:date;not null;index"`
	QuantityLitres float64        `json:"quantity_litres" gorm:"type:decimal(10,2);not null"`
	Reason         string         `json:"reason" gorm:"not null"`
	Notes          *string        `json:"notes,omitempty"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
	DeletedAt      gorm.DeletedAt `json:"deleted_at,omitempty" gorm:"index"`
}

func (MilkSpoilage) TableName() string {
	return "milk_spoilage"
}

// CollectorReconciliation represents a daily summary for a collector.
type CollectorReconciliation struct {
	CollectorID          uint    `json:"collector_id"`
	CollectorName        string  `json:"collector_name,omitempty"`
	Date                 string  `json:"date"`
	TotalCollectedLitres float64 `json:"total_collected_litres"`
	TotalSoldLitres      float64 `json:"total_sold_litres"`
	TotalSpoiledLitres   float64 `json:"total_spoiled_litres"`
	NetDeliveredLitres   float64 `json:"net_delivered_litres"` // Collected - Sold - Spoiled
	TotalSalesAmount     float64 `json:"total_sales_amount"`
	TotalPurchasesAmount float64 `json:"total_purchases_amount"`
}
