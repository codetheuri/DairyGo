package collection

import (
	"testing"
	"time"
)

func TestRepriceSales(t *testing.T) {
	d := func(day int) time.Time { return time.Date(2026, 10, day, 0, 0, 0, 0, time.Local) }
	agreed := 62.0
	row := func(day int, price float64) CustomerPrice {
		return CustomerPrice{PricePerLitre: price, EffectiveDate: d(day), CreatedAt: d(day)}
	}
	sale := func(id string, day int, litres, price, paid float64) MilkSale {
		return MilkSale{ID: id, SaleDate: d(day), QuantityLitres: litres, UnitPrice: price,
			TotalAmount: litres * price, AmountPaid: paid}
	}
	now := time.Now()
	sales := []MilkSale{
		sale("before", 2, 10, 62, 0),    // before the new price: unchanged
		sale("credit", 5, 10, 62, 0),    // on credit at the agreed price
		sale("partial", 6, 10, 62, 300), // part paid
		sale("paid", 7, 10, 62, 620),    // paid in full
		sale("discount", 8, 10, 55, 0),  // price typed on the day
		{ID: "void", SaleDate: d(9), QuantityLitres: 10, UnitPrice: 62, TotalAmount: 620, VoidedAt: &now},
	}
	before := []CustomerPrice{}
	after := []CustomerPrice{row(1, 62), row(5, 65)}

	changes, sum := repriceSales(sales, before, after, &agreed)
	got := map[string]saleReprice{}
	for _, c := range changes {
		got[c.Sale.ID] = c
	}
	if len(changes) != 3 {
		t.Fatalf("repriced %d sales, want 3 (credit, partial, paid): %+v", len(changes), changes)
	}
	if c := got["credit"]; c.NewTotal != 650 || c.NewStatus != SaleCredit || c.PaidFull {
		t.Errorf("credit = %+v", c)
	}
	if c := got["partial"]; c.NewStatus != SalePartial {
		t.Errorf("partial = %+v", c)
	}
	if c := got["paid"]; !c.PaidFull || c.NewStatus != SalePartial || c.NewTotal != 650 {
		t.Errorf("paid in full at 62, now 650 with 620 received = %+v", c)
	}
	want := RepriceSummary{CreditSales: 2, CreditChange: 60, PaidSales: 1, PaidChange: 30, Handtyped: 1}
	if sum != want {
		t.Errorf("summary = %+v, want %+v", sum, want)
	}

	// A lower price: a sale paid in full stays paid, the customer is in credit.
	changes, sum = repriceSales([]MilkSale{sale("paid", 7, 10, 62, 620)}, before, []CustomerPrice{row(5, 60)}, &agreed)
	if len(changes) != 1 || changes[0].NewStatus != SalePaid || sum.PaidChange != -20 {
		t.Errorf("price down on a paid sale = %+v %+v", changes, sum)
	}

	// No agreed price and no history before the change: nothing to compare,
	// so the sale is treated as typed by hand.
	_, sum = repriceSales([]MilkSale{sale("x", 6, 10, 70, 0)}, nil, []CustomerPrice{row(5, 65)}, nil)
	if sum.Handtyped != 1 || sum.CreditSales != 0 {
		t.Errorf("no earlier price = %+v", sum)
	}
}

func TestCustomerFirstDay(t *testing.T) {
	added := time.Date(2026, 9, 20, 14, 0, 0, 0, time.Local)
	early := time.Date(2026, 8, 3, 0, 0, 0, 0, time.Local)
	c := priceCustomer{CreatedAt: added}
	if got := c.FirstDay(); got.Format(dateLayout) != "2026-09-20" {
		t.Errorf("first day = %s", got.Format(dateLayout))
	}
	c.FirstSale = &early
	if got := c.FirstDay(); got.Format(dateLayout) != "2026-08-03" {
		t.Errorf("with an older sale = %s", got.Format(dateLayout))
	}
}
