package sacco

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

// Sacco represents a Dairy Cooperative entity in the multi-tenant platform.
type Sacco struct {
	ID        string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	Code      string         `json:"code" gorm:"uniqueIndex;not null"`
	Name      string         `json:"name" gorm:"not null"`
	Email     *string        `json:"email,omitempty"`
	Phone     *string        `json:"phone,omitempty"`
	Address   *string        `json:"address,omitempty"`
	Status    Status         `json:"status" gorm:"default:'ACTIVE';index"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"deleted_at,omitempty" gorm:"index"`

	Settings *SaccoSettings `json:"settings,omitempty" gorm:"foreignKey:SaccoID"`
}

// TableName explicitly overrides table name.
func (Sacco) TableName() string {
	return "saccos"
}

// SaccoSettings contains operational and business parameters for a specific Sacco tenant.
type SaccoSettings struct {
	SaccoID           string  `json:"sacco_id" gorm:"primaryKey;type:varchar(36)"`
	Currency          string  `json:"currency" gorm:"default:'KES'"`
	MilkUnit          string  `json:"milk_unit" gorm:"default:'LITRES'"`
	MorningCutoffTime *string `json:"morning_cutoff_time,omitempty"`
	EveningCutoffTime *string `json:"evening_cutoff_time,omitempty"`
	// ReconciliationToleranceLitres is the measuring difference allowed per
	// collector per day before milk counts as missing or oversold.
	ReconciliationToleranceLitres float64 `json:"reconciliation_tolerance_litres" gorm:"default:0"`
	// InactiveAfterDays is how many days without milk make an active farmer
	// inactive automatically; 0 turns this off (see member.MarkIdleInactive).
	InactiveAfterDays int `json:"inactive_after_days" gorm:"default:60"`
	// AdvanceMaxPerPeriod is the most a farmer may take in advances between
	// pay runs; nil means no limit (see payout.Service.RecordEntry).
	AdvanceMaxPerPeriod *float64 `json:"advance_max_per_period"`
	// AdvanceLastDay is the last day of the month advances are given (1st
	// up to it); nil means any day.
	AdvanceLastDay *int `json:"advance_last_day"`
	// AdvanceMilkPercent caps an advance at this share of the milk delivered
	// since the last pay run, less what the farmer owes; nil means no cap.
	AdvanceMilkPercent *int `json:"advance_milk_percent"`
	// PayrollClosedThrough is the last day farmers have been paid for: milk
	// records up to it are locked. Only approving or cancelling a pay run
	// changes it, so settings saves never write it ("->" is read-only).
	PayrollClosedThrough *time.Time `json:"payroll_closed_through,omitempty" gorm:"->;type:date"`
	CreatedAt            time.Time  `json:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at"`
}

// TableName explicitly overrides table name.
func (SaccoSettings) TableName() string {
	return "sacco_settings"
}
