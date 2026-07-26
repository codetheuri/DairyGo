package dashboard

import (
	"context"
	"strings"
	"time"

	"github.com/codetheuri/tusk/internal/middleware"
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) GetExecutiveDashboard(ctx context.Context, days int) (*ExecutiveDashboardData, error) {
	if days <= 0 {
		days = 7
	}
	if days > 30 {
		days = 30
	}
	return s.repo.GetExecutiveDashboard(ctx, days)
}

func (s *Service) GetCollectorDashboard(ctx context.Context, dateStr string) (*CollectorDashboardData, error) {
	collectorID := middleware.GetUserID(ctx)
	if strings.TrimSpace(dateStr) == "" {
		dateStr = time.Now().Format("2006-01-02")
	}

	return s.repo.GetCollectorDashboard(ctx, collectorID, dateStr)
}
