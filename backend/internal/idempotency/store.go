// Package idempotency makes writes safe to retry. A client sends a unique
// Idempotency-Key header with each save; if the same save arrives again (the
// user tapped twice, or the response was lost on a slow connection and the
// app retried), the stored response is returned instead of recording the
// sale, payment or collection a second time.
package idempotency

import (
	"context"
	"errors"
	"time"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// Record is one keyed request and, once finished, its response.
type Record struct {
	ID           uint      `gorm:"primaryKey"`
	UserID       uint      `gorm:"not null"`
	Key          string    `gorm:"column:idem_key;not null"`
	Method       string    `gorm:"not null"`
	Path         string    `gorm:"not null"`
	RequestHash  string    `gorm:"not null"`
	StatusCode   int       `gorm:"not null;default:0"` // 0 while running
	ContentType  string    `gorm:"type:varchar(100)"`
	ResponseBody string    `gorm:"type:text"`
	CreatedAt    time.Time `gorm:"not null"`
	CompletedAt  *time.Time
}

func (Record) TableName() string { return "idempotency_keys" }

// InProgress reports whether the first request with this key is still running.
func (r *Record) InProgress() bool { return r.StatusCode == 0 }

// Store keeps idempotency records in the database.
type Store struct {
	db *gorm.DB
}

func NewStore(db *gorm.DB) *Store { return &Store{db: db} }

// Begin claims the key for rec. It returns nil if this request now owns the
// key, or the existing record if the key was used before. The unique
// (user_id, idem_key) constraint makes the claim atomic, so two identical
// requests arriving together cannot both run.
func (s *Store) Begin(ctx context.Context, rec *Record) (*Record, error) {
	// Two attempts: the key may be released between our insert and our read.
	for attempt := 0; attempt < 2; attempt++ {
		res := s.db.WithContext(ctx).
			Clauses(clause.OnConflict{DoNothing: true}).
			Create(rec)
		if res.Error != nil {
			return nil, res.Error
		}
		if res.RowsAffected == 1 {
			return nil, nil
		}
		var existing Record
		err := s.db.WithContext(ctx).
			Where("user_id = ? AND idem_key = ?", rec.UserID, rec.Key).
			First(&existing).Error
		if errors.Is(err, gorm.ErrRecordNotFound) {
			rec.ID = 0
			continue
		}
		return &existing, err
	}
	return nil, errors.New("idempotency key is being released and claimed concurrently")
}

// Complete stores the response of the request that owns the key.
func (s *Store) Complete(ctx context.Context, userID uint, key string, status int, contentType string, body []byte) error {
	now := time.Now()
	return s.db.WithContext(ctx).Model(&Record{}).
		Where("user_id = ? AND idem_key = ?", userID, key).
		Updates(map[string]any{
			"status_code":   status,
			"content_type":  contentType,
			"response_body": string(body),
			"completed_at":  &now,
		}).Error
}

// Release frees the key so the request can be tried again, e.g. after a
// server error in which nothing was saved.
func (s *Store) Release(ctx context.Context, userID uint, key string) error {
	return s.db.WithContext(ctx).
		Where("user_id = ? AND idem_key = ?", userID, key).
		Delete(&Record{}).Error
}

// Purge deletes records older than cutoff. Clients only retry within
// minutes, so a day or two of history is plenty.
func (s *Store) Purge(ctx context.Context, cutoff time.Time) (int64, error) {
	res := s.db.WithContext(ctx).Where("created_at < ?", cutoff).Delete(&Record{})
	return res.RowsAffected, res.Error
}
