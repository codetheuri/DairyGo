package report

import (
	"time"

	"github.com/codetheuri/tusk/pkg/reconcile"
)

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

// SaccoReconciliationLedger balances a Sacco's milk over a period: every litre
// collected must be sold to a customer (coolers included) or logged as
// spoilage. Transfers between collectors cancel out at this level.
type SaccoReconciliationLedger struct {
	SaccoID                 string  `json:"sacco_id"`
	SaccoName               string  `json:"sacco_name,omitempty"`
	FromDate                string  `json:"from_date"`
	ToDate                  string  `json:"to_date"`
	TotalFarmerIntakeLitres float64 `json:"total_farmer_intake_litres"`
	TotalFarmerLiabilityKES float64 `json:"total_farmer_liability_kes"`
	TotalSoldLitres         float64 `json:"total_sold_litres"`
	TotalSalesRevenueKES    float64 `json:"total_sales_revenue_kes"`
	CashReceivedKES         float64 `json:"cash_received_kes" doc:"Paid at the time of sale"`
	CreditSalesKES          float64 `json:"credit_sales_kes" doc:"Sold on credit in the period"`
	TotalSpoilageLitres     float64 `json:"total_spoilage_litres"`
	// TotalTransferredLitres moved between collectors. It does not change
	// the Sacco's balance: each litre left one collector and reached another.
	TotalTransferredLitres float64 `json:"total_transferred_litres"`
	reconcile.Result
	GrossMarginKES      float64                 `json:"gross_margin_kes" doc:"Sales revenue minus what is owed to farmers"`
	ReceivablesKES      float64                 `json:"receivables_kes" doc:"What customers owe the Sacco right now (all periods)"`
	SalesByCustomerType []reconcile.TypeTotal   `json:"sales_by_customer_type"`
	CollectorsSummary   []CollectorAuditSummary `json:"collectors_summary"`
}

// CollectorAuditSummary balances one collector's milk over a period,
// transfers to and from other collectors included.
type CollectorAuditSummary struct {
	CollectorID          uint    `json:"collector_id"`
	CollectorName        string  `json:"collector_name"`
	ActiveDays           int64   `json:"active_days"`
	TotalCollectedLitres float64 `json:"total_collected_litres"`
	TotalPurchasesAmount float64 `json:"total_purchases_amount"`
	TotalSoldLitres      float64 `json:"total_sold_litres"`
	TotalSalesRevenue    float64 `json:"total_sales_revenue"`
	CashReceivedAmount   float64 `json:"cash_received_amount"`
	TotalSpoiledLitres   float64 `json:"total_spoiled_litres"`
	// Milk from and to other collectors in the period.
	TotalReceivedLitres       float64 `json:"total_received_litres"`
	TotalTransferredOutLitres float64 `json:"total_transferred_out_litres"`
	reconcile.Result
	FarmersServicedCount int64 `json:"farmers_serviced_count"`
	// ToleranceLitres is the Sacco's allowed difference per collector per
	// day, so clients can balance each day of the period the same way.
	ToleranceLitres float64 `json:"tolerance_litres"`
}
