// Package payout pays farmers for their milk. Every farmer has an account
// (member_transactions) whose balance is what the Sacco owes them. Advances,
// charges and adjustments are written when they happen. A pay run works out
// each farmer's pay (Compute) from their milk and the Sacco's deduction rules
// (deduction_types), and approving it writes the milk, deductions and net pay
// to the accounts and closes the period, so milk records in it can no longer
// change. Deductions are data: a Sacco adds new ones without code changes.
package payout

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Method is how a deduction's amount is worked out.
type Method string

const (
	MethodFixed    Method = "FIXED"     // a set amount (KES 200)
	MethodPercent  Method = "PERCENT"   // a percentage of the base
	MethodPerLitre Method = "PER_LITRE" // KES per litre delivered (transport)
	MethodTiered   Method = "TIERED"    // a fee by band (the M-Pesa tariff)
)

// Base is what a PERCENT or TIERED deduction is worked out on.
type Base string

const (
	BaseGross Base = "GROSS" // the milk value
	BaseNet   Base = "NET"   // the pay left after other deductions (taken last)
)

// Frequency is how often a deduction is taken.
type Frequency string

const (
	FreqEveryRun      Frequency = "EVERY_RUN"
	FreqOncePerMember Frequency = "ONCE_PER_MEMBER" // registration fee
	FreqOncePerYear   Frequency = "ONCE_PER_YEAR"   // annual subscription
	FreqUntilTarget   Frequency = "UNTIL_TARGET"    // shares, a simple loan
)

// AppliesTo says which farmers pay a deduction.
type AppliesTo string

const (
	AppliesAll      AppliesTo = "ALL"      // every farmer, unless exempted
	AppliesEnrolled AppliesTo = "ENROLLED" // only farmers added to it
)

// Tier is one band of a TIERED deduction: amounts up to UpTo pay Fee. The
// last band may leave UpTo empty to cover everything above.
type Tier struct {
	UpTo *float64 `json:"up_to,omitempty" doc:"Upper limit of the band in KES; empty for the last band"`
	Fee  float64  `json:"fee" minimum:"0" doc:"Fee for amounts in this band"`
}

// Tiers is stored as JSON text.
type Tiers []Tier

// Value stores the tiers as JSON.
func (t Tiers) Value() (driver.Value, error) {
	if len(t) == 0 {
		return nil, nil
	}
	b, err := json.Marshal(t)
	return string(b), err
}

// Scan reads tiers stored as JSON.
func (t *Tiers) Scan(v any) error {
	switch s := v.(type) {
	case nil:
		*t = nil
		return nil
	case string:
		return json.Unmarshal([]byte(s), t)
	case []byte:
		return json.Unmarshal(s, t)
	}
	return errors.New("tiers: unsupported type")
}

// DeductionType is a Sacco's rule for something taken from farmers' pay.
type DeductionType struct {
	ID          string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID     string         `json:"sacco_id" gorm:"type:varchar(36);not null"`
	Name        string         `json:"name"`
	Description *string        `json:"description,omitempty"`
	Method      Method         `json:"method"`
	Base        Base           `json:"base"`
	Amount      float64        `json:"amount"`
	Tiers       Tiers          `json:"tiers,omitempty" gorm:"type:text"`
	Frequency   Frequency      `json:"frequency"`
	Target      *float64       `json:"target_amount,omitempty" gorm:"column:target_amount"`
	AppliesTo   AppliesTo      `json:"applies_to"`
	Priority    int            `json:"priority"`
	IsSavings   bool           `json:"is_savings"`
	IsActive    bool           `json:"is_active"`
	CreatedByID *uint          `json:"created_by_id,omitempty"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`
}

// TableName sets the database table name.
func (DeductionType) TableName() string { return "deduction_types" }

