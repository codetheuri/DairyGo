// Package customer manages the buyers a Sacco sells milk to (coolers,
// processors, hotels, shops and individuals) and their running-balance ledger:
// credit sales add to what a customer owes, payments reduce it.
package customer

import (
	"time"

	"gorm.io/gorm"
)

// Type classifies a customer. Coolers are customers like any other buyer.
type Type string

const (
	TypeCooler     Type = "COOLER"
	TypeProcessor  Type = "PROCESSOR"
	TypeHotel      Type = "HOTEL"
	TypeShop       Type = "SHOP"
	TypeIndividual Type = "INDIVIDUAL"
	TypeOther      Type = "OTHER"
)

// Status controls whether new sales can be recorded for a customer.
type Status string

const (
	StatusActive   Status = "ACTIVE"
	StatusInactive Status = "INACTIVE"
)

// PaymentMethod is how a customer paid.
type PaymentMethod string

const (
	MethodCash         PaymentMethod = "CASH"
	MethodMpesa        PaymentMethod = "MPESA"
	MethodBankTransfer PaymentMethod = "BANK_TRANSFER"
	MethodCheque       PaymentMethod = "CHEQUE"
)

// Customer is a buyer of milk belonging to one Sacco.
type Customer struct {
	ID                   string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID              string         `json:"sacco_id" gorm:"index;type:varchar(36);not null"`
	Name                 string         `json:"name" gorm:"not null"`
	Phone                *string        `json:"phone,omitempty"`
	CustomerType         Type           `json:"customer_type" gorm:"default:'OTHER'"`
	DefaultPricePerLitre *float64       `json:"default_price_per_litre,omitempty"`
	Status               Status         `json:"status" gorm:"default:'ACTIVE'"`
	Notes                *string        `json:"notes,omitempty"`
	CreatedByID          *uint          `json:"created_by_id,omitempty"`
	CreatedAt            time.Time      `json:"created_at"`
	UpdatedAt            time.Time      `json:"updated_at"`
	DeletedAt            gorm.DeletedAt `json:"-" gorm:"index"`

	// Balance is the amount the customer currently owes. It is filled in by
	// list and detail queries and never stored.
	Balance *float64 `json:"balance,omitempty" gorm:"-"`
}

// TableName sets the database table name.
func (Customer) TableName() string {
	return "customers"
}

// Payment is money received from a customer against their balance.
type Payment struct {
	ID           string        `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID      string        `json:"sacco_id" gorm:"type:varchar(36);not null"`
	CustomerID   string        `json:"customer_id" gorm:"type:varchar(36);not null"`
	Amount       float64       `json:"amount"`
	PaymentDate  time.Time     `json:"payment_date" gorm:"type:date"`
	Method       PaymentMethod `json:"method"`
	Reference    *string       `json:"reference,omitempty"`
	Notes        *string       `json:"notes,omitempty"`
	RecordedByID *uint         `json:"recorded_by_id,omitempty"`
	VoidedAt     *time.Time    `json:"voided_at,omitempty"`
	VoidReason   *string       `json:"void_reason,omitempty"`
	CreatedAt    time.Time     `json:"created_at"`
	UpdatedAt    time.Time     `json:"updated_at"`
}

// TableName sets the database table name.
func (Payment) TableName() string {
	return "customer_payments"
}

// Balance is one customer's outstanding amount, used for the "who owes what" list.
type Balance struct {
	CustomerID   string  `json:"customer_id"`
	Name         string  `json:"name"`
	Phone        *string `json:"phone,omitempty"`
	CustomerType Type    `json:"customer_type"`
	TotalSales   float64 `json:"total_sales"`
	TotalPaid    float64 `json:"total_paid"`
	Balance      float64 `json:"balance"`
}
