package collection

import (
	"time"

	"github.com/codetheuri/tusk/pkg/reconcile"

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
	ID            string `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID       string `json:"sacco_id" gorm:"index;type:varchar(36);not null"`
	MemberID      string `json:"member_id" gorm:"index;type:varchar(36);not null"`
	CollectorID   uint   `json:"collector_id" gorm:"index;not null"`
	CollectorName string `json:"collector_name,omitempty" gorm:"-"`
	// MemberName and MembershipNumber are filled in on lists so the app does
	// not have to download the farmer directory to label each row.
	MemberName       string           `json:"member_name,omitempty" gorm:"-"`
	MembershipNumber string           `json:"membership_number,omitempty" gorm:"-"`
	CollectionDate   time.Time        `json:"collection_date" gorm:"type:date;not null;index"`
	Shift            Shift            `json:"shift" gorm:"default:'MORNING';not null"`
	QuantityLitres   float64          `json:"quantity_litres" gorm:"type:decimal(10,2);not null"`
	PricePerLitre    float64          `json:"price_per_litre" gorm:"type:decimal(10,2);not null"` // Snapshot price
	TotalAmount      float64          `json:"total_amount" gorm:"type:decimal(12,2);not null"`    // Snapshot total
	Status           CollectionStatus `json:"status" gorm:"default:'SUBMITTED';index"`
	Notes            *string          `json:"notes,omitempty"`
	CreatedAt        time.Time        `json:"created_at"`
	UpdatedAt        time.Time        `json:"updated_at"`
	DeletedAt        gorm.DeletedAt   `json:"deleted_at,omitempty" gorm:"index"`
}

func (MilkCollection) TableName() string {
	return "milk_collections"
}

// MilkSale is milk sold to a customer. Every litre leaving a collector is a
// sale, including deliveries to coolers. BuyerName and BuyerPhone snapshot
// the customer's details at the time of sale.
type MilkSale struct {
	ID             string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID        string         `json:"sacco_id" gorm:"index;type:varchar(36);not null"`
	CollectorID    uint           `json:"collector_id" gorm:"index;not null"`
	CollectorName  string         `json:"collector_name,omitempty" gorm:"-"`
	CustomerID     string         `json:"customer_id" gorm:"type:varchar(36);not null"`
	CustomerType   string         `json:"customer_type,omitempty" gorm:"-"`
	SaleDate       time.Time      `json:"sale_date" gorm:"type:date;not null;index"`
	BuyerName      string         `json:"buyer_name" gorm:"not null"`
	BuyerPhone     *string        `json:"buyer_phone,omitempty"`
	QuantityLitres float64        `json:"quantity_litres" gorm:"type:decimal(10,2);not null"`
	UnitPrice      float64        `json:"unit_price" gorm:"type:decimal(10,2);not null"`
	TotalAmount    float64        `json:"total_amount" gorm:"type:decimal(12,2);not null"`
	AmountPaid     float64        `json:"amount_paid" gorm:"type:decimal(12,2);not null;default:0"`
	PaymentStatus  string         `json:"payment_status" gorm:"default:'PAID'"` // PAID, PARTIAL, CREDIT (legacy: PENDING)
	PaymentMethod  string         `json:"payment_method" gorm:"default:'CASH'"` // CASH, MPESA, BANK_TRANSFER, CREDIT
	VoidedAt       *time.Time     `json:"voided_at,omitempty"`
	VoidReason     *string        `json:"void_reason,omitempty"`
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
	CollectorName  string         `json:"collector_name,omitempty" gorm:"-"`
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

// MilkTransfer is milk handed from one collector to another. It counts for
// both at once: out of the sender's balance and into the receiver's.
type MilkTransfer struct {
	ID              string `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID         string `json:"sacco_id" gorm:"index;type:varchar(36);not null"`
	FromCollectorID uint   `json:"from_collector_id" gorm:"not null"`
	ToCollectorID   uint   `json:"to_collector_id" gorm:"not null"`
	// Display names, filled in on reads.
	FromCollectorName string    `json:"from_collector_name,omitempty" gorm:"-"`
	ToCollectorName   string    `json:"to_collector_name,omitempty" gorm:"-"`
	TransferDate      time.Time `json:"transfer_date" gorm:"type:date;not null"`
	QuantityLitres    float64   `json:"quantity_litres" gorm:"type:decimal(10,2);not null"`
	Notes             *string   `json:"notes,omitempty"`
	// RecordedByID is the sender, or an admin recording it for them.
	RecordedByID uint           `json:"recorded_by_id" gorm:"not null"`
	VoidedAt     *time.Time     `json:"voided_at,omitempty"`
	VoidReason   *string        `json:"void_reason,omitempty"`
	CreatedAt    time.Time      `json:"created_at" doc:"When it was recorded"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `json:"-" gorm:"index"`
}

func (MilkTransfer) TableName() string {
	return "milk_transfers"
}

// TransferRecipient is a colleague milk can be transferred to.
type TransferRecipient struct {
	ID       uint   `json:"id"`
	Name     string `json:"name"`
	Username string `json:"username"`
}

// CollectorReconciliation balances one collector's day: every litre collected
// must be sold (coolers included) or logged as spoilage; the rest is unaccounted.
type CollectorReconciliation struct {
	CollectorID          uint    `json:"collector_id"`
	CollectorName        string  `json:"collector_name,omitempty"`
	Date                 string  `json:"date"`
	TotalCollectedLitres float64 `json:"total_collected_litres"`
	TotalSoldLitres      float64 `json:"total_sold_litres"`
	TotalSpoiledLitres   float64 `json:"total_spoiled_litres"`
	// Milk from and to other collectors on the day.
	TotalReceivedLitres       float64 `json:"total_received_litres"`
	TotalTransferredOutLitres float64 `json:"total_transferred_out_litres"`
	reconcile.Result
	TotalSalesAmount     float64               `json:"total_sales_amount"`
	CashReceivedAmount   float64               `json:"cash_received_amount" doc:"Paid at the time of sale (cash, M-Pesa, bank)"`
	CreditSalesAmount    float64               `json:"credit_sales_amount" doc:"Sold on credit; added to customer balances"`
	TotalPurchasesAmount float64               `json:"total_purchases_amount"`
	SalesByCustomerType  []reconcile.TypeTotal `json:"sales_by_customer_type"`
	// Transfers is the day's transfers to and from the collector, oldest first.
	Transfers []MilkTransfer `json:"transfers"`
}
