package report

import (
	"github.com/codetheuri/tusk/pkg/query"
	"github.com/codetheuri/tusk/pkg/response"
)

// --- FARMER PAYOUT REPORT DTOs ---

type FarmerPayoutReportInput struct {
	Page     int    `query:"page" doc:"Page number"`
	PerPage  int    `query:"per_page" doc:"Items per page"`
	MemberID string `query:"member_id" doc:"Optional Member UUID filter"`
	FromDate string `query:"from_date" doc:"Filter start date (YYYY-MM-DD), defaults to 1st of current month"`
	ToDate   string `query:"to_date" doc:"Filter end date (YYYY-MM-DD), defaults to today"`
}

type FarmerPayoutReportData struct {
	Statements []FarmerPayoutStatement `json:"statements"`
	Meta       query.Meta              `json:"meta"`
}

type FarmerPayoutReportOutput struct {
	Body response.Data[FarmerPayoutReportData]
}

// --- SACCO RECONCILIATION LEDGER DTOs ---

type ReconciliationReportInput struct {
	FromDate string `query:"from_date" doc:"Filter start date (YYYY-MM-DD), defaults to 1st of current month"`
	ToDate   string `query:"to_date" doc:"Filter end date (YYYY-MM-DD), defaults to today"`
}

type ReconciliationReportData struct {
	Ledger SaccoReconciliationLedger `json:"ledger"`
}

type ReconciliationReportOutput struct {
	Body response.Data[ReconciliationReportData]
}

// --- COLLECTOR AUDIT REPORT DTOs ---

type CollectorAuditReportInput struct {
	Page        int    `query:"page" doc:"Page number"`
	PerPage     int    `query:"per_page" doc:"Items per page"`
	CollectorID uint   `query:"collector_id" doc:"Optional Collector User ID filter"`
	FromDate    string `query:"from_date" doc:"Filter start date (YYYY-MM-DD), defaults to 1st of current month"`
	ToDate      string `query:"to_date" doc:"Filter end date (YYYY-MM-DD), defaults to today"`
}

type CollectorAuditReportData struct {
	AuditSummaries []CollectorAuditSummary `json:"audit_summaries"`
	Meta           query.Meta              `json:"meta"`
}

type CollectorAuditReportOutput struct {
	Body response.Data[CollectorAuditReportData]
}
