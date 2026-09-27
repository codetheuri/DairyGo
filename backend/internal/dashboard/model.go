package dashboard

import "github.com/codetheuri/tusk/pkg/reconcile"

// ExecutiveSummaryCards holds real-time aggregated metrics for Sacco Admins & Board Members.
type ExecutiveSummaryCards struct {
	TodayCollectedLitres    float64          `json:"today_collected_litres"`
	TodaySalesLitres        float64          `json:"today_sales_litres"`
	TodaySpoilageLitres     float64          `json:"today_spoilage_litres"`
	TodayUnaccountedLitres  float64          `json:"today_unaccounted_litres" doc:"Collected minus sold minus spoiled today; positive is missing, negative is oversold"`
	TodayBalanceStatus      reconcile.Status `json:"today_balance_status"`
	MonthCollectedLitres    float64          `json:"month_collected_litres"`
	MonthPayoutLiabilityKES float64          `json:"month_payout_liability_kes"`
	MonthSalesRevenueKES    float64          `json:"month_sales_revenue_kes"`
	MonthGrossMarginKES     float64          `json:"month_gross_margin_kes" doc:"Month sales revenue minus what is owed to farmers"`
	ReceivablesKES          float64          `json:"receivables_kes" doc:"What customers owe the Sacco right now"`
	ActiveMembersCount      int64            `json:"active_members_count"`
	ActiveCollectorsCount   int64            `json:"active_collectors_count"`
}

// DailyTrendPoint holds time-series metrics for intake vs sales vs spoilage charts.
type DailyTrendPoint struct {
	Date              string  `json:"date"`
	CollectedLitres   float64 `json:"collected_litres"`
	SalesLitres       float64 `json:"sales_litres"`
	SpoilageLitres    float64 `json:"spoilage_litres"`
	UnaccountedLitres float64 `json:"unaccounted_litres"`
}

// ExecutiveDashboardData represents full data structure for executive overview.
type ExecutiveDashboardData struct {
	SummaryCards ExecutiveSummaryCards `json:"summary_cards"`
	IntakeTrend  []DailyTrendPoint     `json:"intake_trend"`
}

// CollectorDashboardData represents real-time mobile dashboard metrics for a field collector.
type CollectorDashboardData struct {
	CollectorID            uint             `json:"collector_id"`
	CollectorName          string           `json:"collector_name"`
	Date                   string           `json:"date"`
	TodayCollectedLitres   float64          `json:"today_collected_litres"`
	TodayPurchasesAmount   float64          `json:"today_purchases_amount"`
	TodayFarmersServiced   int64            `json:"today_farmers_serviced"`
	TodaySoldLitres        float64          `json:"today_sold_litres"`
	TodaySalesRevenue      float64          `json:"today_sales_revenue"`
	TodayCashReceived      float64          `json:"today_cash_received"`
	TodaySpoiledLitres     float64          `json:"today_spoiled_litres"`
	TodayUnaccountedLitres float64          `json:"today_unaccounted_litres"`
	TodayBalanceStatus     reconcile.Status `json:"today_balance_status"`
}
