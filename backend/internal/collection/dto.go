package collection

import (
	"github.com/codetheuri/tusk/pkg/query"
	"github.com/codetheuri/tusk/pkg/response"
)

// --- PRICING DTOs ---

type SetPriceRequest struct {
	PricePerLitre float64 `json:"price_per_litre" minimum:"0.01" doc:"New Sacco buying price per litre"`
	EffectiveDate *string `json:"effective_date,omitempty" doc:"Effective date (YYYY-MM-DD), defaults to today"`
}

type SetPriceInput struct {
	Body SetPriceRequest
}

type PriceData struct {
	Price *MilkPrice `json:"price"`
}

type PriceOutput struct {
	Body response.Data[PriceData]
}

type ListPricesData struct {
	Prices []MilkPrice `json:"prices"`
	Meta   query.Meta  `json:"meta"`
}

type ListPricesOutput struct {
	Body response.Data[ListPricesData]
}

type ListPricesInput struct {
	Page    int `query:"page" doc:"Page number (default 1)"`
	PerPage int `query:"per_page" doc:"Items per page (default 20)"`
}

type GetActivePriceInput struct{}

// --- COLLECTION DTOs ---

type RecordCollectionRequest struct {
	MemberID       string   `json:"member_id" doc:"Member UUID"`
	CollectionDate *string  `json:"collection_date,omitempty" doc:"Collection date (YYYY-MM-DD), defaults to today if omitted"`
	Shift          *Shift   `json:"shift,omitempty" doc:"Shift: MORNING, EVENING, FULL_DAY (default MORNING)"`
	QuantityLitres float64  `json:"quantity_litres" minimum:"0.01" doc:"Quantity of milk in litres"`
	PricePerLitre  *float64 `json:"price_per_litre,omitempty" doc:"Optional manual price per litre override (Admins only)"`
	Notes          *string  `json:"notes,omitempty" doc:"Optional notes"`
}

type RecordCollectionInput struct {
	Body RecordCollectionRequest
}

type UpdateCollectionRequest struct {
	QuantityLitres *float64 `json:"quantity_litres,omitempty" minimum:"0.01" doc:"Updated quantity of milk in litres"`
	Shift          *Shift   `json:"shift,omitempty" doc:"Updated shift"`
	Notes          *string  `json:"notes,omitempty" doc:"Updated notes"`
}

type UpdateCollectionInput struct {
	ID   string `path:"id" doc:"Collection UUID"`
	Body UpdateCollectionRequest
}

type CollectionIDInput struct {
	ID string `path:"id" doc:"Collection UUID"`
}

type UpdateCollectionStatusRequest struct {
	Status CollectionStatus `json:"status" enum:"SUBMITTED,VERIFIED,REJECTED,ADJUSTED" doc:"Updated status"`
	Notes  *string          `json:"notes,omitempty" doc:"Reason for status update"`
}

type UpdateCollectionStatusInput struct {
	ID   string `path:"id" doc:"Collection UUID"`
	Body UpdateCollectionStatusRequest
}

type ListCollectionsInput struct {
	Page        int    `query:"page" doc:"Page number (default 1)"`
	PerPage     int    `query:"per_page" doc:"Items per page (default 20)"`
	MemberID    string `query:"member_id" doc:"Filter by Member UUID"`
	CollectorID uint   `query:"collector_id" doc:"Filter by Collector User ID"`
	FromDate    string `query:"from_date" doc:"Filter from date (YYYY-MM-DD)"`
	ToDate      string `query:"to_date" doc:"Filter to date (YYYY-MM-DD)"`
	Shift       string `query:"shift" doc:"Filter by shift (MORNING, EVENING, FULL_DAY)"`
	Status      string `query:"status" doc:"Filter by status"`
	Search      string `query:"search" doc:"Search query"`
	Sort        string `query:"sort" doc:"Sort field"`
}

type CollectionData struct {
	Collection *MilkCollection `json:"collection"`
}

type CollectionOutput struct {
	Body response.Data[CollectionData]
}

type ListCollectionsData struct {
	Collections []MilkCollection `json:"collections"`
	Meta        query.Meta       `json:"meta"`
}