// MemberDeduction adds a farmer to an ENROLLED deduction, changes their
// amount or target, or (IsActive false) exempts them from it.
type MemberDeduction struct {
	ID              string    `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID         string    `json:"sacco_id" gorm:"type:varchar(36);not null"`
	MemberID        string    `json:"member_id" gorm:"type:varchar(36);not null"`
	DeductionTypeID string    `json:"deduction_type_id" gorm:"type:varchar(36);not null"`
	Amount          *float64  `json:"amount,omitempty" doc:"This farmer's amount instead of the usual one"`
	Target          *float64  `json:"target_amount,omitempty" gorm:"column:target_amount"`
	IsActive        bool      `json:"is_active"`
	Notes           *string   `json:"notes,omitempty"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

// TableName sets the database table name.
func (MemberDeduction) TableName() string { return "member_deductions" }

// Kind is what a farmer's account entry records.
type Kind string

const (
	KindMilk       Kind = "MILK"       // + milk value for a pay run
	KindAdvance    Kind = "ADVANCE"    // − money advanced before pay day
	KindCharge     Kind = "CHARGE"     // − feeds, AI, vet, items on credit
	KindAdjustment Kind = "ADJUSTMENT" // ± a correction, with a reason
	KindDeduction  Kind = "DEDUCTION"  // − a deduction in a pay run
	KindPayout     Kind = "PAYOUT"     // − the net pay of a pay run
)

// PayMethod is how money reached or left a farmer.
type PayMethod string

const (
	PayCash  PayMethod = "CASH"
	PayMpesa PayMethod = "MPESA"
	PayBank  PayMethod = "BANK_TRANSFER"
	PayCheck PayMethod = "CHEQUE"
)

// Transaction is one entry in a farmer's account. Amount is signed: positive
// means the Sacco owes the farmer more.
type Transaction struct {
	ID              string    `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID         string    `json:"sacco_id" gorm:"type:varchar(36);not null"`
	MemberID        string    `json:"member_id" gorm:"type:varchar(36);not null"`
	Kind            Kind      `json:"kind"`
	EntryDate       time.Time `json:"entry_date" gorm:"type:date"`
	Amount          float64   `json:"amount"`
	Description     string    `json:"description"`
	DeductionTypeID *string   `json:"deduction_type_id,omitempty" gorm:"type:varchar(36)"`
	IsSavings       bool      `json:"is_savings"`
	// PayRunID is the run that settled this entry; nil while an advance,
	// charge or adjustment waits for the next run.
	PayRunID     *string    `json:"pay_run_id,omitempty" gorm:"type:varchar(36)"`
	Method       *PayMethod `json:"method,omitempty"`
	Reference    *string    `json:"reference,omitempty"`
	RecordedByID *uint      `json:"recorded_by_id,omitempty"`
	VoidedAt     *time.Time `json:"voided_at,omitempty"`
	VoidReason   *string    `json:"void_reason,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
}

// TableName sets the database table name.
func (Transaction) TableName() string { return "member_transactions" }

// RunStatus is where a pay run is in its life.
type RunStatus string

const (
	RunDraft     RunStatus = "DRAFT"     // worked out, can be recomputed
	RunApproved  RunStatus = "APPROVED"  // written to accounts; period closed
	RunPaid      RunStatus = "PAID"      // every farmer paid
	RunCancelled RunStatus = "CANCELLED" // undone before anyone was paid
)

// PayRun pays every farmer for a period.
type PayRun struct {
	ID               string     `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID          string     `json:"sacco_id" gorm:"type:varchar(36);not null"`
	FromDate         time.Time  `json:"from_date" gorm:"type:date"`
	ToDate           time.Time  `json:"to_date" gorm:"type:date"`
	Status           RunStatus  `json:"status"`
	Farmers          int        `json:"farmers"`
	TotalLitres      float64    `json:"total_litres"`
	TotalGross       float64    `json:"total_gross"`
	TotalDeductions  float64    `json:"total_deductions"`
	TotalNet         float64    `json:"total_net"`
	TotalPaid        float64    `json:"total_paid"`
	PaidCount        int        `json:"paid_count"`
	Notes            *string    `json:"notes,omitempty"`
	CreatedByID      *uint      `json:"created_by_id,omitempty"`
	ApprovedByID     *uint      `json:"approved_by_id,omitempty"`
	ApprovedAt       *time.Time `json:"approved_at,omitempty"`
	CancelledAt      *time.Time `json:"cancelled_at,omitempty"`
	CancelReason     *string    `json:"cancel_reason,omitempty"`
	PreviousClosedTo *time.Time `json:"-" gorm:"type:date"`
	SMSSentAt        *time.Time `json:"sms_sent_at,omitempty" gorm:"column:sms_sent_at"`
	CreatedAt        time.Time  `json:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at"`
}

// TableName sets the database table name.
func (PayRun) TableName() string { return "pay_runs" }

// PayRunLine is one farmer's pay in a run, with their payment details as
// they were when the run was worked out.
type PayRunLine struct {
	ID                string     `json:"id" gorm:"primaryKey;type:varchar(36)"`
	PayRunID          string     `json:"pay_run_id" gorm:"type:varchar(36);not null"`
	SaccoID           string     `json:"sacco_id" gorm:"type:varchar(36);not null"`
	MemberID          string     `json:"member_id" gorm:"type:varchar(36);not null"`
	MembershipNumber  string     `json:"membership_number"`
	FarmerName        string     `json:"farmer_name"`
	Phone             string     `json:"phone"`
	MpesaNumber       *string    `json:"mpesa_number,omitempty"`
	BankName          *string    `json:"bank_name,omitempty"`
	BankAccountNumber *string    `json:"bank_account_number,omitempty"`
	Litres            float64    `json:"litres"`
	Gross             float64    `json:"gross"`
	Opening           float64    `json:"opening_balance"`
	Entries           float64    `json:"advances_and_charges"`
	Deductions        float64    `json:"total_deductions"`
	Net               float64    `json:"net"`
	Closing           float64    `json:"closing_balance"`
	Items             []LineItem `json:"deductions" gorm:"foreignKey:LineID"`
	PaidAt            *time.Time `json:"paid_at,omitempty"`
	PaidMethod        *PayMethod `json:"paid_method,omitempty"`
	PaidReference     *string    `json:"paid_reference,omitempty"`
	PaidByID          *uint      `json:"paid_by_id,omitempty"`
	CreatedAt         time.Time  `json:"created_at"`
	UpdatedAt         time.Time  `json:"updated_at"`
}

// TableName sets the database table name.
func (PayRunLine) TableName() string { return "pay_run_lines" }

// LineItem is one deduction on a farmer's line.
type LineItem struct {
	ID              string  `json:"-" gorm:"primaryKey;type:varchar(36)"`
	LineID          string  `json:"-" gorm:"type:varchar(36);not null"`
	DeductionTypeID string  `json:"deduction_type_id" gorm:"type:varchar(36)"`
	Name            string  `json:"name"`
	Amount          float64 `json:"amount"`
	IsSavings       bool    `json:"savings"`
}

// TableName sets the database table name.
func (LineItem) TableName() string { return "pay_run_items" }

// Examples are the deductions every Sacco starts with, switched off until an
// admin sets the amounts (the same list migration 00021 gave existing Saccos).
func Examples(saccoID string) []DeductionType {
	desc := func(s string) *string { return &s }
	list := []DeductionType{
		{Name: "Registration fee", Description: desc("Paid once when a farmer joins"), Method: MethodFixed, Frequency: FreqOncePerMember, Priority: 10},
		{Name: "Annual subscription", Description: desc("Paid once a year"), Method: MethodFixed, Frequency: FreqOncePerYear, Priority: 20},
		{Name: "Shares", Description: desc("Share capital, taken each pay run until the target is reached"), Method: MethodFixed, Frequency: FreqUntilTarget, Priority: 30, IsSavings: true},
		{Name: "Transaction cost", Description: desc("M-Pesa or bank charge for sending the pay"), Method: MethodTiered, Base: BaseNet, Frequency: FreqEveryRun, Priority: 100},
	}
	for i := range list {
		list[i].ID = uuid.New().String()
		list[i].SaccoID = saccoID
		list[i].AppliesTo = AppliesAll
		if list[i].Base == "" {
			list[i].Base = BaseGross
		}
	}
	return list
}
