package dashboard

import "github.com/codetheuri/tusk/pkg/response"

// --- EXECUTIVE DASHBOARD DTOs ---

type ExecutiveDashboardInput struct {
	Days int `query:"days" doc:"Number of trend days to include (default 7, max 30)"`
}

type ExecutiveDashboardOutput struct {
	Body response.Data[ExecutiveDashboardData]
}

// --- COLLECTOR MOBILE DASHBOARD DTOs ---

type CollectorDashboardInput struct {
	Date string `query:"date" doc:"Date for mobile summary (YYYY-MM-DD), defaults to today"`
}

type CollectorDashboardOutput struct {
	Body response.Data[CollectorDashboardData]
}
