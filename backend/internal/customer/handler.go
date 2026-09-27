package customer

import (
	"context"
	"errors"
	"net/url"

	"github.com/danielgtaylor/huma/v2"

	"github.com/codetheuri/tusk/pkg/logger"
	"github.com/codetheuri/tusk/pkg/query"
)

// Handler exposes the customer service over HTTP.
type Handler struct {
	service *Service
	log     logger.Logger
}

// NewHandler creates a customer handler.
func NewHandler(service *Service, log logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

func customerOutput(c *Customer, msg string) *CustomerOutput {
	resp := &CustomerOutput{}
	resp.Body.Success = true
	resp.Body.Message = msg
	resp.Body.Data.Customer = c
	return resp
}

func (h *Handler) Create(ctx context.Context, input *CreateCustomerInput) (*CustomerOutput, error) {
	c, err := h.service.Create(ctx, &input.Body)
	if err != nil {
		return nil, toHTTPError(err)
	}
	return customerOutput(c, "Customer created successfully"), nil
}

func (h *Handler) Get(ctx context.Context, input *CustomerIDInput) (*CustomerOutput, error) {
	c, err := h.service.Get(ctx, input.ID)
	if err != nil {
		return nil, toHTTPError(err)
	}
	return customerOutput(c, "Customer retrieved successfully"), nil
}

func (h *Handler) List(ctx context.Context, input *ListCustomersInput) (*ListCustomersOutput, error) {
	q := query.Query{
		Page:    input.Page,
		PerPage: input.PerPage,
		Search:  input.Search,
		Filters: make(map[string]string),
	}
	if input.Sort != "" {
		q.Sorts = query.ParseURLValues(url.Values{"sort": []string{input.Sort}}).Sorts
	}
	if input.Status != "" {
		q.Filters["status"] = input.Status
	}
	if input.CustomerType != "" {
		q.Filters["customer_type"] = input.CustomerType
	}

	customers, meta, err := h.service.List(ctx, q)
	if err != nil {
		return nil, huma.Error500InternalServerError("Failed to retrieve customers", err)
	}

	resp := &ListCustomersOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Customers retrieved successfully"
	resp.Body.Data.Customers = customers
	resp.Body.Data.Meta = meta
	return resp, nil
}

func (h *Handler) Update(ctx context.Context, input *UpdateCustomerInput) (*CustomerOutput, error) {
	c, err := h.service.Update(ctx, input.ID, &input.Body)
	if err != nil {
		return nil, toHTTPError(err)
	}
	return customerOutput(c, "Customer updated successfully"), nil
}

func (h *Handler) UpdateStatus(ctx context.Context, input *UpdateCustomerStatusInput) (*CustomerOutput, error) {
	c, err := h.service.SetStatus(ctx, input.ID, input.Body.Status)
	if err != nil {
		return nil, toHTTPError(err)
	}
	return customerOutput(c, "Customer status updated successfully"), nil
}

func (h *Handler) History(ctx context.Context, input *CustomerIDInput) (*HistoryOutput, error) {
	history, err := h.service.History(ctx, input.ID)
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &HistoryOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Customer history retrieved"
	resp.Body.Data.History = history
	return resp, nil
}

func (h *Handler) RecordPayment(ctx context.Context, input *RecordPaymentInput) (*PaymentOutput, error) {
	p, err := h.service.RecordPayment(ctx, input.ID, &input.Body)
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &PaymentOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Payment recorded successfully"
	resp.Body.Data.Payment = p
	return resp, nil
}

func (h *Handler) VoidPayment(ctx context.Context, input *VoidPaymentInput) (*PaymentOutput, error) {
	p, err := h.service.VoidPayment(ctx, input.ID, input.Body.Reason)
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &PaymentOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Payment voided"
	resp.Body.Data.Payment = p
	return resp, nil
}

func (h *Handler) Statement(ctx context.Context, input *StatementInput) (*StatementOutput, error) {
	st, err := h.service.Statement(ctx, input.ID, input.FromDate, input.ToDate)
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &StatementOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Customer statement generated"
	resp.Body.Data.Statement = st
	return resp, nil
}

func (h *Handler) Balances(ctx context.Context, input *BalancesInput) (*BalancesOutput, error) {
	balances, total, err := h.service.Balances(ctx, input.OwingOnly)
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &BalancesOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Customer balances retrieved"
	resp.Body.Data.Balances = balances
	resp.Body.Data.TotalOwed = total
	return resp, nil
}

// toHTTPError maps domain errors to HTTP status codes; anything else is a
// validation problem with the request.
func toHTTPError(err error) error {
	switch {
	case errors.Is(err, ErrNotFound):
		return huma.Error404NotFound(err.Error())
	case errors.Is(err, ErrConflict), errors.Is(err, ErrLocked):
		return huma.Error409Conflict(err.Error())
	default:
		return huma.Error400BadRequest(err.Error(), err)
	}
}
