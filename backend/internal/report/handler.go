package report

import (
	"context"

	"github.com/danielgtaylor/huma/v2"

	"github.com/codetheuri/tusk/pkg/logger"
)

type Handler struct {
	service *Service
	log     logger.Logger
}

func NewHandler(service *Service, log logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

func (h *Handler) GetFarmerPayoutReport(ctx context.Context, input *FarmerPayoutReportInput) (*FarmerPayoutReportOutput, error) {
	statements, meta, err := h.service.GetFarmerPayoutReport(ctx, input.FromDate, input.ToDate, input.MemberID, input.Page, input.PerPage)
	if err != nil {
		h.log.Error("Failed to generate farmer payout report", err)
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &FarmerPayoutReportOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Farmer payout report generated successfully"
	resp.Body.Data.Statements = statements
	resp.Body.Data.Meta = meta
	return resp, nil
}

func (h *Handler) GetReconciliationLedger(ctx context.Context, input *ReconciliationReportInput) (*ReconciliationReportOutput, error) {
	ledger, err := h.service.GetSaccoReconciliationLedger(ctx, input.FromDate, input.ToDate)
	if err != nil {
		h.log.Error("Failed to generate reconciliation ledger", err)
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &ReconciliationReportOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Sacco reconciliation balancing ledger generated successfully"
	resp.Body.Data.Ledger = *ledger
	return resp, nil
}

func (h *Handler) GetCollectorAuditReport(ctx context.Context, input *CollectorAuditReportInput) (*CollectorAuditReportOutput, error) {
	summaries, meta, err := h.service.GetCollectorAuditReport(ctx, input.FromDate, input.ToDate, input.CollectorID, input.Page, input.PerPage)
	if err != nil {
		h.log.Error("Failed to generate collector audit report", err)
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &CollectorAuditReportOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Collector audit report generated successfully"
	resp.Body.Data.AuditSummaries = summaries
	resp.Body.Data.Meta = meta
	return resp, nil
}
