package report

import "time"

// FarmerPayoutStatement represents a summary of earnings and milk supplied by a farmer over a date range.
type FarmerPayoutStatement struct {
	MemberID             string    `json:"member_id"`
	MembershipNumber     string    `json:"membership_number"`
	FarmerName           string    `json:"farmer_name"`
	Phone                string    `json:"phone,omitempty"`
	MpesaNumber          *string   `json:"mpesa_number,omitempty"`
	BankAccountNumber    *string   `json:"bank_account_number,omitempty"`
	BankName             *string   `json:"bank_name,omitempty"`
	TotalLitres          float64   `json:"total_litres"`
	AveragePricePerLitre float64   `json:"average_price_per_litre"`
	GrossAmountOwed      float64   `json:"gross_amount_owed"`
	CollectionsCount     int64     `json:"collections_count"`
	FromDate             time.Time `json:"from_date"`
	ToDate               time.Time `json:"to_date"`
}

// SaccoReconciliationLedger represents the complete mathematical balancing statement for a Sacco.
type SaccoReconciliationLedger struct {
	SaccoID                   string                  `json:"sacco_id"`
	SaccoName                 string                  `json:"sacco_name,omitempty"`
	FromDate                  string                  `json:"from_date"`
	ToDate                    string                  `json:"to_date"`
	TotalFarmerIntakeLitres   float64                 `json:"total_farmer_intake_litres"`
	TotalFarmerLiabilityKES   float64                 `json:"total_farmer_liability_kes"`
	TotalFieldSalesLitres     float64                 `json:"total_field_sales_litres"`
	TotalFieldSalesRevenueKES float64                 `json:"total_field_sales_revenue_kes"`
	TotalSpoilageLitres       float64                 `json:"total_spoilage_litres"`
	NetCoolantStationLitres   float64                 `json:"net_coolant_station_litres"`
	IsBalanced                bool                    `json:"is_balanced"`
	DiscrepancyLitres         float64                 `json:"discrepancy_litres"`
	CollectorsSummary         []CollectorAuditSummary `json:"collectors_summary"`
}

// CollectorAuditSummary represents performance & transit metrics for a collector over a date range.
type CollectorAuditSummary struct {
	CollectorID          uint    `json:"collector_id"`
	CollectorName        string  `json:"collector_name"`
	TotalCollectedLitres float64 `json:"total_collected_litres"`
	TotalPurchasesAmount float64 `json:"total_purchases_amount"`
	TotalSoldLitres      float64 `json:"total_sold_litres"`
	TotalSalesRevenue    float64 `json:"total_sales_revenue"`
	TotalSpoiledLitres   float64 `json:"total_spoiled_litres"`
	NetDeliveredLitres   float64 `json:"net_delivered_litres"`
	FarmersServicedCount int64   `json:"farmers_serviced_count"`
}
