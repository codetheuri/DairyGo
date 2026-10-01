package finance

import (
	"context"
	"errors"
	"strings"

	"github.com/danielgtaylor/huma/v2"

	"github.com/codetheuri/tusk/pkg/logger"
)

// Handler exposes the finance service over HTTP.
type Handler struct {
	service *Service
	log     logger.Logger
}

// NewHandler creates a finance handler.
func NewHandler(service *Service, log logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

func (h *Handler) Accounts(ctx context.Context, _ *struct{}) (*CashAccountsOutput, error) {
	list, total, err := h.service.Accounts(ctx)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &CashAccountsOutput{}
	out.Body.Success, out.Body.Message = true, "Accounts"
	out.Body.Data.Accounts, out.Body.Data.Total = list, total
	return out, nil
}

func (h *Handler) saveAccount(ctx context.Context, id string, req *CashAccountRequest, msg string) (*CashAccountOutput, error) {
	a, err := h.service.SaveAccount(ctx, id, req)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &CashAccountOutput{}
	out.Body.Success, out.Body.Message = true, msg
	out.Body.Data.CashAccount = a
	return out, nil
}

func (h *Handler) CreateAccount(ctx context.Context, in *CashCreateAccountInput) (*CashAccountOutput, error) {
	return h.saveAccount(ctx, "", &in.Body, "CashAccount added")
}

func (h *Handler) UpdateAccount(ctx context.Context, in *CashUpdateAccountInput) (*CashAccountOutput, error) {
	return h.saveAccount(ctx, in.ID, &in.Body, "CashAccount saved")
}

func (h *Handler) Cashbook(ctx context.Context, in *FinCashbookInput) (*FinCashbookOutput, error) {
	cb, err := h.service.Cashbook(ctx, in.ID, in.From, in.To)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &FinCashbookOutput{}
	out.Body.Success, out.Body.Message = true, "Cashbook"
	out.Body.Data.Cashbook = cb
	return out, nil
}

func (h *Handler) Categories(ctx context.Context, _ *struct{}) (*FinCategoriesOutput, error) {
	list, err := h.service.Categories(ctx)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &FinCategoriesOutput{}
	out.Body.Success, out.Body.Message = true, "Expense categories"
	out.Body.Data.Categories = list
	return out, nil
}

func (h *Handler) saveCategory(ctx context.Context, id string, req *FinCategoryRequest, msg string) (*FinCategoryOutput, error) {
	c, err := h.service.SaveCategory(ctx, id, req)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &FinCategoryOutput{}
	out.Body.Success, out.Body.Message = true, msg
	out.Body.Data.ExpenseCategory = c
	return out, nil
}

func (h *Handler) CreateCategory(ctx context.Context, in *FinCreateCategoryInput) (*FinCategoryOutput, error) {
	return h.saveCategory(ctx, "", &in.Body, "ExpenseCategory added")
}

func (h *Handler) UpdateCategory(ctx context.Context, in *FinUpdateCategoryInput) (*FinCategoryOutput, error) {
	return h.saveCategory(ctx, in.ID, &in.Body, "ExpenseCategory saved")
}

func (h *Handler) Expenses(ctx context.Context, in *FinListExpensesInput) (*FinExpensesOutput, error) {
	list, err := h.service.Expenses(ctx, in)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &FinExpensesOutput{}
	out.Body.Success, out.Body.Message = true, "Expenses"
	out.Body.Data = *list
	return out, nil
}

func expenseOutput(e *Expense, msg string) *FinExpenseOutput {
	out := &FinExpenseOutput{}
	out.Body.Success, out.Body.Message = true, msg
	out.Body.Data.Expense = e
	return out
}

func (h *Handler) RecordExpense(ctx context.Context, in *FinRecordExpenseInput) (*FinExpenseOutput, error) {
	e, err := h.service.RecordExpense(ctx, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return expenseOutput(e, "Expense recorded"), nil
}

func (h *Handler) VoidExpense(ctx context.Context, in *FinVoidInput) (*FinExpenseOutput, error) {
	e, err := h.service.VoidExpense(ctx, in.ID, in.Body.Reason)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return expenseOutput(e, "Expense voided"), nil
}

func (h *Handler) Transfers(ctx context.Context, in *FinListTransfersInput) (*FinTransfersOutput, error) {
	list, err := h.service.Transfers(ctx, in.From, in.To)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &FinTransfersOutput{}
	out.Body.Success, out.Body.Message = true, "Transfers"
	out.Body.Data.Transfers = list
	return out, nil
}

func transferOutput(t *AccountTransfer, msg string) *FinTransferOutput {
	out := &FinTransferOutput{}
	out.Body.Success, out.Body.Message = true, msg
	out.Body.Data.AccountTransfer = t
	return out
}

func (h *Handler) RecordTransfer(ctx context.Context, in *FinRecordTransferInput) (*FinTransferOutput, error) {
	t, err := h.service.RecordTransfer(ctx, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return transferOutput(t, "Money moved"), nil
}

func (h *Handler) VoidTransfer(ctx context.Context, in *FinVoidInput) (*FinTransferOutput, error) {
	t, err := h.service.VoidTransfer(ctx, in.ID, in.Body.Reason)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return transferOutput(t, "AccountTransfer voided"), nil
}

func (h *Handler) Summary(ctx context.Context, in *FinSummaryInput) (*FinSummaryOutput, error) {
	sum, err := h.service.Summary(ctx, in.From, in.To)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &FinSummaryOutput{}
	out.Body.Success, out.Body.Message = true, "Income and expenditure"
	out.Body.Data.FinanceSummary = sum
	return out, nil
}

// toHTTPError maps domain errors to status codes with plain sentences.
func (h *Handler) toHTTPError(err error) error {
	switch {
	case errors.Is(err, ErrNotFound):
		return huma.Error404NotFound(sentence(err))
	case errors.Is(err, ErrConflict), errors.Is(err, ErrLocked):
		return huma.Error409Conflict(sentence(err))
	case errors.Is(err, ErrInvalid):
		return huma.Error400BadRequest(sentence(err))
	default:
		h.log.Error("Finance request failed", err)
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
