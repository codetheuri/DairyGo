package member

import (
	"context"
	"net/url"

	"github.com/danielgtaylor/huma/v2"

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

func (h *Handler) Create(ctx context.Context, input *CreateMemberInput) (*MemberOutput, error) {
	member, err := h.service.CreateMember(ctx, &input.Body)
	if err != nil {
		h.log.Error("Failed to register member", err)
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &MemberOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Member registered successfully"
	resp.Body.Data.Member = member
	return resp, nil
}

func (h *Handler) GetByID(ctx context.Context, input *MemberIDInput) (*MemberOutput, error) {
	member, err := h.service.GetMemberByID(ctx, input.ID)
	if err != nil {
		return nil, huma.Error404NotFound("Member not found", err)
	}

	resp := &MemberOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Member retrieved successfully"
	resp.Body.Data.Member = member
	return resp, nil
}

func (h *Handler) List(ctx context.Context, input *ListMembersInput) (*ListMembersOutput, error) {
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
	if input.CanSupply {
		q.Filters[filterCanSupply] = "true"
	}

	members, meta, err := h.service.ListMembers(ctx, q)
	if err != nil {
		return nil, huma.Error500InternalServerError("Failed to retrieve members", err)
	}

	resp := &ListMembersOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Members retrieved successfully"
	resp.Body.Data.Members = members
	resp.Body.Data.Meta = meta
	return resp, nil
}

func (h *Handler) Update(ctx context.Context, input *UpdateMemberInput) (*MemberOutput, error) {
	member, err := h.service.UpdateMember(ctx, input.ID, &input.Body)
	if err != nil {
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &MemberOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Member details updated successfully"
	resp.Body.Data.Member = member
	return resp, nil
}

func (h *Handler) UpdateStatus(ctx context.Context, input *UpdateMemberStatusInput) (*MemberOutput, error) {
	reason := ""
	if input.Body.Reason != nil {
		reason = *input.Body.Reason
	}
	member, err := h.service.UpdateStatus(ctx, input.ID, input.Body.Status, reason)
	if err != nil {
		if err.Error() == "member not found" {
			return nil, huma.Error404NotFound(err.Error())
		}
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &MemberOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Member status updated successfully"
	resp.Body.Data.Member = member
	return resp, nil
}

// History returns who changed a farmer's details and when.
func (h *Handler) History(ctx context.Context, input *MemberIDInput) (*MemberHistoryOutput, error) {
	history, err := h.service.History(ctx, input.ID)
	if err != nil {
		return nil, huma.Error404NotFound(err.Error())
	}
	resp := &MemberHistoryOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Farmer history"
	resp.Body.Data.History = history
	return resp, nil
}
