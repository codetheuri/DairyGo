package collection

import (
	"context"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
	"github.com/codetheuri/tusk/pkg/query"
)

// transferSnapshot is the audited view of a transfer's values.
type transferSnapshot struct {
	FromCollectorID uint       `json:"from_collector_id"`
	ToCollectorID   uint       `json:"to_collector_id"`
	TransferDate    string     `json:"transfer_date"`
	QuantityLitres  float64    `json:"quantity_litres"`
	Notes           *string    `json:"notes,omitempty"`
	VoidedAt        *time.Time `json:"voided_at,omitempty"`
}

func transferSnapshotOf(t *MilkTransfer) transferSnapshot {
	return transferSnapshot{
		FromCollectorID: t.FromCollectorID, ToCollectorID: t.ToCollectorID,
		TransferDate: t.TransferDate.Format(dateLayout), QuantityLitres: t.QuantityLitres,
		Notes: t.Notes, VoidedAt: t.VoidedAt,
	}
}

// transferLitres validates and rounds a transferred quantity.
func transferLitres(q float64) (float64, error) {
	if q <= 0 {
		return 0, fmt.Errorf("quantity in litres must be greater than zero")
	}
	return math.Round(q*100) / 100, nil
}

// transferDay parses a transfer date (default today), which may not be in
// the future: milk cannot be handed over before it happens.
func transferDay(date *string, now time.Time) (time.Time, error) {
	today := now.Format(dateLayout)
	if date == nil || strings.TrimSpace(*date) == "" {
		d, _ := time.Parse(dateLayout, today)
		return d, nil
	}
	d, err := time.Parse(dateLayout, strings.TrimSpace(*date))
	if err != nil {
		return time.Time{}, fmt.Errorf("invalid transfer_date format, expected YYYY-MM-DD")
	}
	if d.Format(dateLayout) > today {
		return time.Time{}, fmt.Errorf("transfer_date cannot be in the future")
	}
	return d, nil
}

// TransferRecipients lists the colleagues the caller can transfer milk to.
func (s *Service) TransferRecipients(ctx context.Context) ([]TransferRecipient, error) {
	return s.repo.ListTransferRecipients(ctx, middleware.GetUserID(ctx))
}

// RecordTransfer records milk handed to another collector. It counts at once
// for both. Collectors transfer their own milk; admins
// (milk.transfers.manage) may record a transfer for any collector.
func (s *Service) RecordTransfer(ctx context.Context, req *RecordTransferRequest) (*MilkTransfer, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, fmt.Errorf("sacco context is required to record a transfer")
	}
	a, err := s.actorFrom(ctx, PermMilkTransfersManage)
	if err != nil {
		return nil, err
	}

	from := a.userID
	if req.FromCollectorID != nil && *req.FromCollectorID != a.userID {
		if !a.canManage {
			return nil, fmt.Errorf("%w: you can only transfer your own milk", ErrForbidden)
		}
		sender, err := s.repo.FindTransferRecipient(ctx, *req.FromCollectorID)
		if err != nil {
			return nil, err
		}
		from = sender.ID
	}
	if req.ToCollectorID == from {
		return nil, fmt.Errorf("choose another collector: milk cannot be transferred to the same collector")
	}
	if _, err := s.repo.FindTransferRecipient(ctx, req.ToCollectorID); err != nil {
		return nil, err
	}
	litres, err := transferLitres(req.QuantityLitres)
	if err != nil {
		return nil, err
	}
	day, err := transferDay(req.TransferDate, time.Now())
	if err != nil {
		return nil, err
	}

	t := &MilkTransfer{
		ID:              uuid.New().String(),
		SaccoID:         saccoID,
		FromCollectorID: from,
		ToCollectorID:   req.ToCollectorID,
		TransferDate:    day,
		QuantityLitres:  litres,
		Notes:           trimmedOrNil(req.Notes),
		RecordedByID:    a.userID,
	}
	entry := audit.Entry{
		SaccoID: saccoID, EntityType: auditEntityTransfer, EntityID: t.ID,
		Action: audit.ActionCreate, ActorID: a.userID, NewValues: transferSnapshotOf(t),
	}
	if err := s.repo.CreateTransfer(ctx, t, entry); err != nil {
		return nil, fmt.Errorf("failed to record the transfer: %w", err)
	}
	return s.repo.FindTransferByID(ctx, t.ID)
}

