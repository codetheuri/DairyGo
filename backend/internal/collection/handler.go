package collection

import (
	"context"
	"errors"
	"strconv"
	"strings"

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

// --- PRICING HANDLERS ---

func (h *Handler) SetPrice(ctx context.Context, input *SetPriceInput) (*PriceOutput, error) {
	price, err := h.service.SetPrice(ctx, &input.Body)
	if err != nil {
		h.log.Error("Failed to set milk price", err)
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &PriceOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Milk price configured successfully"
	resp.Body.Data.Price = price
	return resp, nil
}

func (h *Handler) GetActivePrice(ctx context.Context, input *GetActivePriceInput) (*PriceOutput, error) {
	price, err := h.service.GetActivePrice(ctx)
	if err != nil {
		return nil, huma.Error404NotFound(err.Error(), err)
	}

	resp := &PriceOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Active milk price retrieved successfully"
	resp.Body.Data.Price = price
	return resp, nil
}

func (h *Handler) ListPrices(ctx context.Context, input *ListPricesInput) (*ListPricesOutput, error) {
	q := query.Query{
		Page:    input.Page,
		PerPage: input.PerPage,
	}

	prices, meta, err := h.service.ListPrices(ctx, q)
	if err != nil {
		return nil, huma.Error500InternalServerError("Failed to retrieve milk prices", err)
	}

	resp := &ListPricesOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Milk price history retrieved successfully"
	resp.Body.Data.Prices = prices
	resp.Body.Data.Meta = meta
	return resp, nil
}

// idFilter formats a numeric ID for a query filter. (string(rune(id)) would
// give the character with that code, not its digits.)
func idFilter(id uint) string {
	return strconv.FormatUint(uint64(id), 10)
}

// collectionFilters turns the list request's query parameters into filters.
func collectionFilters(input *ListCollectionsInput) map[string]string {
	f := make(map[string]string)
	if input.MemberID != "" {
		f["member_id"] = input.MemberID
	}
	if input.CollectorID > 0 {
		f["collector_id"] = idFilter(input.CollectorID)
	}
	if input.Shift != "" {
		f["shift"] = input.Shift
	}
	if input.Status != "" {
		f["status"] = input.Status
	}
	if input.FromDate != "" {
		f["collection_date_from"] = input.FromDate
	}
	if input.ToDate != "" {
		f["collection_date_to"] = input.ToDate
	}
	return f
}

// spoilageFilters turns the list request's query parameters into filters.
func spoilageFilters(input *ListSpoilageInput) map[string]string {
	f := make(map[string]string)
	if input.CollectorID > 0 {
		f["collector_id"] = idFilter(input.CollectorID)
	}
	if input.FromDate != "" {
		f["spoilage_date_from"] = input.FromDate
	}
	if input.ToDate != "" {
		f["spoilage_date_to"] = input.ToDate
	}
	return f
}

// --- COLLECTION HANDLERS ---

func (h *Handler) RecordCollection(ctx context.Context, input *RecordCollectionInput) (*CollectionOutput, error) {
	col, err := h.service.RecordCollection(ctx, &input.Body)
	if err != nil {
		h.log.Error("Failed to record milk collection", err)
		return nil, toHTTPError(err)
	}

	resp := &CollectionOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Milk collection recorded successfully"
	resp.Body.Data.Collection = col
	return resp, nil
}

func (h *Handler) GetCollectionByID(ctx context.Context, input *CollectionIDInput) (*CollectionOutput, error) {
	col, err := h.service.GetCollectionByID(ctx, input.ID)
	if err != nil {
		return nil, huma.Error404NotFound("Collection record not found", err)
	}

	resp := &CollectionOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Milk collection retrieved successfully"
	resp.Body.Data.Collection = col
	return resp, nil
}

func (h *Handler) ListCollections(ctx context.Context, input *ListCollectionsInput) (*ListCollectionsOutput, error) {
	q := query.Query{
		Page:    input.Page,
		PerPage: input.PerPage,
		Search:  input.Search,
		Filters: collectionFilters(input),
	}

	collections, meta, err := h.service.ListCollections(ctx, q)
	if err != nil {
		return nil, huma.Error500InternalServerError("Failed to retrieve milk collections", err)
	}

	resp := &ListCollectionsOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Milk collections retrieved successfully"
	resp.Body.Data.Collections = collections
	resp.Body.Data.Meta = meta
	return resp, nil
}

func (h *Handler) UpdateCollection(ctx context.Context, input *UpdateCollectionInput) (*CollectionOutput, error) {
	col, err := h.service.UpdateCollection(ctx, input.ID, &input.Body)
	if err != nil {
		return nil, toHTTPError(err)
	}

	resp := &CollectionOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Milk collection updated successfully"
	resp.Body.Data.Collection = col
	return resp, nil
}

func (h *Handler) UpdateCollectionStatus(ctx context.Context, input *UpdateCollectionStatusInput) (*CollectionOutput, error) {
	col, err := h.service.UpdateCollectionStatus(ctx, input.ID, &input.Body)
	if err != nil {
		return nil, toHTTPError(err)
	}

	resp := &CollectionOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Collection status updated successfully"
	resp.Body.Data.Collection = col
	return resp, nil
}

// GetCollectionHistory returns the audit trail of a collection.
func (h *Handler) GetCollectionHistory(ctx context.Context, input *CollectionIDInput) (*CollectionHistoryOutput, error) {
	history, err := h.service.CollectionHistory(ctx, input.ID)
	if err != nil {
		return nil, toHTTPError(err)
	}

	resp := &CollectionHistoryOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Collection history retrieved"
	resp.Body.Data.History = history
	return resp, nil
}

// toHTTPError maps domain errors to HTTP status codes. Anything that is not a
// known domain error is a validation problem with the request.
func toHTTPError(err error) error {
	switch {
	case errors.Is(err, ErrNotFound):
		return huma.Error404NotFound(userMessage(err, ErrNotFound))
	case errors.Is(err, ErrForbidden):
		return huma.Error403Forbidden(userMessage(err, ErrForbidden))
	case errors.Is(err, ErrLocked):
		return huma.Error409Conflict(userMessage(err, ErrLocked))
	default:
		return huma.Error400BadRequest(err.Error(), err)
	}
}

// userMessage is err's text for the person using the app, without the
// "locked: " style prefix the domain error adds for errors.Is.
func userMessage(err, kind error) string {
	msg := strings.TrimPrefix(err.Error(), kind.Error()+": ")
	if msg == "" {
		return msg
	}
	return strings.ToUpper(msg[:1]) + msg[1:]
}

// --- SALES HANDLERS ---

func (h *Handler) RecordSale(ctx context.Context, input *RecordSaleInput) (*SaleOutput, error) {
	sale, err := h.service.RecordSale(ctx, &input.Body)
	if err != nil {
		h.log.Error("Failed to record milk sale", err)
		return nil, toHTTPError(err)
	}

	resp := &SaleOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Milk sale recorded successfully"
	resp.Body.Data.Sale = sale
	return resp, nil
}

func (h *Handler) ListSales(ctx context.Context, input *ListSalesInput) (*ListSalesOutput, error) {
	q := query.Query{
		Page:    input.Page,
		PerPage: input.PerPage,
		Search:  input.Search,
		Filters: make(map[string]string),
	}

	if input.FromDate != "" {
		q.Filters["sale_date_from"] = input.FromDate
	}
	if input.ToDate != "" {
		q.Filters["sale_date_to"] = input.ToDate
	}
	if input.CollectorID > 0 {
		q.Filters["collector_id"] = idFilter(input.CollectorID)
	}
	if input.CustomerID != "" {
		q.Filters["customer_id"] = input.CustomerID
	}
	if input.PaymentStatus != "" {
		q.Filters["payment_status"] = input.PaymentStatus
	}

	sales, meta, err := h.service.ListSales(ctx, q)
	if err != nil {
		return nil, huma.Error500InternalServerError("Failed to retrieve sales records", err)
	}

	resp := &ListSalesOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Milk sales retrieved successfully"
	resp.Body.Data.Sales = sales
	resp.Body.Data.Meta = meta
	return resp, nil
}

func saleOutput(sale *MilkSale, msg string) *SaleOutput {
	resp := &SaleOutput{}
	resp.Body.Success = true
	resp.Body.Message = msg
	resp.Body.Data.Sale = sale
	return resp
}

// UpdateSale corrects a sale within the edit rules.
func (h *Handler) UpdateSale(ctx context.Context, input *UpdateSaleInput) (*SaleOutput, error) {
	sale, err := h.service.UpdateSale(ctx, input.ID, &input.Body)
	if err != nil {
		return nil, toHTTPError(err)
	}
	return saleOutput(sale, "Milk sale updated successfully"), nil
}

// VoidSale cancels a sale recorded in error.
func (h *Handler) VoidSale(ctx context.Context, input *VoidSaleInput) (*SaleOutput, error) {
	sale, err := h.service.VoidSale(ctx, input.ID, input.Body.Reason)
	if err != nil {
		return nil, toHTTPError(err)
	}
	return saleOutput(sale, "Milk sale voided"), nil
}

// GetSaleHistory returns the audit trail of a sale.
func (h *Handler) GetSaleHistory(ctx context.Context, input *SaleIDInput) (*CollectionHistoryOutput, error) {
	history, err := h.service.SaleHistory(ctx, input.ID)
	if err != nil {
		return nil, toHTTPError(err)
	}
	resp := &CollectionHistoryOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Sale history retrieved"
	resp.Body.Data.History = history
	return resp, nil
}

// --- SPOILAGE HANDLERS ---

func (h *Handler) RecordSpoilage(ctx context.Context, input *RecordSpoilageInput) (*SpoilageOutput, error) {
	sp, err := h.service.RecordSpoilage(ctx, &input.Body)
	if err != nil {
		h.log.Error("Failed to record milk spoilage", err)
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &SpoilageOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Milk spoilage logged successfully"
	resp.Body.Data.Spoilage = sp
	return resp, nil
}

func (h *Handler) ListSpoilage(ctx context.Context, input *ListSpoilageInput) (*ListSpoilageOutput, error) {
	q := query.Query{
		Page:    input.Page,
		PerPage: input.PerPage,
		Filters: spoilageFilters(input),
	}

	spoilages, meta, err := h.service.ListSpoilage(ctx, q)
	if err != nil {
		return nil, huma.Error500InternalServerError("Failed to retrieve spoilage records", err)
	}

	resp := &ListSpoilageOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Milk spoilage logs retrieved successfully"
	resp.Body.Data.Spoilages = spoilages
	resp.Body.Data.Meta = meta
	return resp, nil
}

// --- RECONCILIATION SUMMARY HANDLER ---

func (h *Handler) GetReconciliation(ctx context.Context, input *ReconciliationInput) (*ReconciliationOutput, error) {
	var collectorIDPtr *uint
	if input.CollectorID > 0 {
		collectorIDPtr = &input.CollectorID
	}

	recon, err := h.service.GetReconciliation(ctx, collectorIDPtr, input.Date)
	if err != nil {
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &ReconciliationOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Collector daily reconciliation summary retrieved"
	resp.Body.Data.Reconciliation = *recon
	return resp, nil
}
