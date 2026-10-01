package sacco

import (
	"context"
	"errors"

	"github.com/danielgtaylor/huma/v2"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/response"
)

type LogoBody struct {
	Image string `json:"image" doc:"The logo, base64 (a data: URL is fine). PNG or JPEG, at most 512 KB." minLength:"1"`
}

type AdminLogoInput struct {
	ID   string `path:"id" doc:"Sacco UUID"`
	Body LogoBody
}

type OwnLogoInput struct {
	Body LogoBody
}

type LogoSavedOutput struct {
	Body response.Data[map[string]bool]
}

// LogoImageOutput is the logo itself.
type LogoImageOutput struct {
	ContentType  string `header:"Content-Type"`
	CacheControl string `header:"Cache-Control"`
	Body         []byte
}

func saved(has bool) *LogoSavedOutput {
	out := &LogoSavedOutput{}
	out.Body.Success, out.Body.Message = true, "Logo saved"
	if !has {
		out.Body.Message = "Logo removed"
	}
	out.Body.Data = map[string]bool{"has_logo": has}
	return out
}

func logoError(err error) error {
	switch {
	case errors.Is(err, ErrNoLogo):
		return huma.Error404NotFound(err.Error())
	case err.Error() == "sacco not found":
		return huma.Error404NotFound("Sacco not found")
	default:
		return huma.Error400BadRequest(err.Error())
	}
}

// AdminSetLogo stores a Sacco's logo for a platform operator.
func (h *Handler) AdminSetLogo(ctx context.Context, in *AdminLogoInput) (*LogoSavedOutput, error) {
	if !middleware.IsSuperUser(ctx) {
		return nil, huma.Error403Forbidden("Only Platform Super Users can change another Sacco's logo")
	}
	if err := h.service.SetLogo(ctx, in.ID, in.Body.Image); err != nil {
		return nil, logoError(err)
	}
	return saved(true), nil
}

// AdminRemoveLogo removes a Sacco's logo for a platform operator.
func (h *Handler) AdminRemoveLogo(ctx context.Context, in *SaccoIDInput) (*LogoSavedOutput, error) {
	if !middleware.IsSuperUser(ctx) {
		return nil, huma.Error403Forbidden("Only Platform Super Users can change another Sacco's logo")
	}
	if err := h.service.RemoveLogo(ctx, in.ID); err != nil {
		return nil, logoError(err)
	}
	return saved(false), nil
}

// AdminLogo returns a Sacco's logo, for the console.
func (h *Handler) AdminLogo(ctx context.Context, in *SaccoIDInput) (*LogoImageOutput, error) {
	if !middleware.IsSuperUser(ctx) {
		return nil, huma.Error403Forbidden("Only Platform Super Users can view another Sacco's logo")
	}
	return h.logo(ctx, in.ID)
}

// SetOwnLogo stores the caller's Sacco's logo.
func (h *Handler) SetOwnLogo(ctx context.Context, in *OwnLogoInput) (*LogoSavedOutput, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, huma.Error400BadRequest("No Sacco associated with the current user context")
	}
	if err := h.service.SetLogo(ctx, saccoID, in.Body.Image); err != nil {
		return nil, logoError(err)
	}
	return saved(true), nil
}

// OwnLogo returns the caller's Sacco's logo.
func (h *Handler) OwnLogo(ctx context.Context, _ *struct{}) (*LogoImageOutput, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, huma.Error400BadRequest("No Sacco associated with the current user context")
	}
	return h.logo(ctx, saccoID)
}

func (h *Handler) logo(ctx context.Context, saccoID string) (*LogoImageOutput, error) {
	data, kind, err := h.service.Logo(ctx, saccoID)
	if err != nil {
		return nil, logoError(err)
	}
	return &LogoImageOutput{ContentType: kind, CacheControl: "private, max-age=300", Body: data}, nil
}
