package payout

import (
	"context"

	"github.com/codetheuri/tusk/pkg/response"
)

// Out is a response with data.
type Out[T any] struct {
	Body response.Data[T]
}

func ok[T any](msg string, v T) *Out[T] {
	out := &Out[T]{}
	out.Body.Success, out.Body.Message, out.Body.Data = true, msg, v
	return out
}

type ShareInput struct {
	MemberID string `path:"member_id" doc:"Farmer UUID"`
	Body     ShareRequest
}

type ShareVoidInput struct {
	ID   string `path:"id" doc:"Share entry UUID"`
	Body struct {
		Reason string `json:"reason" minLength:"3" doc:"Why it is cancelled"`
	}
}

type SharesData struct {
	Shares *Shares `json:"shares"`
}

type ShareEntriesData struct {
	Entries []ShareEntry `json:"entries"`
}

func (h *Handler) Shares(ctx context.Context, in *MemberIDInput) (*Out[SharesData], error) {
	sh, err := h.service.Shares(ctx, in.MemberID)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Shares", SharesData{sh}), nil
}

func (h *Handler) OpeningShares(ctx context.Context, in *ShareInput) (*Out[ShareEntriesData], error) {
	e, err := h.service.OpeningShares(ctx, in.MemberID, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Opening shares recorded", ShareEntriesData{[]ShareEntry{*e}}), nil
}

func (h *Handler) RefundShares(ctx context.Context, in *ShareInput) (*Out[ShareEntriesData], error) {
	e, err := h.service.RefundShares(ctx, in.MemberID, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Shares refunded", ShareEntriesData{[]ShareEntry{*e}}), nil
}

func (h *Handler) TransferShares(ctx context.Context, in *ShareInput) (*Out[ShareEntriesData], error) {
	list, err := h.service.TransferShares(ctx, in.MemberID, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Shares moved", ShareEntriesData{list}), nil
}

func (h *Handler) VoidShareEntry(ctx context.Context, in *ShareVoidInput) (*Out[ShareEntriesData], error) {
	list, err := h.service.VoidShareEntry(ctx, in.ID, in.Body.Reason)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Voided", ShareEntriesData{list}), nil
}
