package payout

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/danielgtaylor/huma/v2"

	"github.com/codetheuri/tusk/pkg/logger"
)

// Handler exposes the payout service over HTTP.
type Handler struct {
	service *Service
	log     logger.Logger
}

// NewHandler creates a payout handler.
func NewHandler(service *Service, log logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

// --- deduction types ---

func (h *Handler) ListTypes(ctx context.Context, _ *struct{}) (*DeductionTypesOutput, error) {
	types, err := h.service.ListTypes(ctx)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	if types == nil {
		types = []DeductionType{}
	}
	out := &DeductionTypesOutput{}
	out.Body.Success, out.Body.Message = true, "Deductions"
	out.Body.Data.Deductions = types
	return out, nil
}

func (h *Handler) CreateType(ctx context.Context, in *CreateDeductionTypeInput) (*DeductionTypeOutput, error) {
	return h.saveType(ctx, "", &in.Body, "Deduction added")
}

func (h *Handler) UpdateType(ctx context.Context, in *UpdateDeductionTypeInput) (*DeductionTypeOutput, error) {
	return h.saveType(ctx, in.ID, &in.Body, "Deduction saved")
}

func (h *Handler) saveType(ctx context.Context, id string, req *DeductionTypeRequest, msg string) (*DeductionTypeOutput, error) {
	t, err := h.service.SaveType(ctx, id, req)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &DeductionTypeOutput{}
	out.Body.Success, out.Body.Message = true, msg
	out.Body.Data.Deduction = t
	return out, nil
}

func (h *Handler) DeleteType(ctx context.Context, in *DeductionTypeIDInput) (*MessageOutput, error) {
	if err := h.service.DeleteType(ctx, in.ID); err != nil {
		return nil, h.toHTTPError(err)
	}
	return done("Deduction deleted"), nil
}

// --- a farmer's deductions and account ---

func (h *Handler) FarmerDeductions(ctx context.Context, in *MemberIDInput) (*FarmerDeductionsOutput, error) {
	list, err := h.service.FarmerDeductions(ctx, in.MemberID)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &FarmerDeductionsOutput{}
	out.Body.Success, out.Body.Message = true, "Farmer's deductions"
	out.Body.Data.Deductions = list
	return out, nil
}

func (h *Handler) SetFarmerDeduction(ctx context.Context, in *SetFarmerDeductionInput) (*FarmerDeductionOutput, error) {
	md, err := h.service.SetFarmerDeduction(ctx, in.MemberID, in.TypeID, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &FarmerDeductionOutput{}
	out.Body.Success, out.Body.Message = true, "Saved"
	out.Body.Data.Setting = md
	return out, nil
}

func (h *Handler) Account(ctx context.Context, in *AccountInput) (*AccountOutput, error) {
	acc, err := h.service.Account(ctx, in.MemberID, in.From, in.To)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &AccountOutput{}
	out.Body.Success, out.Body.Message = true, "Farmer's account"
	out.Body.Data.Account = acc
	return out, nil
}

func (h *Handler) AdvanceInfo(ctx context.Context, in *MemberIDInput) (*AdvanceInfoOutput, error) {
	info, err := h.service.AdvanceInfo(ctx, in.MemberID)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &AdvanceInfoOutput{}
	out.Body.Success, out.Body.Message = true, "Advance"
	out.Body.Data.Info = info
	return out, nil
}

func (h *Handler) recordEntry(ctx context.Context, in *RecordEntryInput, kind Kind, msg string) (*EntryOutput, error) {
	t, err := h.service.RecordEntry(ctx, in.MemberID, kind, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &EntryOutput{}
	out.Body.Success, out.Body.Message = true, msg
	out.Body.Data.Entry = t
	return out, nil
}

func (h *Handler) RecordAdvance(ctx context.Context, in *RecordEntryInput) (*EntryOutput, error) {
	return h.recordEntry(ctx, in, KindAdvance, "Advance recorded")
}

func (h *Handler) RecordCharge(ctx context.Context, in *RecordEntryInput) (*EntryOutput, error) {
	return h.recordEntry(ctx, in, KindCharge, "Charge recorded")
}

func (h *Handler) RecordAdjustment(ctx context.Context, in *RecordEntryInput) (*EntryOutput, error) {
	return h.recordEntry(ctx, in, KindAdjustment, "Adjustment recorded")
}

func (h *Handler) VoidEntry(ctx context.Context, in *VoidEntryInput) (*EntryOutput, error) {
	t, err := h.service.VoidEntry(ctx, in.ID, in.Body.Reason)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &EntryOutput{}
	out.Body.Success, out.Body.Message = true, "Entry voided"
	out.Body.Data.Entry = t
	return out, nil
}

func (h *Handler) listEntries(ctx context.Context, in *ListEntriesInput, kind Kind) (*EntriesOutput, error) {
	rows, err := h.service.ListEntries(ctx, kind, in.From, in.To, in.OpenOnly)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &EntriesOutput{}
	out.Body.Success, out.Body.Message = true, "Entries"
	out.Body.Data.Entries = rows
	total := 0.0
	for _, r := range rows {
		if r.VoidedAt == nil {
			total -= r.Amount
		}
	}
	if kind == KindAdjustment {
		total = -total
	}
	out.Body.Data.Total = round2(total)
	return out, nil
}

func (h *Handler) ListAdvances(ctx context.Context, in *ListEntriesInput) (*EntriesOutput, error) {
	return h.listEntries(ctx, in, KindAdvance)
}

func (h *Handler) ListCharges(ctx context.Context, in *ListEntriesInput) (*EntriesOutput, error) {
	return h.listEntries(ctx, in, KindCharge)
}

// --- pay runs ---

func (h *Handler) ListRuns(ctx context.Context, _ *struct{}) (*RunsOutput, error) {
	runs, err := h.service.ListRuns(ctx)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	from, to, err := h.service.DefaultPeriod(ctx)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &RunsOutput{}
	out.Body.Success, out.Body.Message = true, "Pay runs"
	out.Body.Data.Runs = runs
	out.Body.Data.Next = PeriodData{FromDate: from.Format(dateLayout), ToDate: to.Format(dateLayout)}
	return out, nil
}

func runOutput(d *RunDetail, msg string) *RunOutput {
	out := &RunOutput{}
	out.Body.Success, out.Body.Message = true, msg
	out.Body.Data = *d
	return out
}

func (h *Handler) CreateRun(ctx context.Context, in *CreateRunInput) (*RunOutput, error) {
	d, err := h.service.CreateRun(ctx, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return runOutput(d, "Pay run worked out"), nil
}

func (h *Handler) GetRun(ctx context.Context, in *GetRunInput) (*RunOutput, error) {
	d, err := h.service.GetRun(ctx, in.ID, in.Search, in.UnpaidOnly)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return runOutput(d, "Pay run"), nil
}

func (h *Handler) RecomputeRun(ctx context.Context, in *RunIDInput) (*RunOutput, error) {
	d, err := h.service.RecomputeRun(ctx, in.ID)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return runOutput(d, "Pay run worked out again"), nil
}

func (h *Handler) ApproveRun(ctx context.Context, in *ApproveRunInput) (*RunOutput, error) {
	d, err := h.service.ApproveRun(ctx, in.ID, in.Body.ExpectedNet)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return runOutput(d, "Pay run approved"), nil
}

func (h *Handler) CancelRun(ctx context.Context, in *CancelRunInput) (*MessageOutput, error) {
	if err := h.service.CancelRun(ctx, in.ID, in.Body.Reason); err != nil {
		return nil, h.toHTTPError(err)
	}
	return done("Pay run cancelled"), nil
}

func (h *Handler) Pay(ctx context.Context, in *PayInput) (*RunOutput, error) {
	d, err := h.service.PayLines(ctx, in.ID, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return runOutput(d, "Marked paid"), nil
}

func fileOutput(f *File) *FileOutput {
	return &FileOutput{
		ContentType:        f.ContentType,
		ContentDisposition: fmt.Sprintf(`attachment; filename="%s"`, f.Name),
		// Pay details are personal: never kept by caches.
		CacheControl: "no-store",
		Body:         f.Data,
	}
}

func (h *Handler) PaymentFile(ctx context.Context, in *PaymentFileInput) (*FileOutput, error) {
	f, err := h.service.PaymentFile(ctx, in.ID, strings.ToLower(in.Kind))
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return fileOutput(f), nil
}

func (h *Handler) Register(ctx context.Context, in *RegisterInput) (*FileOutput, error) {
	f, err := h.service.Register(ctx, in.ID, strings.ToLower(in.Format))
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return fileOutput(f), nil
}

func (h *Handler) Payslip(ctx context.Context, in *PayslipInput) (*FileOutput, error) {
	f, err := h.service.Payslip(ctx, in.ID, in.MemberID)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return fileOutput(f), nil
}

func done(msg string) *MessageOutput {
	out := &MessageOutput{}
	out.Body.Success, out.Body.Message = true, msg
	return out
}

// toHTTPError maps domain errors to status codes, with the message as a
// plain sentence ("locked: …" prefixes removed).
func (h *Handler) toHTTPError(err error) error {
	switch {
	case errors.Is(err, ErrNotFound):
		return huma.Error404NotFound(sentence(err))
	case errors.Is(err, ErrConflict), errors.Is(err, ErrLocked):
		return huma.Error409Conflict(sentence(err))
	case errors.Is(err, ErrInvalid):
		return huma.Error400BadRequest(sentence(err))
	default:
		h.log.Error("Payout request failed", err)
		return huma.Error500InternalServerError("Something went wrong. Please try again.")
	}
}

func sentence(err error) string {
	msg := err.Error()
	for _, p := range []string{"not found: ", "conflict: ", "locked: ", "invalid: "} {
		msg = strings.TrimPrefix(msg, p)
	}
	if msg == "" {
		return msg
	}
	return strings.ToUpper(msg[:1]) + msg[1:]
}
