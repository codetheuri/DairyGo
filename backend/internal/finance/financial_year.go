package finance

import (
	"context"
	"fmt"
	"time"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
)

// The Sacco's financial year: twelve months from the start month it chooses
// (sacco_settings.financial_year_start_month, 1 = January). It only groups
// dates for reports, so changing it never changes a record.

// FinancialYear is the start month and this and last financial year's dates.
type FinancialYear struct {
	StartMonth int    `json:"start_month" doc:"1 = January … 12 = December"`
	ThisFrom   string `json:"this_from" doc:"First day of this financial year"`
	ThisTo     string `json:"this_to" doc:"Last day of this financial year"`
	LastFrom   string `json:"last_from"`
	LastTo     string `json:"last_to"`
}

// yearOf is the financial year that day falls in, for a year starting in
// startMonth.
func yearOf(day time.Time, startMonth int) (from, to time.Time) {
	year := day.Year()
	if int(day.Month()) < startMonth {
		year--
	}
	from = time.Date(year, time.Month(startMonth), 1, 0, 0, 0, 0, time.UTC)
	return from, from.AddDate(1, 0, -1)
}

// financialYear works out this and last financial year as of today.
func financialYear(today time.Time, startMonth int) *FinancialYear {
	from, to := yearOf(today, startMonth)
	lastFrom, lastTo := yearOf(from.AddDate(0, 0, -1), startMonth)
	return &FinancialYear{StartMonth: startMonth, ThisFrom: from.Format(dateLayout), ThisTo: to.Format(dateLayout),
		LastFrom: lastFrom.Format(dateLayout), LastTo: lastTo.Format(dateLayout)}
}

// FinancialYear returns the Sacco's financial year.
func (s *Service) FinancialYear(ctx context.Context) (*FinancialYear, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	month, err := s.repo.FinancialYearStart(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	return financialYear(s.today(), month), nil
}

// SetFinancialYear changes the month the financial year starts.
func (s *Service) SetFinancialYear(ctx context.Context, month int) (*FinancialYear, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	if month < 1 || month > 12 {
		return nil, fmt.Errorf("%w: the start month must be 1 (January) to 12 (December)", ErrInvalid)
	}
	old, err := s.repo.FinancialYearStart(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	if old != month {
		entry := audit.Entry{SaccoID: saccoID, EntityType: "sacco_settings", EntityID: saccoID, Action: audit.ActionUpdate,
			ActorID:   middleware.GetUserID(ctx),
			OldValues: map[string]int{"financial_year_start_month": old},
			NewValues: map[string]int{"financial_year_start_month": month}}
		if err := s.repo.SetFinancialYearStart(ctx, saccoID, month, entry); err != nil {
			return nil, err
		}
	}
	return financialYear(s.today(), month), nil
}
