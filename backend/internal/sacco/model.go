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
	SaccoID           string    `json:"sacco_id" gorm:"primaryKey;type:varchar(36)"`
	Currency          string    `json:"currency" gorm:"default:'KES'"`
	MilkUnit          string    `json:"milk_unit" gorm:"default:'LITRES'"`
	MorningCutoffTime *string   `json:"morning_cutoff_time,omitempty"`
	EveningCutoffTime *string   `json:"evening_cutoff_time,omitempty"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// TableName explicitly overrides table name.
func (SaccoSettings) TableName() string {
	return "sacco_settings"
}
