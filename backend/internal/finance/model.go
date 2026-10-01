// Package finance keeps the cooperative's own money: the accounts it is
// kept in (petty cash, bank, M-Pesa), what it spends (expenses by category),
// money moved between accounts, each account's cashbook, and the income and
// expenditure. Customer payments, cash at sales, advances and farmers' pay
// recorded elsewhere name the account they went through, so the cashbook
// reads them where they are rather than copying them.
package finance

import (
	"time"

	"github.com/google/uuid"
)

// Kind is what sort of place money is kept.
type Kind string

const (
	KindCash  Kind = "CASH"
	KindBank  Kind = "BANK"
	KindMpesa Kind = "MPESA"
)

// CashAccount is a place the Sacco keeps money.
type CashAccount struct {
	ID             string    `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID        string    `json:"sacco_id" gorm:"type:varchar(36);not null"`
	Name           string    `json:"name"`
	Kind           Kind      `json:"kind"`
	AccountNumber  *string   `json:"account_number,omitempty"`
	OpeningBalance float64   `json:"opening_balance"`
	OpeningDate    time.Time `json:"opening_date" gorm:"type:date"`
	IsActive       bool      `json:"is_active"`
	CreatedByID    *uint     `json:"created_by_id,omitempty"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`

	// Balance is worked out from the opening balance and every movement;
	// never stored.
	Balance float64 `json:"balance" gorm:"-"`
}

// TableName sets the database table name.
func (CashAccount) TableName() string { return "cash_accounts" }

// ExpenseCategory groups expenses.
type ExpenseCategory struct {
	ID        string    `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID   string    `json:"sacco_id" gorm:"type:varchar(36);not null"`
	Name      string    `json:"name"`
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// TableName sets the database table name.
func (ExpenseCategory) TableName() string { return "expense_categories" }

// DefaultCategories are the expense categories every Sacco starts with.
var DefaultCategories = []string{
	"Salaries and wages", "Petty cash spending", "Transport and fuel", "Rent", "Electricity and water",
	"Repairs and maintenance", "Stationery and printing", "Bank and M-Pesa charges", "Meetings and AGM", "Other",
}

// Categories are a new Sacco's expense categories (migration 00023 gave
// existing Saccos the same list).
func Categories(saccoID string) []ExpenseCategory {
	out := make([]ExpenseCategory, len(DefaultCategories))
	for i, name := range DefaultCategories {
		out[i] = ExpenseCategory{ID: uuid.New().String(), SaccoID: saccoID, Name: name, IsActive: true}
	}
	return out
}

// Expense is money the Sacco spent.
type Expense struct {
	ID            string     `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID       string     `json:"sacco_id" gorm:"type:varchar(36);not null"`
	CategoryID    string     `json:"category_id" gorm:"type:varchar(36);not null"`
	CashAccountID string     `json:"cash_account_id" gorm:"type:varchar(36);not null"`
	ExpenseDate   time.Time  `json:"expense_date" gorm:"type:date"`
	Amount        float64    `json:"amount"`
	Payee         string     `json:"payee"`
	Reference     *string    `json:"reference,omitempty"`
	Description   *string    `json:"description,omitempty"`
	RecordedByID  *uint      `json:"recorded_by_id,omitempty"`
	VoidedAt      *time.Time `json:"voided_at,omitempty"`
	VoidReason    *string    `json:"void_reason,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`

	// Names for lists; filled by queries, never stored.
	CategoryName string `json:"category_name,omitempty" gorm:"->;-:migration"`
	AccountName  string `json:"account_name,omitempty" gorm:"->;-:migration"`
}

// TableName sets the database table name.
func (Expense) TableName() string { return "expenses" }

// AccountTransfer is money moved from one account to another (a petty cash top-up,
// a bank deposit).
type AccountTransfer struct {
	ID            string     `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID       string     `json:"sacco_id" gorm:"type:varchar(36);not null"`
	FromAccountID string     `json:"from_account_id" gorm:"type:varchar(36);not null"`
	ToAccountID   string     `json:"to_account_id" gorm:"type:varchar(36);not null"`
	TransferDate  time.Time  `json:"transfer_date" gorm:"type:date"`
	Amount        float64    `json:"amount"`
	Reference     *string    `json:"reference,omitempty"`
	Notes         *string    `json:"notes,omitempty"`
	RecordedByID  *uint      `json:"recorded_by_id,omitempty"`
	VoidedAt      *time.Time `json:"voided_at,omitempty"`
	VoidReason    *string    `json:"void_reason,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`

	FromName string `json:"from_account_name,omitempty" gorm:"->;-:migration"`
	ToName   string `json:"to_account_name,omitempty" gorm:"->;-:migration"`
}

// TableName sets the database table name.
func (AccountTransfer) TableName() string { return "account_transfers" }
