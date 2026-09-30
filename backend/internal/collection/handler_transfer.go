package collection

import (
	"context"

	"github.com/codetheuri/tusk/pkg/query"
)

// --- TRANSFER HANDLERS ---

func transferOutput(t *MilkTransfer, msg string) *TransferOutput {
	resp := &TransferOutput{}
	resp.Body.Success = true
	resp.Body.Message = msg
	resp.Body.Data.Transfer = t
	return resp
}

// RecordTransfer records milk handed to another collector.
func (h *Handler) RecordTransfer(ctx context.Context, input *RecordTransferInput) (*TransferOutput, error) {
	t, err := h.service.RecordTransfer(ctx, &input.Body)
	if err != nil {
		return nil, toHTTPError(err)
	}
	return transferOutput(t, "Milk transfer recorded"), nil
}

// ListTransfers lists transfers the caller may see.
func (h *Handler) ListTransfers(ctx context.Context, input *ListTransfersInput) (*ListTransfersOutput, error) {
	q := query.Query{Page: input.Page, PerPage: input.PerPage}
	f := TransferListFilter{
		CollectorID:   input.CollectorID,
		Direction:     input.Direction,
		FromDate:      input.FromDate,
		ToDate:        input.ToDate,
		IncludeVoided: input.IncludeVoided,
	}
	transfers, meta, err := h.service.ListTransfers(ctx, q, f)
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &ListTransfersOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Milk transfers retrieved"
	resp.Body.Data.Transfers = transfers
	resp.Body.Data.Meta = meta
	return resp, nil
}

// GetTransfer returns one transfer.
func (h *Handler) GetTransfer(ctx context.Context, input *TransferIDInput) (*TransferOutput, error) {
	t, err := h.service.GetTransfer(ctx, input.ID)
	if err != nil {
		return nil, toHTTPError(err)
	}
	return transferOutput(t, "Milk transfer retrieved"), nil
}

// UpdateTransfer corrects a transfer.
func (h *Handler) UpdateTransfer(ctx context.Context, input *UpdateTransferInput) (*TransferOutput, error) {
	t, err := h.service.UpdateTransfer(ctx, input.ID, &input.Body)
	if err != nil {
		return nil, toHTTPError(err)
	}
	return transferOutput(t, "Milk transfer updated"), nil
}

// CancelTransfer cancels a transfer recorded in error.
func (h *Handler) CancelTransfer(ctx context.Context, input *CancelTransferInput) (*TransferOutput, error) {
	t, err := h.service.CancelTransfer(ctx, input.ID, input.Body.Reason)
	if err != nil {
		return nil, toHTTPError(err)
	}
	return transferOutput(t, "Milk transfer cancelled"), nil
}

// GetTransferHistory returns who recorded and changed a transfer.
func (h *Handler) GetTransferHistory(ctx context.Context, input *TransferIDInput) (*CollectionHistoryOutput, error) {
	history, err := h.service.TransferHistory(ctx, input.ID)
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &CollectionHistoryOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Transfer history retrieved"
	resp.Body.Data.History = history
	return resp, nil
}

// TransferRecipients lists the collectors milk can be transferred to.
func (h *Handler) TransferRecipients(ctx context.Context, _ *TransferRecipientsInput) (*TransferRecipientsOutput, error) {
	collectors, err := h.service.TransferRecipients(ctx)
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &TransferRecipientsOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Collectors retrieved"
	resp.Body.Data.Collectors = collectors
	return resp, nil
}
