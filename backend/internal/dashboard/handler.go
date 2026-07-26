package dashboard

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

func (h *Handler) GetExecutiveDashboard(ctx context.Context, input *ExecutiveDashboardInput) (*ExecutiveDashboardOutput, error) {
	data, err := h.service.GetExecutiveDashboard(ctx, input.Days)
	if err != nil {
		h.log.Error("Failed to generate executive dashboard", err)
		return nil, huma.Error500InternalServerError("Failed to generate executive dashboard", err)
	}

	resp := &ExecutiveDashboardOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Executive dashboard metrics retrieved successfully"
	resp.Body.Data = *data
	return resp, nil
}

func (h *Handler) GetCollectorDashboard(ctx context.Context, input *CollectorDashboardInput) (*CollectorDashboardOutput, error) {
	data, err := h.service.GetCollectorDashboard(ctx, input.Date)
	if err != nil {
		h.log.Error("Failed to generate collector mobile dashboard", err)
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &CollectorDashboardOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Collector mobile shift metrics retrieved successfully"
	resp.Body.Data = *data
	return resp, nil
}
