package auth

import (
	"context"
	"errors"

	"github.com/danielgtaylor/huma/v2"
)

// ChangeStaffRole gives a staff account in the caller's Sacco another role.
func (h *Handler) ChangeStaffRole(ctx context.Context, input *ChangeStaffRoleInput) (*StaffUserOutput, error) {
	user, err := h.service.ChangeStaffRole(ctx, input.UserID, input.Body.RoleID, input.Body.Reason)
	if err != nil {
		return nil, staffHTTPError(err)
	}
	resp := &StaffUserOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Role changed to " + user.RoleName
	resp.Body.Data.User = user
	return resp, nil
}

// RemoveStaff removes a staff account from the caller's Sacco.
func (h *Handler) RemoveStaff(ctx context.Context, input *RemoveStaffInput) (*MessageOutput, error) {
	if err := h.service.RemoveStaff(ctx, input.UserID, &input.Reason); err != nil {
		return nil, staffHTTPError(err)
	}
	resp := &MessageOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Staff account removed"
	return resp, nil
}

// staffHTTPError maps staff management errors to HTTP status codes; anything
// else is a problem with the request.
func staffHTTPError(err error) error {
	switch {
	case errors.Is(err, ErrStaffNotFound):
		return huma.Error404NotFound(err.Error())
	case errors.Is(err, ErrStaffForbidden):
		return huma.Error403Forbidden(err.Error())
	default:
		return huma.Error400BadRequest(err.Error(), err)
	}
}
