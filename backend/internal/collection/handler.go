package collection

import (
	"context"

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

// --- COLLECTION HANDLERS ---

func (h *Handler) RecordCollection(ctx context.Context, input *RecordCollectionInput) (*CollectionOutput, error) {
	col, err := h.service.RecordCollection(ctx, &input.Body)
	if err != nil {
		h.log.Error("Failed to record milk collection", err)
		return nil, huma.Error400BadRequest(err.Error(), err)
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
		Filters: make(map[string]string),
	}

	if input.MemberID != "" {
		q.Filters["member_id"] = input.MemberID
	}
	if input.CollectorID > 0 {
		q.Filters["collector_id"] = string(rune(input.CollectorID))
	}
	if input.Shift != "" {
		q.Filters["shift"] = input.Shift
	}
	if input.Status != "" {
		q.Filters["status"] = input.Status
	}
	if input.FromDate != "" {
		q.Filters["collection_date_from"] = input.FromDate
	}
	if input.ToDate != "" {
		q.Filters["collection_date_to"] = input.ToDate
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
		return nil, huma.Error400BadRequest(err.Error(), err)
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
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &CollectionOutput{}
	resp.Body.Success = true
	resp.Body.Message = "Collection status updated successfully"
	resp.Body.Data.Collection = col
	return resp, nil
}

// --- SALES HANDLERS ---

func (h *Handler) RecordSale(ctx context.Context, input *RecordSaleInput) (*SaleOutput, error) {
	sale, err := h.service.RecordSale(ctx, &input.Body)
	if err != nil {
		h.log.Error("Failed to record milk sale", err)
		return nil, huma.Error400BadRequest(err.Error(), err)
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
		Filters: make(map[string]string),
	}

	if input.FromDate != "" {
		q.Filters["spoilage_date_from"] = input.FromDate
	}
	if input.ToDate != "" {
		q.Filters["spoilage_date_to"] = input.ToDate
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
