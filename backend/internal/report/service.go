package report

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/codetheuri/tusk/pkg/query"
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

// GetFarmerPayoutReport computes itemized farmer payout statements for a date range.
func (s *Service) GetFarmerPayoutReport(ctx context.Context, fromDateStr, toDateStr, memberID string, page, perPage int) ([]FarmerPayoutStatement, query.Meta, error) {
	fromDate, toDate, err := parseDateRange(fromDateStr, toDateStr)
	if err != nil {
		return nil, query.Meta{}, err
	}

	return s.repo.GetFarmerPayoutStatements(ctx, fromDate, toDate, memberID, page, perPage)
}

// GetSaccoReconciliationLedger generates the Sacco-wide mathematical balancing statement.
func (s *Service) GetSaccoReconciliationLedger(ctx context.Context, fromDateStr, toDateStr string) (*SaccoReconciliationLedger, error) {
	fromDate, toDate, err := parseDateRange(fromDateStr, toDateStr)
	if err != nil {
		return nil, err
	}

	return s.repo.GetSaccoReconciliationLedger(ctx, fromDate.Format("2006-01-02"), toDate.Format("2006-01-02"))
}

// GetCollectorAuditReport generates transit and performance logs for collectors.
func (s *Service) GetCollectorAuditReport(ctx context.Context, fromDateStr, toDateStr string, collectorID uint, page, perPage int) ([]CollectorAuditSummary, query.Meta, error) {
	fromDate, toDate, err := parseDateRange(fromDateStr, toDateStr)
	if err != nil {
		return nil, query.Meta{}, err
	}

	return s.repo.GetCollectorAuditSummaries(ctx, fromDate.Format("2006-01-02"), toDate.Format("2006-01-02"), collectorID, page, perPage)
}

// Helper to resolve and validate date range parameters
func parseDateRange(fromDateStr, toDateStr string) (time.Time, time.Time, error) {
	now := time.Now()
	
	// Default fromDate: 1st day of current month
	fromDate := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
	if strings.TrimSpace(fromDateStr) != "" {
		parsed, err := time.Parse("2006-01-02", strings.TrimSpace(fromDateStr))
		if err != nil {
			return time.Time{}, time.Time{}, fmt.Errorf("invalid from_date format, expected YYYY-MM-DD")
		}
		fromDate = parsed
	}

	// Default toDate: today
	toDate := now
	if strings.TrimSpace(toDateStr) != "" {
		parsed, err := time.Parse("2006-01-02", strings.TrimSpace(toDateStr))
		if err != nil {
			return time.Time{}, time.Time{}, fmt.Errorf("invalid to_date format, expected YYYY-MM-DD")
		}
		toDate = parsed
	}

	if fromDate.After(toDate) {
		return time.Time{}, time.Time{}, fmt.Errorf("from_date cannot be after to_date")
	}

	return fromDate, toDate, nil
}
