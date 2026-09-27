// Package reconcile holds the milk balancing rule shared by collector
// reconciliation, reports and dashboards.
//
// Every litre a collector receives must leave as a sale (coolers included) or
// be logged as spoilage:
//
//	collected = sold + spoiled + unaccounted
//
// Unaccounted milk above zero is missing (loss or theft); below zero means
// more was sold than collected (a recording error or added water). A Sacco sets
// a tolerance in litres per collector per day for normal measuring differences.
package reconcile

import (
	"context"
	"math"
	"time"

	"gorm.io/gorm"
)

// Status summarises a balance check.
type Status string

const (
	StatusBalanced Status = "BALANCED"
	StatusMissing  Status = "MISSING"
	StatusOversold Status = "OVERSOLD"
)

// Result is the outcome of balancing collected milk against sales and spoilage.
type Result struct {
	UnaccountedLitres float64 `json:"unaccounted_litres"`
	AllowanceLitres   float64 `json:"allowance_litres"`
	IsBalanced        bool    `json:"is_balanced"`
	Status            Status  `json:"balance_status"`
}

// Compute balances collected against sold and spoiled litres. allowance is the
// tolerated difference in litres (tolerance × collector-days being checked).
func Compute(collected, sold, spoiled, allowance float64) Result {
	unaccounted := round2(collected - sold - spoiled)
	allowance = round2(math.Max(allowance, 0))

	r := Result{UnaccountedLitres: unaccounted, AllowanceLitres: allowance}
	switch {
	case math.Abs(unaccounted) <= allowance+0.005:
		r.IsBalanced, r.Status = true, StatusBalanced
	case unaccounted > 0:
		r.Status = StatusMissing
	default:
		r.Status = StatusOversold
	}
	return r
}

// ToleranceLitres returns a Sacco's allowed difference per collector per day.
func ToleranceLitres(ctx context.Context, db *gorm.DB, saccoID string) float64 {
	var tolerance float64
	db.WithContext(ctx).Table("sacco_settings").
		Select("COALESCE(reconciliation_tolerance_litres, 0)").
		Where("sacco_id = ?", saccoID).
		Scan(&tolerance)
	return tolerance
}

// TypeTotal is milk sold to one type of customer (e.g. COOLER) in a period.
type TypeTotal struct {
	CustomerType string  `json:"customer_type"`
	Litres       float64 `json:"litres"`
	Revenue      float64 `json:"revenue"`
}

// SalesByCustomerType totals non-voided sales in [from, to] by customer type.
// collectorID 0 means every collector.
func SalesByCustomerType(ctx context.Context, db *gorm.DB, saccoID string, from, to time.Time, collectorID uint) ([]TypeTotal, error) {
	session := db.WithContext(ctx).Table("milk_sales s").
		Select("c.customer_type, COALESCE(SUM(s.quantity_litres), 0) AS litres, COALESCE(SUM(s.total_amount), 0) AS revenue").
		Joins("JOIN customers c ON c.id = s.customer_id").
		Where("s.sacco_id = ? AND s.deleted_at IS NULL AND s.voided_at IS NULL AND s.sale_date BETWEEN ? AND ?",
			saccoID, from.Format(DateLayout), to.Format(DateLayout))
	if collectorID > 0 {
		session = session.Where("s.collector_id = ?", collectorID)
	}

	var totals []TypeTotal
	if err := session.Group("c.customer_type").Order("litres DESC").Scan(&totals).Error; err != nil {
		return nil, err
	}
	for i := range totals {
		totals[i].Litres = round2(totals[i].Litres)
		totals[i].Revenue = round2(totals[i].Revenue)
	}
	return totals, nil
}

// Receivables is what all customers of a Sacco owe right now: sale totals minus
// amounts paid at sale and customer payments, excluding voided entries.
func Receivables(ctx context.Context, db *gorm.DB, saccoID string) float64 {
	var owed float64
	db.WithContext(ctx).Raw(`
		SELECT
			COALESCE((SELECT SUM(total_amount - amount_paid) FROM milk_sales
			          WHERE sacco_id = ? AND deleted_at IS NULL AND voided_at IS NULL), 0)
		  - COALESCE((SELECT SUM(amount) FROM customer_payments
			          WHERE sacco_id = ? AND voided_at IS NULL), 0)`, saccoID, saccoID).
		Scan(&owed)
	return round2(owed)
}

// DateLayout is the calendar-date format used in queries.
const DateLayout = "2006-01-02"

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
