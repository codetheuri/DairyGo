package superadmin

import (
	"context"
	"errors"

	"github.com/danielgtaylor/huma/v2"

	"github.com/codetheuri/tusk/internal/member"
	"github.com/codetheuri/tusk/pkg/query"
)

// Handler exposes the platform console over HTTP.
type Handler struct {
	service *Service
}

// NewHandler creates a platform console handler.
func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) Overview(ctx context.Context, _ *OverviewInput) (*OverviewOutput, error) {
	o, err := h.service.Overview(ctx)
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &OverviewOutput{}
	resp.Body.Success, resp.Body.Message, resp.Body.Data = true, "Platform overview", o
	return resp, nil
}

func (h *Handler) Staff(ctx context.Context, in *SaccoIDInput) (*StaffOutput, error) {
	users, err := h.service.Staff(ctx, in.ID)
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &StaffOutput{}
	resp.Body.Success, resp.Body.Message, resp.Body.Data.Users = true, "Sacco staff", users
	return resp, nil
}

func (h *Handler) AddStaff(ctx context.Context, in *AddStaffInput) (*UserOutput, error) {
	user, err := h.service.AddStaff(ctx, in.ID, &in.Body)
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &UserOutput{}
	resp.Body.Success, resp.Body.Message, resp.Body.Data.User = true, "Staff account created", user
	return resp, nil
}

func (h *Handler) SetUserStatus(ctx context.Context, in *UserStatusInput) (*MessageOutput, error) {
	if err := h.service.SetUserActive(ctx, in.ID, in.Body.IsActive, in.Body.Reason); err != nil {
		return nil, toHTTPError(err)
	}
	return message("User status updated", map[string]any{"is_active": in.Body.IsActive}), nil
}

func (h *Handler) UnlockUser(ctx context.Context, in *UserIDInput) (*MessageOutput, error) {
	if err := h.service.UnlockUser(ctx, in.ID); err != nil {
		return nil, toHTTPError(err)
	}
	return message("User unlocked", nil), nil
}

func (h *Handler) ResetPassword(ctx context.Context, in *ResetPasswordInput) (*MessageOutput, error) {
	if err := h.service.ResetPassword(ctx, in.ID, in.Body.NewPassword); err != nil {
		return nil, toHTTPError(err)
	}
	return message("Password reset; the user's sessions were ended", nil), nil
}

func (h *Handler) Members(ctx context.Context, in *SaccoMembersInput) (*MembersOutput, error) {
	q := query.Query{Page: in.Page, PerPage: in.PerPage, Search: in.Search, Filters: map[string]string{}}
	if in.Status != "" {
		q.Filters["status"] = in.Status
	}
	members, meta, err := h.service.Members(ctx, in.ID, q)
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &MembersOutput{}
	resp.Body.Success, resp.Body.Message = true, "Sacco farmers"
	resp.Body.Data.Members, resp.Body.Data.Meta = members, meta
	return resp, nil
}

func (h *Handler) AddMember(ctx context.Context, in *AddMemberInput) (*MemberOutput, error) {
	m, err := h.service.AddMember(ctx, in.ID, &in.Body)
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &MemberOutput{}
	resp.Body.Success, resp.Body.Message = true, "Farmer registered"
	resp.Body.Data = map[string]*member.Member{"member": m}
	return resp, nil
}

func (h *Handler) AuditLogs(ctx context.Context, in *LogsInput) (*AuditLogsOutput, error) {
	logs, meta, err := h.service.AuditLogs(ctx, in.filter())
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &AuditLogsOutput{}
	resp.Body.Success, resp.Body.Message = true, "Audit logs"
	resp.Body.Data.Logs, resp.Body.Data.Meta = logs, meta
	return resp, nil
}

func (h *Handler) SystemLogs(ctx context.Context, in *LogsInput) (*SystemLogsOutput, error) {
	logs, meta, err := h.service.SystemLogs(ctx, in.filter())
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &SystemLogsOutput{}
	resp.Body.Success, resp.Body.Message = true, "Failed requests"
	resp.Body.Data.Logs, resp.Body.Data.Meta = logs, meta
	return resp, nil
}

func (h *Handler) SMSLogs(ctx context.Context, in *LogsInput) (*SMSLogsOutput, error) {
	logs, meta, err := h.service.SMSLogs(ctx, in.filter())
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &SMSLogsOutput{}
	resp.Body.Success, resp.Body.Message = true, "SMS logs"
	resp.Body.Data.Logs, resp.Body.Data.Meta = logs, meta
	return resp, nil
}

func message(msg string, data map[string]any) *MessageOutput {
	resp := &MessageOutput{}
	resp.Body.Success, resp.Body.Message, resp.Body.Data = true, msg, data
	return resp
}

// toHTTPError maps domain errors to HTTP status codes; anything else is a
// validation problem with the request.
func toHTTPError(err error) error {
	switch {
	case errors.Is(err, ErrForbidden):
		return huma.Error403Forbidden(err.Error())
	case errors.Is(err, ErrNotFound):
		return huma.Error404NotFound(err.Error())
	default:
		return huma.Error400BadRequest(err.Error(), err)
	}
}
