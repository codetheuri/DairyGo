// Package ledger keeps the Sacco's books: a double-entry ledger built from
// the records staff already make. Every sale, customer payment, expense,
// transfer, advance, charge, adjustment, pay run and payment of farmers'
// pay posts a balanced journal by itself, in the same transaction as the
// record (through the audit hook, see hook.go). A record that changes or is
// voided gets a reversal and a new journal; journals are never edited. The
// accountant adds manual journals for anything else and reverses their own.
//
// Where a record posts is data (ledger_links), so the chart of accounts can
// change without code: each cash account, expense category and deduction has
// its own ledger account, and the farmer, customer and pay accounts are
// found by their role. Records dated before the books start are summed into
// one opening journal.
package ledger

import (
	"errors"
	"math"
	"time"
)

// Domain errors, mapped to HTTP status codes by the handler.
var (
	ErrNotFound   = errors.New("not found")
	ErrConflict   = errors.New("conflict")
	ErrInvalid    = errors.New("invalid")
	ErrNotStarted = errors.New("not started")
)

const dateLayout = "2006-01-02"

// Type is what an account records.
type Type string

const (
	Asset     Type = "ASSET"
	Liability Type = "LIABILITY"
	Equity    Type = "EQUITY"
	Income    Type = "INCOME"
	Expense   Type = "EXPENSE"
)

// Types in the order the chart lists them.
var Types = []Type{Asset, Liability, Equity, Income, Expense}

// DebitNormal says whether an account of this type grows with debits.
func (t Type) DebitNormal() bool { return t == Asset || t == Expense }

// Valid says whether t is one of the five types.
func (t Type) Valid() bool {
	for _, v := range Types {
		if v == t {
			return true
		}
	}
	return false
}

// Account is one account in a Sacco's chart.
type LedgerAccount struct {
	ID          string    `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID     string    `json:"-" gorm:"type:varchar(36);not null"`
	Code        string    `json:"code"`
	Name        string    `json:"name"`
	Type        Type      `json:"type"`
	Description *string   `json:"description,omitempty"`
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

	// Filled for lists, never stored.
	Balance float64 `json:"balance" gorm:"-" doc:"Balance now, positive in the account's usual direction (debit for assets and expenses, credit otherwise)"`
	Used    bool    `json:"used" gorm:"-" doc:"True once anything has posted to it; it can then be switched off but never deleted"`
	// Kept says the account follows records (customers, farmers, a cash
	// account): manual journals cannot use it.
	Kept   bool   `json:"kept_from_records" gorm:"-"`
	KeptBy string `json:"kept_by,omitempty" gorm:"-" doc:"What it follows, e.g. Customers' balances"`
}

// TableName sets the database table name.
func (LedgerAccount) TableName() string { return "ledger_accounts" }

// Link says which account a kind of record posts to.
type Link struct {
	SaccoID   string    `gorm:"primaryKey;type:varchar(36)"`
	LinkKey   string    `gorm:"primaryKey;column:link_key"`
	AccountID string    `gorm:"type:varchar(36)"`
	CreatedAt time.Time ``
	UpdatedAt time.Time ``
}

// TableName sets the database table name.
func (Link) TableName() string { return "ledger_links" }

// Books is a Sacco's books once started.
type Books struct {
	SaccoID     string     `gorm:"primaryKey;type:varchar(36)"`
	StartDate   time.Time  `gorm:"type:date"`
	NextNumber  int64      ``
	SyncedAt    *time.Time ``
	StartedByID *uint      ``
	CreatedAt   time.Time  ``
	UpdatedAt   time.Time  ``
}

// TableName sets the database table name.
func (Books) TableName() string { return "ledger_books" }

// Kind says who made a journal.
type Kind string

const (
	KindAuto   Kind = "AUTO"   // posted from a record
	KindManual Kind = "MANUAL" // made by the accountant
)

// Journal is one balanced entry.
type Journal struct {
	ID           string    `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID      string    `json:"-" gorm:"type:varchar(36)"`
	Number       int64     `json:"number"`
	JournalDate  time.Time `json:"date" gorm:"type:date"`
	Kind         Kind      `json:"kind"`
	SourceType   *string   `json:"source_type,omitempty"`
	SourceID     *string   `json:"source_id,omitempty"`
	SourceKey    *string   `json:"-"`
	Memo         string    `json:"memo"`
	Reference    *string   `json:"reference,omitempty"`
	Total        float64   `json:"total"`
	ReversesID   *string   `json:"reverses_id,omitempty"`
	ReversedByID *string   `json:"reversed_by_id,omitempty"`
	Reason       *string   `json:"reason,omitempty"`
	CreatedByID  *uint     `json:"created_by_id,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
	Lines        []Line    `json:"lines,omitempty" gorm:"foreignKey:JournalID"`

	// Filled for detail, never stored.
	CreatedBy        string `json:"created_by,omitempty" gorm:"->;-:migration"`
	ReversesNumber   *int64 `json:"reverses_number,omitempty" gorm:"-"`
	ReversedByNumber *int64 `json:"reversed_by_number,omitempty" gorm:"-"`
}

// TableName sets the database table name.
func (Journal) TableName() string { return "journals" }

// Line is one debit or credit in a journal.
type Line struct {
	ID          string    `json:"-" gorm:"primaryKey;type:varchar(36)"`
	JournalID   string    `json:"-" gorm:"type:varchar(36)"`
	SaccoID     string    `json:"-" gorm:"type:varchar(36)"`
	LineNo      int       `json:"-"`
	AccountID   string    `json:"account_id" gorm:"type:varchar(36)"`
	LinkKey     *string   `json:"-"`
	JournalDate time.Time `json:"-" gorm:"type:date"`
	Debit       float64   `json:"debit"`
	Credit      float64   `json:"credit"`
	Memo        *string   `json:"memo,omitempty"`

	AccountCode string `json:"account_code,omitempty" gorm:"->;-:migration"`
	AccountName string `json:"account_name,omitempty" gorm:"->;-:migration"`
}

// TableName sets the database table name.
func (Line) TableName() string { return "journal_lines" }

// round2 rounds to the cent; -0 comes out as 0.
func round2(v float64) float64 { return math.Round(v*100)/100 + 0 }

// same says two amounts are the same to the cent.
func same(a, b float64) bool { return math.Abs(a-b) < 0.005 }