// UpdateTransfer corrects the receiver, litres or notes of a transfer, within
// canChangeTransfer's rules. Admins must give a reason.
func (s *Service) UpdateTransfer(ctx context.Context, id string, req *UpdateTransferRequest) (*MilkTransfer, error) {
	a, err := s.actorFrom(ctx, PermMilkTransfersManage)
	if err != nil {
		return nil, err
	}
	t, err := s.repo.FindTransferByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if err := canChangeTransfer(a, t, time.Now().Format(dateLayout)); err != nil {
		return nil, err
	}
	reason := trimmedOrNil(req.Reason)
	if a.canManage && t.FromCollectorID != a.userID && reason == nil {
		return nil, fmt.Errorf("a reason is required when an admin changes another collector's transfer")
	}

	before := transferSnapshotOf(t)
	if req.ToCollectorID != nil && *req.ToCollectorID != t.ToCollectorID {
		if *req.ToCollectorID == t.FromCollectorID {
			return nil, fmt.Errorf("choose another collector: milk cannot be transferred to the same collector")
		}
		if _, err := s.repo.FindTransferRecipient(ctx, *req.ToCollectorID); err != nil {
			return nil, err
		}
		t.ToCollectorID = *req.ToCollectorID
	}
	if req.QuantityLitres != nil {
		if t.QuantityLitres, err = transferLitres(*req.QuantityLitres); err != nil {
			return nil, err
		}
	}
	if req.Notes != nil {
		t.Notes = trimmedOrNil(req.Notes)
	}

	entry := audit.Entry{
		SaccoID: t.SaccoID, EntityType: auditEntityTransfer, EntityID: t.ID,
		Action: audit.ActionUpdate, ActorID: a.userID, Reason: reason,
		OldValues: before, NewValues: transferSnapshotOf(t),
	}
	if err := s.repo.UpdateTransfer(ctx, t, entry); err != nil {
		return nil, fmt.Errorf("failed to update the transfer: %w", err)
	}
	return s.repo.FindTransferByID(ctx, t.ID)
}

// CancelTransfer cancels a transfer recorded in error, within
// canChangeTransfer's rules. It stays on record for the history but no
// longer counts for either collector.
func (s *Service) CancelTransfer(ctx context.Context, id, reason string) (*MilkTransfer, error) {
	reasonPtr := trimmedOrNil(&reason)
	if reasonPtr == nil {
		return nil, fmt.Errorf("a reason is required to cancel a transfer")
	}
	a, err := s.actorFrom(ctx, PermMilkTransfersManage)
	if err != nil {
		return nil, err
	}
	t, err := s.repo.FindTransferByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if err := canChangeTransfer(a, t, time.Now().Format(dateLayout)); err != nil {
		return nil, err
	}

	before := transferSnapshotOf(t)
	now := time.Now()
	t.VoidedAt, t.VoidReason = &now, reasonPtr
	entry := audit.Entry{
		SaccoID: t.SaccoID, EntityType: auditEntityTransfer, EntityID: t.ID,
		Action: audit.ActionVoid, ActorID: a.userID, Reason: reasonPtr,
		OldValues: before, NewValues: transferSnapshotOf(t),
	}
	if err := s.repo.UpdateTransfer(ctx, t, entry); err != nil {
		return nil, fmt.Errorf("failed to cancel the transfer: %w", err)
	}
	return t, nil
}

// visibleTransfer loads a transfer the caller may see: admins and board
// members see all; collectors only those they sent or received.
func (s *Service) visibleTransfer(ctx context.Context, id string) (*MilkTransfer, error) {
	t, err := s.repo.FindTransferByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if !middleware.SeesAllRecords(ctx) {
		me := middleware.GetUserID(ctx)
		if t.FromCollectorID != me && t.ToCollectorID != me {
			return nil, fmt.Errorf("%w: milk transfer not found", ErrNotFound)
		}
	}
	return t, nil
}

// GetTransfer returns one transfer the caller may see.
func (s *Service) GetTransfer(ctx context.Context, id string) (*MilkTransfer, error) {
	return s.visibleTransfer(ctx, id)
}

// TransferHistory returns who recorded and changed a transfer, oldest first.
func (s *Service) TransferHistory(ctx context.Context, id string) ([]audit.Log, error) {
	t, err := s.visibleTransfer(ctx, id)
	if err != nil {
		return nil, err
	}
	return s.repo.TransferHistory(ctx, t)
}

// ListTransfers lists transfers the caller may see.
func (s *Service) ListTransfers(ctx context.Context, q query.Query, f TransferListFilter) ([]MilkTransfer, query.Meta, error) {
	return s.repo.ListTransfers(ctx, q, f)
}
