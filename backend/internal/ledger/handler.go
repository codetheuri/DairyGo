package ledger

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/danielgtaylor/huma/v2"

	"github.com/codetheuri/tusk/pkg/logger"
)

// Handler exposes the books over HTTP.
type Handler struct {
	service *Service
	log     logger.Logger
}

// NewHandler creates a books handler.
func NewHandler(service *Service, log logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

func (h *Handler) status(st *BooksStatus, made int, err error, msg string) (*BooksStatusOutput, error) {
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &BooksStatusOutput{}
	out.Body.Success, out.Body.Message = true, msg
	out.Body.Data.Books, out.Body.Data.Made = st, made
	return out, nil
}

func (h *Handler) Status(ctx context.Context, _ *struct{}) (*BooksStatusOutput, error) {
	st, err := h.service.Status(ctx)
	return h.status(st, 0, err, "Books")
}

func (h *Handler) Start(ctx context.Context, in *BooksStartInput) (*BooksStatusOutput, error) {
	st, made, err := h.service.Start(ctx, &in.Body)
	return h.status(st, made, err, "The books start on "+in.Body.StartDate)
}

func (h *Handler) BringUpToDate(ctx context.Context, _ *struct{}) (*BooksStatusOutput, error) {
	st, made, err := h.service.BringUpToDate(ctx)
	msg := "The books were already up to date"
	if made > 0 {
		msg = fmt.Sprintf("%s posted to bring the books up to date", plural(made, "journal"))
	}
	return h.status(st, made, err, msg)
}

func (h *Handler) Accounts(ctx context.Context, _ *struct{}) (*LedgerAccountsOutput, error) {
	list, err := h.service.Accounts(ctx)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &LedgerAccountsOutput{}
	out.Body.Success, out.Body.Message = true, "Chart of accounts"
	out.Body.Data.Accounts = list
	return out, nil
}

func (h *Handler) saveAccount(ctx context.Context, id string, req *AccountRequest, msg string) (*LedgerAccountOutput, error) {
	a, err := h.service.SaveAccount(ctx, id, req)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &LedgerAccountOutput{}
	out.Body.Success, out.Body.Message = true, msg
	out.Body.Data.Account = a
	return out, nil
}

func (h *Handler) CreateAccount(ctx context.Context, in *LedgerCreateAccountInput) (*LedgerAccountOutput, error) {
	return h.saveAccount(ctx, "", &in.Body, "Account added")
}

func (h *Handler) UpdateAccount(ctx context.Context, in *LedgerUpdateAccountInput) (*LedgerAccountOutput, error) {
	return h.saveAccount(ctx, in.ID, &in.Body, "Account saved")
}

func (h *Handler) links(list []LinkRow, err error, msg string) (*BooksLinksOutput, error) {
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &BooksLinksOutput{}
	out.Body.Success, out.Body.Message = true, msg
	out.Body.Data.Links = list
	return out, nil
}

func (h *Handler) Links(ctx context.Context, _ *struct{}) (*BooksLinksOutput, error) {
	list, err := h.service.Links(ctx)
	return h.links(list, err, "Where records post")
}

func (h *Handler) SetLink(ctx context.Context, in *BooksSetLinkInput) (*BooksLinksOutput, error) {
	list, err := h.service.SetLink(ctx, &in.Body)
	return h.links(list, err, "Saved: records post there from now on")
}

func (h *Handler) Journals(ctx context.Context, in *JournalsInput) (*JournalsOutput, error) {
	list, err := h.service.Journals(ctx, JournalFilter{From: in.From, To: in.To, Kind: in.Kind, AccountID: in.AccountID,
		Search: in.Search, Page: in.Page, Limit: in.Limit})
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &JournalsOutput{}
	out.Body.Success, out.Body.Message = true, "Journals"
	out.Body.Data.JournalList = *list
	return out, nil
}

func (h *Handler) journal(j *Journal, err error, msg string) (*JournalOutput, error) {
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &JournalOutput{}
	out.Body.Success, out.Body.Message = true, msg
	out.Body.Data.Journal = j
	return out, nil
}

func (h *Handler) Journal(ctx context.Context, in *JournalIDInput) (*JournalOutput, error) {
	j, err := h.service.Journal(ctx, in.ID)
	return h.journal(j, err, "Journal")
}

func (h *Handler) CreateJournal(ctx context.Context, in *JournalCreateInput) (*JournalOutput, error) {
	j, err := h.service.CreateJournal(ctx, &in.Body)
	if err == nil {
		return h.journal(j, nil, fmt.Sprintf("Journal J-%d saved", j.Number))
	}
	return h.journal(nil, err, "")
}

func (h *Handler) ReverseJournal(ctx context.Context, in *JournalReverseInput) (*JournalOutput, error) {
	j, err := h.service.ReverseJournal(ctx, in.ID, &in.Body)
	if err == nil {
		return h.journal(j, nil, fmt.Sprintf("Reversed by J-%d", j.Number))
	}
	return h.journal(nil, err, "")
}

func (h *Handler) TrialBalance(ctx context.Context, in *TrialBalanceInput) (*TrialBalanceOutput, error) {
	tb, err := h.service.TrialBalance(ctx, in.Date)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &TrialBalanceOutput{}
	out.Body.Success, out.Body.Message = true, "Trial balance"
	out.Body.Data.TrialBalance = tb
	return out, nil
}

func (h *Handler) AccountLedger(ctx context.Context, in *AccountLedgerInput) (*AccountLedgerOutput, error) {
	l, err := h.service.AccountLedger(ctx, in.ID, in.From, in.To)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &AccountLedgerOutput{}
	out.Body.Success, out.Body.Message = true, "Account ledger"
	out.Body.Data.Ledger = l
	return out, nil
}

func (h *Handler) IncomeStatement(ctx context.Context, in *IncomeStatementInput) (*IncomeStatementOutput, error) {
	st, err := h.service.IncomeStatement(ctx, in.From, in.To)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &IncomeStatementOutput{}
	out.Body.Success, out.Body.Message = true, "Income statement"
	out.Body.Data.Statement = st
	return out, nil
}

func (h *Handler) BalanceSheet(ctx context.Context, in *BalanceSheetInput) (*BalanceSheetOutput, error) {
	bs, err := h.service.BalanceSheet(ctx, in.Date, in.Previous)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &BalanceSheetOutput{}
	out.Body.Success, out.Body.Message = true, "Balance sheet"
	out.Body.Data.Sheet = bs
	return out, nil
}

// toHTTPError maps domain errors to status codes with plain sentences.
func (h *Handler) toHTTPError(err error) error {
	switch {
	case errors.Is(err, ErrNotFound):
		return huma.Error404NotFound(sentence(err))
	case errors.Is(err, ErrConflict), errors.Is(err, ErrNotStarted):
		return huma.Error409Conflict(sentence(err))
	case errors.Is(err, ErrInvalid):
		return huma.Error400BadRequest(sentence(err))
	default:
		h.log.Error("Books request failed", err)
		return huma.Error500InternalServerError("Something went wrong. Please try again.")
	}
}

func sentence(err error) string {
	msg := err.Error()
	for _, p := range []string{"not found: ", "conflict: ", "invalid: ", "not started: "} {
		msg = strings.TrimPrefix(msg, p)
	}
	if msg == "" {
		return msg
	}
	return strings.ToUpper(msg[:1]) + msg[1:]
}
