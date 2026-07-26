package sacco

import (
	"context"
	"net/url"

	"github.com/danielgtaylor/huma/v2"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/logger"
	"github.com/codetheuri/tusk/pkg/query"
)

type Handler struct {
	service *Service
	log     logger.Logger
}

func NewHandler(service *Service, log logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

// Create provisions a new Dairy Sacco tenant and default Admin account (Platform Super User only).
func (h *Handler) Create(ctx context.Context, input *CreateSaccoInput) (*SaccoOutput, error) {
	if !middleware.IsSuperUser(ctx) {
		return nil, huma.Error403Forbidden("Only Platform Super Users can create new Saccos")
	}

	sacco, _, err := h.service.CreateSacco(ctx, &input.Body)
	if err != nil {
		h.log.Error("Failed to create Sacco", err)
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &SaccoOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Sacco provisioned successfully"
	resp.Body.Data.Sacco = sacco
	return resp, nil
}

// GetByID returns detailed information for a specific Sacco.
func (h *Handler) GetByID(ctx context.Context, input *SaccoIDInput) (*SaccoOutput, error) {
	sacco, err := h.service.GetSaccoByID(ctx, input.ID)
	if err != nil {
		return nil, huma.Error404NotFound("Sacco not found", err)
	}

	resp := &SaccoOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Sacco retrieved successfully"
	resp.Body.Data.Sacco = sacco
	return resp, nil
}

// List returns a paginated, filterable list of Saccos (Platform Super User only).
func (h *Handler) List(ctx context.Context, input *ListSaccosInput) (*ListSaccosOutput, error) {
	if !middleware.IsSuperUser(ctx) {
		return nil, huma.Error403Forbidden("Only Platform Super Users can list Saccos")
	}

	q := query.Query{
		Page:    input.Page,
		PerPage: input.PerPage,
		Search:  input.Search,
		Filters: make(map[string]string),
	}

	if input.Sort != "" {
		sortQuery := query.ParseURLValues(url.Values{"sort": []string{input.Sort}})
		q.Sorts = sortQuery.Sorts
	}

	if input.Status != "" {
		q.Filters["status"] = input.Status
	}

	saccos, meta, err := h.service.ListSaccos(ctx, q)
	if err != nil {
		return nil, huma.Error500InternalServerError("Failed to retrieve Saccos", err)
	}

	resp := &ListSaccosOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Saccos retrieved successfully"
	resp.Body.Data.Saccos = saccos
	resp.Body.Data.Meta = meta
	return resp, nil
}

// Update modifies general Sacco details.
func (h *Handler) Update(ctx context.Context, input *UpdateSaccoInput) (*SaccoOutput, error) {
	if !middleware.IsSuperUser(ctx) {
		return nil, huma.Error403Forbidden("Only Platform Super Users can update Saccos")
	}

	sacco, err := h.service.UpdateSacco(ctx, input.ID, &input.Body)
	if err != nil {
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &SaccoOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Sacco updated successfully"
	resp.Body.Data.Sacco = sacco
	return resp, nil
}

// UpdateStatus changes a Sacco operational status (ACTIVE, INACTIVE, SUSPENDED).
func (h *Handler) UpdateStatus(ctx context.Context, input *UpdateSaccoStatusInput) (*SaccoOutput, error) {
	if !middleware.IsSuperUser(ctx) {
		return nil, huma.Error403Forbidden("Only Platform Super Users can change Sacco status")
	}

	if err := h.service.UpdateStatus(ctx, input.ID, input.Body.Status); err != nil {
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	sacco, err := h.service.GetSaccoByID(ctx, input.ID)
	if err != nil {
		return nil, huma.Error500InternalServerError("Failed to reload Sacco", err)
	}

	resp := &SaccoOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Sacco status updated successfully"
	resp.Body.Data.Sacco = sacco
	return resp, nil
}

// GetCurrentSacco returns the Sacco profile for the authenticated tenant user.
func (h *Handler) GetCurrentSacco(ctx context.Context, input *GetCurrentSaccoInput) (*SaccoOutput, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, huma.Error400BadRequest("No Sacco associated with the current user context")
	}

	sacco, err := h.service.GetSaccoByID(ctx, saccoID)
	if err != nil {
		return nil, huma.Error404NotFound("Sacco profile not found", err)
	}

	resp := &SaccoOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Sacco profile retrieved successfully"
	resp.Body.Data.Sacco = sacco
	return resp, nil
}

// GetSettings retrieves the operational settings for the tenant Sacco.
func (h *Handler) GetSettings(ctx context.Context, input *GetCurrentSaccoInput) (*SettingsOutput, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, huma.Error400BadRequest("No Sacco associated with the current user context")
	}

	settings, err := h.service.GetSettings(ctx, saccoID)
	if err != nil {
		return nil, huma.Error404NotFound("Sacco settings not found", err)
	}

	resp := &SettingsOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Sacco settings retrieved successfully"
	resp.Body.Data.Settings = settings
	return resp, nil
}

// UpdateSettings modifies the operational parameters for the tenant Sacco.
func (h *Handler) UpdateSettings(ctx context.Context, input *UpdateSettingsInput) (*SettingsOutput, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, huma.Error400BadRequest("No Sacco associated with the current user context")
	}

	settings, err := h.service.UpdateSettings(ctx, saccoID, &input.Body)
	if err != nil {
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &SettingsOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Sacco settings updated successfully"
	resp.Body.Data.Settings = settings
	return resp, nil
}
