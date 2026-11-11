package ledger

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
)

// Service holds the rules for the accountant's work on the books.
type Service struct {
	db  *gorm.DB
	now func() time.Time
}

// NewService creates a books service.
func NewService(db *gorm.DB) *Service {
	return &Service{db: db, now: time.Now}
}

func (s *Service) saccoID(ctx context.Context) (string, error) {
	id, ok := middleware.GetSaccoID(ctx)
	if !ok || id == "" {
		return "", fmt.Errorf("%w: sacco context is required", ErrInvalid)
	}
	return id, nil
}

func (s *Service) today() time.Time {
	n := s.now().In(time.Local)
	return time.Date(n.Year(), n.Month(), n.Day(), 0, 0, 0, 0, time.UTC)
}

func actor(ctx context.Context) *uint {
	if id := middleware.GetUserID(ctx); id > 0 {
		return &id
	}
	return nil
}

func parseDay(v string, def time.Time) (time.Time, error) {
	v = strings.TrimSpace(v)
	if v == "" {
		return def, nil
	}
	d, err := time.Parse(dateLayout, v)
	if err != nil {
		return time.Time{}, fmt.Errorf("%w: dates must look like 2026-10-31", ErrInvalid)
	}
	return d, nil
}

// started loads the Sacco's books, or ErrNotStarted.
func (s *Service) started(ctx context.Context, db *gorm.DB, saccoID string) (*Books, error) {
	b, err := findBooks(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	if b == nil {
		return nil, fmt.Errorf("%w: the books have not been started yet", ErrNotStarted)
	}
	return b, nil
}

// --- starting the books ---

// BooksStatus is the books at a glance: whether they have started, and whether
// they agree with the records.
type BooksStatus struct {
	Started           bool       `json:"started"`
	StartDate         *string    `json:"start_date,omitempty"`
	Journals          int64      `json:"journals"`
	SyncedAt          *time.Time `json:"checked_at,omitempty" doc:"When every record was last compared with the books"`
	Balanced          bool       `json:"balanced" doc:"Debits equal credits"`
	Agrees            bool       `json:"agrees" doc:"Every account kept from records equals what the records say"`
	Controls          []Control  `json:"controls"`
	NotInAccount      float64    `json:"not_in_account" doc:"Money recorded without naming an account (Money not in an account)"`
	ClosedThrough     *string    `json:"closed_through,omitempty" doc:"Nothing may be dated on or before this day"`
	YearClosedThrough *string    `json:"year_closed_through,omitempty" doc:"The end of the last financial year closed into retained surplus"`
}

// Status reports on the Sacco's books.
func (s *Service) Status(ctx context.Context) (*BooksStatus, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	db := s.db.WithContext(ctx)
	b, err := findBooks(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	out := &BooksStatus{Controls: []Control{}}
	if b == nil {
		return out, nil
	}
	start := b.StartDate.Format(dateLayout)
	out.Started, out.StartDate, out.SyncedAt = true, &start, b.SyncedAt
	out.ClosedThrough, out.YearClosedThrough = dayPtr(b.ClosedThrough), dayPtr(b.YearClosedThrough)
	if err := db.Model(&Journal{}).Where("sacco_id = ?", saccoID).Count(&out.Journals).Error; err != nil {
		return nil, err
	}
	check, err := s.check(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	out.Balanced, out.Agrees, out.Controls, out.NotInAccount = check.Balanced, check.Agrees, check.Controls, check.NotInAccount
	return out, nil
}

// StartRequest starts the books, or moves their start date.
type StartRequest struct {
	StartDate string `json:"start_date" doc:"The first day of the books (YYYY-MM-DD); everything before it becomes one opening journal"`
	Reason    string `json:"reason,omitempty" doc:"Why the start date is moving (needed once the books have started)"`
}

// Start begins the books from a day: the chart is made, every record from
// that day posts its journal and everything before it is summed into the
// opening journal. Moving the start date later rebuilds the automatic
// journals the same way; the accountant's own journals stay, so none may be
// dated before the new start.
func (s *Service) Start(ctx context.Context, req *StartRequest) (*BooksStatus, int, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, 0, err
	}
	start, err := time.Parse(dateLayout, strings.TrimSpace(req.StartDate))
	if err != nil {
		return nil, 0, fmt.Errorf("%w: choose the day the books start", ErrInvalid)
	}
	if start.After(s.today()) {
		return nil, 0, fmt.Errorf("%w: the books cannot start in the future", ErrInvalid)
	}
	reason := strings.TrimSpace(req.Reason)
	made := 0
	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		old, err := findBooks(ctx, tx, saccoID)
		if err != nil {
			return err
		}
		entry := audit.Entry{SaccoID: saccoID, EntityType: "books", EntityID: saccoID, ActorID: middleware.GetUserID(ctx),
			NewValues: map[string]any{"start_date": start.Format(dateLayout)}}
		if old == nil {
			entry.Action = audit.ActionCreate
			if err := tx.Create(&Books{SaccoID: saccoID, StartDate: start, StartedByID: actor(ctx)}).Error; err != nil {
				return err
			}
		} else {
			if old.StartDate.Equal(start) {
				return fmt.Errorf("%w: the books already start on %s", ErrConflict, start.Format("2 Jan 2006"))
			}
			if len(reason) < 3 {
				return fmt.Errorf("%w: give the reason for moving the start of the books", ErrInvalid)
			}
			if old.ClosedThrough != nil {
				return fmt.Errorf("%w: the books are closed through %s; reopen every month before moving their start",
					ErrConflict, old.ClosedThrough.Format("2 Jan 2006"))
			}
			var early int64
			if err := tx.Model(&Journal{}).Where("sacco_id = ? AND kind = ? AND journal_date < ?", saccoID, KindManual, start.Format(dateLayout)).
				Count(&early).Error; err != nil {
				return err
			}
			if early > 0 {
				return fmt.Errorf("%w: %s dated before %s; reverse them first or choose an earlier day",
					ErrConflict, plural(int(early), "journal"), start.Format("2 Jan 2006"))
			}
			var manual int64
			if err := tx.Model(&Journal{}).Where("sacco_id = ? AND kind = ?", saccoID, KindManual).Count(&manual).Error; err != nil {
				return err
			}
			// The automatic journals are rebuilt from the records; nothing
			// else refers to them.
			if err := tx.Exec("DELETE FROM journals WHERE sacco_id = ? AND kind = ?", saccoID, KindAuto).Error; err != nil {
				return err
			}
			fields := map[string]any{"start_date": start.Format(dateLayout), "updated_at": time.Now()}
			if manual == 0 {
				fields["next_number"] = 0 // nothing left: number from 1 again
			}
			if err := tx.Model(&Books{}).Where("sacco_id = ?", saccoID).Updates(fields).Error; err != nil {
				return err
			}
			entry.Action, entry.Reason = audit.ActionUpdate, &reason
			entry.OldValues = map[string]any{"start_date": old.StartDate.Format(dateLayout)}
		}
		c, err := loadChart(ctx, tx, saccoID)
		if err != nil {
			return err
		}
		if err := c.seedAll(); err != nil {
			return err
		}
		if made, err = SyncAll(ctx, tx, saccoID, actor(ctx)); err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
	if err != nil {
		return nil, 0, err
	}
	st, err := s.Status(ctx)
	return st, made, err
}

// BringUpToDate compares every record with the books now (as the nightly
// check does) and returns how many journals that made.
func (s *Service) BringUpToDate(ctx context.Context) (*BooksStatus, int, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, 0, err
	}
	made := 0
	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if _, err := s.started(ctx, tx, saccoID); err != nil {
			return err
		}
		made, err = SyncAll(ctx, tx, saccoID, actor(ctx))
		return err
	})
	if err != nil {
		return nil, 0, err
	}
	st, err := s.Status(ctx)
	return st, made, err
}

// SyncEverySacco is the nightly check: every Sacco's books compared with
// its records. It returns how many Saccos were checked and journals made.
func SyncEverySacco(ctx context.Context, db *gorm.DB) (saccos, made int, err error) {
	var ids []string
	if err := db.WithContext(ctx).Model(&Books{}).Pluck("sacco_id", &ids).Error; err != nil {
		return 0, 0, err
	}
	var errs []error
	for _, id := range ids {
		if ctx.Err() != nil {
			return saccos, made, ctx.Err()
		}
		err := db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
			n, err := SyncAll(ctx, tx, id, nil)
			made += n
			return err
		})
		if err != nil {
			errs = append(errs, fmt.Errorf("sacco %s: %w", id, err))
			continue
		}
		saccos++
	}
	return saccos, made, errors.Join(errs...)
}

func dayPtr(d *time.Time) *string {
	if d == nil {
		return nil
	}
	v := d.Format(dateLayout)
	return &v
}
