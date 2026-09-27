// Package audit records who changed a business record, when, why, and what
// the values were before and after.
//
// Entries are written with the same *gorm.DB transaction as the change they
// describe, so a change and its audit entry are committed or rolled back
// together.
package audit

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Action names the kind of change an entry describes.
type Action string

const (
	ActionCreate Action = "CREATE"
	ActionUpdate Action = "UPDATE"
	ActionStatus Action = "STATUS"
	ActionVoid   Action = "VOID"
)

// Entry describes one change to an audited record.
// OldValues and NewValues are marshalled to JSON; nil values are stored as NULL.
type Entry struct {
	SaccoID    string
	EntityType string
	EntityID   string
	Action     Action
	ActorID    uint
	Reason     *string
	OldValues  any
	NewValues  any
}

// Log is a stored audit entry, as returned by List.
type Log struct {
	ID         string    `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID    *string   `json:"sacco_id,omitempty"`
	EntityType string    `json:"entity_type"`
	EntityID   string    `json:"entity_id"`
	Action     Action    `json:"action"`
	ActorID    *uint     `json:"actor_id,omitempty"`
	ActorName  string    `json:"actor_name,omitempty" gorm:"->;-:migration"`
	Reason     *string   `json:"reason,omitempty"`
	OldValues  *string   `json:"old_values,omitempty"`
	NewValues  *string   `json:"new_values,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
}

// TableName sets the database table name.
func (Log) TableName() string {
	return "audit_logs"
}

// Record stores an entry using tx, which should be the transaction that
// performs the audited change.
func Record(tx *gorm.DB, e Entry) error {
	oldJSON, err := marshal(e.OldValues)
	if err != nil {
		return fmt.Errorf("audit: encode old values: %w", err)
	}
	newJSON, err := marshal(e.NewValues)
	if err != nil {
		return fmt.Errorf("audit: encode new values: %w", err)
	}

	log := Log{
		ID:         uuid.New().String(),
		EntityType: e.EntityType,
		EntityID:   e.EntityID,
		Action:     e.Action,
		Reason:     e.Reason,
		OldValues:  oldJSON,
		NewValues:  newJSON,
	}
	if e.SaccoID != "" {
		log.SaccoID = &e.SaccoID
	}
	if e.ActorID > 0 {
		log.ActorID = &e.ActorID
	}

	if err := tx.Omit("ActorName").Create(&log).Error; err != nil {
		return fmt.Errorf("audit: save entry: %w", err)
	}
	return nil
}

// List returns the history of one record in a Sacco, oldest first, with the
// actor's username filled in.
func List(ctx context.Context, db *gorm.DB, saccoID, entityType, entityID string) ([]Log, error) {
	var logs []Log
	err := db.WithContext(ctx).
		Table("audit_logs").
		Select("audit_logs.*, users.username AS actor_name").
		Joins("LEFT JOIN users ON users.id = audit_logs.actor_id").
		Where("audit_logs.sacco_id = ? AND audit_logs.entity_type = ? AND audit_logs.entity_id = ?", saccoID, entityType, entityID).
		Order("audit_logs.created_at ASC").
		Scan(&logs).Error
	if err != nil {
		return nil, fmt.Errorf("audit: list entries: %w", err)
	}
	return logs, nil
}

func marshal(v any) (*string, error) {
	if v == nil {
		return nil, nil
	}
	b, err := json.Marshal(v)
	if err != nil {
		return nil, err
	}
	s := string(b)
	return &s, nil
}
