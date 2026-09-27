package collection

import (
	"errors"
	"fmt"
	"math"
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

// Sale payment statuses, derived from what was paid at the time of sale.
const (
	SalePaid    = "PAID"
	SalePartial = "PARTIAL"
	SaleCredit  = "CREDIT"
)

var validSaleMethods = map[string]bool{"CASH": true, "MPESA": true, "BANK_TRANSFER": true, "CREDIT": true}

// settleSale works out what was paid at the time of sale and the resulting
// payment status. When amountPaid is nil the whole total is paid, unless the
// method is CREDIT. A sale with nothing paid is always recorded as CREDIT.
// The status describes the sale moment only; later payments reduce the
// customer's running balance, not individual sales.
func settleSale(total float64, amountPaid *float64, method string) (paid float64, status string, finalMethod string, err error) {
	if method == "" {
		method = "CASH"
	}
	if !validSaleMethods[method] {
		return 0, "", "", fmt.Errorf("payment_method must be CASH, MPESA, BANK_TRANSFER or CREDIT")
	}

	switch {
	case amountPaid != nil:
		paid = math.Round(*amountPaid*100) / 100
	case method == "CREDIT":
		paid = 0
	default:
		paid = total
	}

	if paid < 0 {
		return 0, "", "", fmt.Errorf("amount_paid cannot be negative")
	}
	if paid > total {
		return 0, "", "", fmt.Errorf("amount_paid (%.2f) cannot exceed the sale total (%.2f); record extra money as a customer payment", paid, total)
	}
	if paid > 0 && method == "CREDIT" {
		return 0, "", "", fmt.Errorf("payment_method CREDIT means nothing was paid; choose how the %.2f was received", paid)
	}

	switch {
	case paid == 0:
		return 0, SaleCredit, "CREDIT", nil
	case paid < total:
		return paid, SalePartial, method, nil
	default:
		return paid, SalePaid, method, nil
	}
}

// canEditSale applies the collection edit rules to sales: voided sales are
// locked; admins (milk.sales.manage) may edit any other sale; collectors may
// edit only their own sales on the day they were recorded.
func canEditSale(a actor, s *MilkSale, today string) error {
	if s.VoidedAt != nil {
		return fmt.Errorf("%w: sale is voided", ErrLocked)
	}
	if a.canManage {
		return nil
	}
	if s.CollectorID != a.userID {
		return fmt.Errorf("%w: you can only edit sales you recorded", ErrForbidden)
	}
	if s.CreatedAt.In(time.Local).Format(dateLayout) != today {
		return fmt.Errorf("%w: sales can only be edited on the day they were recorded; ask an admin", ErrLocked)
	}
	return nil
}