type ListCollectionsOutput struct {
	Body response.Data[ListCollectionsData]
}

// --- SALES DTOs ---

type RecordSaleRequest struct {
	SaleDate       string  `json:"sale_date" doc:"Sale date (YYYY-MM-DD)"`
	BuyerName      string  `json:"buyer_name" minLength:"2" doc:"Buyer or Establishment name (e.g. Hotel B)"`
	BuyerPhone     *string `json:"buyer_phone,omitempty" doc:"Buyer contact phone"`
	QuantityLitres float64 `json:"quantity_litres" minimum:"0.01" doc:"Quantity sold in litres"`
	UnitPrice      float64 `json:"unit_price" minimum:"0.01" doc:"Selling price per litre"`
	PaymentStatus  *string `json:"payment_status,omitempty" enum:"PAID,PENDING,PARTIAL" doc:"Payment status"`
	PaymentMethod  *string `json:"payment_method,omitempty" enum:"CASH,MPESA,BANK_TRANSFER,CREDIT" doc:"Payment method"`
	Notes          *string `json:"notes,omitempty" doc:"Optional notes"`
}

type RecordSaleInput struct {
	Body RecordSaleRequest
}

type SaleIDInput struct {
	ID string `path:"id" doc:"Sale UUID"`
}

type ListSalesInput struct {
	Page        int    `query:"page" doc:"Page number (default 1)"`
	PerPage     int    `query:"per_page" doc:"Items per page (default 20)"`
	CollectorID uint   `query:"collector_id" doc:"Filter by Collector User ID"`
	FromDate    string `query:"from_date" doc:"Filter from date"`
	ToDate      string `query:"to_date" doc:"Filter to date"`
	Search      string `query:"search" doc:"Search by buyer name or phone"`
	Sort        string `query:"sort" doc:"Sort field"`
}

type SaleData struct {
	Sale *MilkSale `json:"sale"`
}

type SaleOutput struct {
	Body response.Data[SaleData]
}

type ListSalesData struct {
	Sales []MilkSale `json:"sales"`
	Meta  query.Meta `json:"meta"`
}

type ListSalesOutput struct {
	Body response.Data[ListSalesData]
}

// --- SPOILAGE DTOs ---

type RecordSpoilageRequest struct {
	SpoilageDate   string  `json:"spoilage_date" doc:"Spoilage date (YYYY-MM-DD)"`
	QuantityLitres float64 `json:"quantity_litres" minimum:"0.01" doc:"Quantity spoiled in litres"`
	Reason         string  `json:"reason" minLength:"3" doc:"Reason for spoilage (e.g. Acidic failure, Spillage)"`
	Notes          *string `json:"notes,omitempty" doc:"Optional notes"`
}

type RecordSpoilageInput struct {
	Body RecordSpoilageRequest
}

type ListSpoilageInput struct {
	Page        int    `query:"page" doc:"Page number"`
	PerPage     int    `query:"per_page" doc:"Items per page"`
	CollectorID uint   `query:"collector_id" doc:"Filter by Collector"`
	FromDate    string `query:"from_date" doc:"From date"`
	ToDate      string `query:"to_date" doc:"To date"`
}

type SpoilageData struct {
	Spoilage *MilkSpoilage `json:"spoilage"`
}

type SpoilageOutput struct {
	Body response.Data[SpoilageData]
}

type ListSpoilageData struct {
	Spoilages []MilkSpoilage `json:"spoilages"`
	Meta      query.Meta     `json:"meta"`
}

type ListSpoilageOutput struct {
	Body response.Data[ListSpoilageData]
}

// --- RECONCILIATION OVERVIEW DTOs ---

type ReconciliationInput struct {
	CollectorID uint   `query:"collector_id" doc:"Optional collector filter (Admins can specify; Collectors default to self)"`
	Date        string `query:"date" doc:"Date for reconciliation (YYYY-MM-DD), defaults to today"`
}

type ReconciliationData struct {
	Reconciliation CollectorReconciliation `json:"reconciliation"`
}

type ReconciliationOutput struct {
	Body response.Data[ReconciliationData]
}
