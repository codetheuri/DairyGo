package member

import (
	"time"

	"gorm.io/gorm"
)

type Status string

const (
	StatusActive    Status = "ACTIVE"
	StatusInactive  Status = "INACTIVE"
	StatusSuspended Status = "SUSPENDED"
)

// Member represents a Dairy Producer / Farmer belonging to a specific Sacco.
type Member struct {
	ID               string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID          string         `json:"sacco_id" gorm:"index;type:varchar(36);not null"`
	MembershipNumber string         `json:"membership_number" gorm:"not null"`
	FirstName        string         `json:"first_name" gorm:"not null"`
	LastName         string         `json:"last_name" gorm:"not null"`
	NationalID       *string        `json:"national_id,omitempty"`
	Phone            string         `json:"phone" gorm:"not null"`
	Email            *string        `json:"email,omitempty"`
	Gender           *string        `json:"gender,omitempty"`
	Location         *string        `json:"location,omitempty"`
	Status           Status         `json:"status" gorm:"default:'ACTIVE';index"`
	MpesaNumber      *string        `json:"mpesa_number,omitempty"`
	MpesaName        *string        `json:"mpesa_name,omitempty"`
	BankName         *string        `json:"bank_name,omitempty"`
	BankAccountNumber *string       `json:"bank_account_number,omitempty"`
	BankBranch       *string        `json:"bank_branch,omitempty"`
	RegisteredByID   *uint          `json:"registered_by_id,omitempty"`
	CreatedAt        time.Time      `json:"created_at"`
	UpdatedAt        time.Time      `json:"updated_at"`
	DeletedAt        gorm.DeletedAt `json:"deleted_at,omitempty" gorm:"index"`
}

// TableName explicitly sets the database table name.
func (Member) TableName() string {
	return "members"
}
