package collection

import (
	"errors"
	"fmt"
	"time"
)

// Domain errors returned by the service. Handlers map them to HTTP status
// codes with errors.Is, so business rules never need to know about HTTP.
var (
	// ErrForbidden means the caller may not act on this record at all.
	ErrForbidden = errors.New("forbidden")
	// ErrLocked means the record exists but its current state does not allow the change.
	ErrLocked = errors.New("locked")
	// ErrNotFound means the record does not exist in the caller's Sacco.
	ErrNotFound = errors.New("not found")
)

// dateLayout is the calendar-date format used across the API and in queries.
const dateLayout = "2006-01-02"

// actor is the authenticated user performing a change.
// canManage is true for users holding milk.collections.manage (Sacco admins)
// and for platform super users.
type actor struct {
	userID    uint
	canManage bool
}

// canEditCollection enforces who may edit a collection and when:
//   - VERIFIED and REJECTED records are locked for everyone; an admin must
//     reopen them as ADJUSTED first.
//   - Admins may edit any SUBMITTED or ADJUSTED record; an admin edit marks
//     the record ADJUSTED (see Service.UpdateCollection).
//   - Collectors may edit only their own SUBMITTED records, and only on the
//     day the record was created. "today" is a date in dateLayout.
func canEditCollection(a actor, c *MilkCollection, today string) error {
	if c.Status == StatusVerified || c.Status == StatusRejected {
		return fmt.Errorf("%w: collection is %s; an admin must reopen it as ADJUSTED before editing", ErrLocked, c.Status)
	}
	if a.canManage {
		return nil
	}
	if c.CollectorID != a.userID {
		return fmt.Errorf("%w: you can only edit collections you recorded", ErrForbidden)
	}
	if c.Status != StatusSubmitted {
		return fmt.Errorf("%w: collection is %s; only an admin can edit it", ErrLocked, c.Status)
	}
	if c.CreatedAt.In(time.Local).Format(dateLayout) != today {
		return fmt.Errorf("%w: collections can only be edited on the day they were recorded; ask an admin", ErrLocked)
	}
	return nil
}

// allowedTransitions lists the status changes an admin may make.
// VERIFIED and REJECTED can only be reopened as ADJUSTED.
var allowedTransitions = map[CollectionStatus][]CollectionStatus{
	StatusSubmitted: {StatusVerified, StatusRejected, StatusAdjusted},
	StatusAdjusted:  {StatusVerified, StatusRejected},
	StatusVerified:  {StatusAdjusted},
	StatusRejected:  {StatusAdjusted},
}

// validateStatusTransition reports whether a collection may move from one status to another.
func validateStatusTransition(from, to CollectionStatus) error {
	for _, allowed := range allowedTransitions[from] {
		if allowed == to {
			return nil
		}
	}
	return fmt.Errorf("%w: cannot change status from %s to %s", ErrLocked, from, to)
}
