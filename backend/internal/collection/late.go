package collection

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/codetheuri/tusk/internal/middleware"
)

// LateEntry marks a record entered after its day. Sacco staff record milk
// only for today; an earlier day is entered by DairyGo support from the
// platform console, with a reason. Both fields are empty for records made on
// the day, and the record's collector stays the one the milk belongs to.
type LateEntry struct {
	LateReason  *string `json:"late_reason,omitempty" doc:"Why the day was entered late (console entries only)"`
	EnteredByID *uint   `json:"entered_by_id,omitempty" doc:"The DairyGo support user who entered it late"`
}

// recordDay checks the day a milk record is for. No one records a future
// day. Sacco staff record only today; a platform operator may enter an
// earlier day with a reason, which is returned for the record. what names
// the record in messages ("milk", "the sale"...).
func recordDay(day time.Time, today string, platform bool, reason *string, what string) (*string, error) {
	d := day.Format(dateLayout)
	switch {
	case d > today:
		return nil, fmt.Errorf("%s cannot be recorded for a future date", what)
	case d == today:
		return nil, nil
	case !platform:
		return nil, fmt.Errorf("%w: %s can only be recorded for today. To enter an earlier day, ask DairyGo support", ErrForbidden, what)
	}
	why := ""
	if reason != nil {
		why = strings.TrimSpace(*reason)
	}
	if len(why) < 3 {
		return nil, fmt.Errorf("say why %s for %s is being entered late (late_reason)", what, d)
	}
	return &why, nil
}

// lateEntry checks the day of a new record and, for a console late entry,
// returns what marks it as such.
func lateEntry(ctx context.Context, day time.Time, reason *string, what string) (LateEntry, error) {
	why, err := recordDay(day, time.Now().Format(dateLayout), middleware.IsSuperUser(ctx), reason, what)
	if err != nil || why == nil {
		return LateEntry{}, err
	}
	by := middleware.GetUserID(ctx)
	return LateEntry{LateReason: why, EnteredByID: &by}, nil
}

// collectorFor is who a new record belongs to: the caller, or for DairyGo
// support (who are not Sacco staff) the active staff member they name.
func (s *Service) collectorFor(ctx context.Context, chosen *uint) (uint, error) {
	caller := middleware.GetUserID(ctx)
	if !middleware.IsSuperUser(ctx) {
		if chosen != nil && *chosen != 0 && *chosen != caller {
			return 0, fmt.Errorf("%w: you can only record your own milk", ErrForbidden)
		}
		return caller, nil
	}
	if chosen == nil || *chosen == 0 {
		return 0, fmt.Errorf("choose the collector the milk belongs to (collector_id)")
	}
	staff, err := s.repo.FindTransferRecipient(ctx, *chosen)
	if err != nil {
		return 0, err
	}
	return staff.ID, nil
}

// LateRecords lists the Sacco's records entered after their day.
func (s *Service) LateRecords(ctx context.Context) ([]LateRecord, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, fmt.Errorf("sacco context is required")
	}
	return s.repo.LateRecords(ctx, saccoID)
}

// Collectors lists the Sacco's active staff who record milk, the people a
// late entry can belong to.
func (s *Service) Collectors(ctx context.Context) ([]TransferRecipient, error) {
	return s.repo.ListTransferRecipients(ctx, 0)
}
