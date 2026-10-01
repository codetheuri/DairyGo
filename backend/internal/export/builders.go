package export

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/codetheuri/tusk/internal/customer"
	"github.com/codetheuri/tusk/pkg/document"
)

// Short names for the column kinds.
const (
	txt   = document.Text
	money = document.Money
	ltr   = document.Litres
	num   = document.Number
	cnt   = document.Count
	day   = document.Date
)

func col(title string, kind document.Kind, width float64) document.Column {
	return document.Column{Title: title, Kind: kind, Width: width}
}

func kes(v float64) string    { return document.Format(document.Money, v) }
func litres(v float64) string { return document.Thousands(v, 2) + " L" }
func count(v int) string      { return document.Thousands(float64(v), 0) }

func perLitre(amount, l float64) float64 {
	if l == 0 {
		return 0
	}
	return amount / l
}

// payoutTo is where a farmer is paid: M-Pesa, else bank, else nothing set.
func payoutTo(f Farmer) string {
	if v := deref(f.MpesaNumber); v != "" {
		return "M-Pesa " + v
	}
	if v := deref(f.BankAccountNumber); v != "" {
		bank := deref(f.BankName)
		if bank == "" {
			bank = "Bank"
		}
		return strings.TrimSpace(bank + " " + v + " " + deref(f.BankBranch))
	}
	return "Not set"
}

func farmerPayouts(ctx context.Context, s *Service, in *input) error {
	rows, err := s.repo.Payouts(ctx, in.saccoID, in.from, in.to)
	if err != nil {
		return err
	}
	t := document.Table{
		Columns: []document.Column{
			col("No.", txt, 0.7), col("Farmer", txt, 2), col("Phone", txt, 1.2), col("Pay to", txt, 2.2),
			col("Deliveries", cnt, 0.9), col("Litres", ltr, 1), col("Avg price/L", num, 1), col("Amount owed", money, 1.4),
		},
		Empty: "No farmer delivered accepted milk in this period.",
	}
	var l, a float64
	var deliveries int64
	for _, p := range rows {
		t.Rows = append(t.Rows, []any{p.MembershipNumber, p.FullName(), p.Phone, payoutTo(p.Farmer),
			p.Deliveries, p.Litres, perLitre(p.Amount, p.Litres), p.Amount})
		l, a, deliveries = l+p.Litres, a+p.Amount, deliveries+p.Deliveries
	}
	if len(rows) > 0 {
		t.Totals = []any{"Total", fmt.Sprintf("%d farmers", len(rows)), nil, nil, deliveries, l, perLitre(a, l), a}
	}
	in.doc.Figures = []document.Figure{
		{Label: "Total owed to farmers", Value: kes(a)}, {Label: "Litres", Value: litres(l)},
		{Label: "Farmers", Value: count(len(rows))}, {Label: "Average price", Value: kes(perLitre(a, l)) + "/L"},
	}
	in.doc.Tables = []document.Table{t}
	in.doc.Notes = []string{"Only accepted milk is counted: rejected collections are left out."}
	return nil
}

func farmerStatement(ctx context.Context, s *Service, in *input) error {
	f, err := s.repo.Farmer(ctx, in.saccoID, in.req.MemberID)
	if err != nil {
		return err
	}
	rows, err := s.repo.Deliveries(ctx, in.saccoID, in.from, in.to, DeliveryFilter{
		MemberID: f.ID, CollectorID: in.collectorID, Accepted: true,
	})
	if err != nil {
		return err
	}
	in.doc.Subject = fmt.Sprintf("%s · Member %s", f.FullName(), f.MembershipNumber)
	if f.Phone != "" {
		in.doc.Subject += " · " + f.Phone
	}
	t := document.Table{
		Title: "Deliveries",
		Columns: []document.Column{
			col("#", cnt, 0.45), col("Date", day, 1.2), col("Time", txt, 0.8), col("Shift", txt, 0.9),
			col("Litres", ltr, 0.9), col("Price/L", num, 0.9), col("Amount", money, 1.3),
		},
		Empty: "No accepted deliveries in this period.",
	}
	var l, a float64
	for i, d := range rows {
		t.Rows = append(t.Rows, []any{i + 1, d.CollectionDate, d.CreatedAt.In(nairobi).Format("3:04 PM"), title(d.Shift),
			d.QuantityLitres, d.PricePerLitre, d.TotalAmount})
		l, a = l+d.QuantityLitres, a+d.TotalAmount
	}
	if len(rows) > 0 {
		t.Totals = []any{"Total", nil, nil, nil, l, nil, a}
	}
	in.doc.Figures = []document.Figure{
		{Label: "Total payment", Value: kes(a)}, {Label: "Litres collected", Value: litres(l)},
		{Label: "Deliveries", Value: count(len(rows))},
	}
	in.doc.Tables = []document.Table{t}
	in.doc.Notes = []string{"Paid to: " + payoutTo(*f) + ". Each delivery is priced at the rate in force on its date."}
	return nil
}

func collections(ctx context.Context, s *Service, in *input) error {
	rows, err := s.repo.Deliveries(ctx, in.saccoID, in.from, in.to, DeliveryFilter{
		CollectorID: in.collectorID, Shift: strings.ToUpper(in.req.Shift),
	})
	if err != nil {
		return err
	}
	t := document.Table{
		Columns: []document.Column{
			col("Date", day, 1.1), col("Shift", txt, 0.8), col("No.", txt, 0.7), col("Farmer", txt, 2),
			col("Litres", ltr, 0.9), col("Price/L", num, 0.9), col("Amount", money, 1.3), col("Collector", txt, 1.5), col("Status", txt, 1),
		},
		Empty: "No milk was collected in this period.",
	}
	var l, a float64
	farmers := map[string]bool{}
	accepted := 0
	for _, d := range rows {
		t.Rows = append(t.Rows, []any{d.CollectionDate, title(d.Shift), d.MembershipNumber, d.FarmerName,
			d.QuantityLitres, d.PricePerLitre, d.TotalAmount, d.CollectorName, title(d.Status)})
		if d.Status != "REJECTED" {
			l, a = l+d.QuantityLitres, a+d.TotalAmount
			farmers[d.MembershipNumber] = true
			accepted++
		}
	}
	if len(rows) > 0 {
		t.Totals = []any{"Total", nil, nil, fmt.Sprintf("%d farmers", len(farmers)), l, perLitre(a, l), a, nil, nil}
	}
	in.doc.Figures = []document.Figure{
		{Label: "Litres collected", Value: litres(l)}, {Label: "Owed to farmers", Value: kes(a)},
		{Label: "Deliveries", Value: count(accepted)}, {Label: "Farmers", Value: count(len(farmers))},
	}
	in.doc.Tables = []document.Table{t}
	in.doc.Notes = []string{"Totals leave out rejected collections, which are listed for the record."}
	return nil
}

func sales(ctx context.Context, s *Service, in *input) error {
	rows, err := s.repo.Sales(ctx, in.saccoID, in.from, in.to, in.collectorID)
	if err != nil {
		return err
	}
	t := document.Table{
		Columns: []document.Column{
			col("Date", day, 1.1), col("Customer", txt, 2), col("Type", txt, 1), col("Litres", ltr, 0.9),
			col("Price/L", num, 0.9), col("Total", money, 1.3), col("Paid", money, 1.3), col("Owed", money, 1.3), col("Collector", txt, 1.4),
		},
		Empty: "No milk was sold in this period.",
	}
	var l, total, paid float64
	for _, x := range rows {
		t.Rows = append(t.Rows, []any{x.SaleDate, x.CustomerName, title(x.CustomerType), x.QuantityLitres,
			x.UnitPrice, x.TotalAmount, x.AmountPaid, x.TotalAmount - x.AmountPaid, x.CollectorName})
		l, total, paid = l+x.QuantityLitres, total+x.TotalAmount, paid+x.AmountPaid
	}
	if len(rows) > 0 {
		t.Totals = []any{"Total", fmt.Sprintf("%d sales", len(rows)), nil, l, perLitre(total, l), total, paid, total - paid, nil}
	}
	in.doc.Figures = []document.Figure{
		{Label: "Litres sold", Value: litres(l)}, {Label: "Sales", Value: kes(total)},
		{Label: "Paid at sale", Value: kes(paid)}, {Label: "On credit", Value: kes(total - paid)},
	}
	in.doc.Tables = []document.Table{t}
	in.doc.Notes = []string{"Voided sales are left out. \"Owed\" is what was not paid at the time of the sale; see Customers Owing for balances after payments."}
	return nil
}

func customerStatement(ctx context.Context, s *Service, in *input) error {
	st, err := s.customers.Statement(ctx, in.req.CustomerID, in.from.Format(dateLayout), in.to.Format(dateLayout))
	if err != nil {
		return err
	}
	c := st.Customer
	in.doc.Subject = c.Name + " · " + title(string(c.CustomerType))
	if c.Phone != nil && *c.Phone != "" {
		in.doc.Subject += " · " + *c.Phone
	}
	t := document.Table{
		Columns: []document.Column{
			col("Date", day, 1.1), col("Details", txt, 2.6), col("Litres", ltr, 0.9),
			col("Sales", money, 1.3), col("Payments", money, 1.3), col("Balance", money, 1.4),
		},
		Rows: [][]any{{in.from, "Balance brought forward", nil, nil, nil, st.OpeningBalance}},
	}
	for _, line := range st.Lines {
		date, _ := time.Parse(dateLayout, line.Date[:min(len(line.Date), 10)])
		var l, debit, credit any
		if line.Litres != 0 {
			l = line.Litres
		}
		if line.Debit != 0 {
			debit = line.Debit
		}
		if line.Credit != 0 {
			credit = line.Credit
		}
		t.Rows = append(t.Rows, []any{date, statementDetails(line.Kind, line.Description, line.Debit, line.Credit), l, debit, credit, line.Balance})
	}
	t.Totals = []any{"Closing balance", nil, nil, st.TotalDebit, st.TotalCredit, st.ClosingBalance}
	owes := "Owes the Sacco"
	if st.ClosingBalance < 0 {
		owes = "In credit"
	}
	in.doc.Figures = []document.Figure{
		{Label: "Opening balance", Value: kes(st.OpeningBalance)}, {Label: "Sales", Value: kes(st.TotalDebit)},
		{Label: "Payments", Value: kes(st.TotalCredit)}, {Label: owes, Value: kes(abs(st.ClosingBalance))},
	}
	in.doc.Tables = []document.Table{t}
	in.doc.Notes = []string{"Sales add to what the customer owes; payments reduce it. A negative balance is money paid in advance."}
	return nil
}

func customersOwing(ctx context.Context, s *Service, in *input) error {
	rows, total, err := s.customers.Balances(ctx, true)
	if err != nil {
		return err
	}
	t := document.Table{
		Columns: []document.Column{
			col("Customer", txt, 2.2), col("Type", txt, 1), col("Phone", txt, 1.2),
			col("Total sales", money, 1.3), col("Total paid", money, 1.3), col("Owes", money, 1.4),
		},
		Empty: "No customer owes the Sacco money.",
	}
	for _, b := range rows {
		t.Rows = append(t.Rows, []any{b.Name, title(string(b.CustomerType)), deref(b.Phone), b.TotalSales, b.TotalPaid, b.Balance})
	}
	if len(rows) > 0 {
		t.Totals = []any{fmt.Sprintf("%d customers", len(rows)), nil, nil, nil, nil, total}
	}
	in.doc.Figures = []document.Figure{{Label: "Total owed", Value: kes(total)}, {Label: "Customers owing", Value: count(len(rows))}}
	in.doc.Tables = []document.Table{t}
	return nil
}

func milkBalance(ctx context.Context, s *Service, in *input) error {
	rows, _, err := s.reports.GetCollectorAuditReport(ctx, in.from.Format(dateLayout), in.to.Format(dateLayout), in.collectorID, 1, 1000)
	if err != nil {
		return err
	}
	t := document.Table{
		Columns: []document.Column{
			col("Collector", txt, 1.8), col("Days", cnt, 0.6), col("Farmers", cnt, 0.8), col("Collected L", ltr, 1),
			col("Received L", ltr, 1), col("Sold L", ltr, 1), col("Transferred L", ltr, 1.1), col("Spoiled L", ltr, 0.9),
			col("Unaccounted L", ltr, 1.1), col("Result", txt, 1),
		},
		Empty: "No milk was handled in this period.",
	}
	var c, rcv, sold, out, sp, un float64
	for _, x := range rows {
		t.Rows = append(t.Rows, []any{x.CollectorName, x.ActiveDays, x.FarmersServicedCount, x.TotalCollectedLitres,
			x.TotalReceivedLitres, x.TotalSoldLitres, x.TotalTransferredOutLitres, x.TotalSpoiledLitres, x.UnaccountedLitres, title(string(x.Status))})
		c, rcv, sold, out, sp, un = c+x.TotalCollectedLitres, rcv+x.TotalReceivedLitres, sold+x.TotalSoldLitres,
			out+x.TotalTransferredOutLitres, sp+x.TotalSpoiledLitres, un+x.UnaccountedLitres
	}
	if len(rows) > 0 {
		t.Totals = []any{"Total", nil, nil, c, rcv, sold, out, sp, un, nil}
	}
	in.doc.Figures = []document.Figure{
		{Label: "Collected", Value: litres(c)}, {Label: "Sold", Value: litres(sold)},
		{Label: "Spoiled", Value: litres(sp)}, {Label: "Unaccounted", Value: litres(un)},
	}
	in.doc.Tables = []document.Table{t}
	in.doc.Notes = []string{
		"Unaccounted = collected + received - sold - transferred - spoiled. Above zero: milk missing; below zero: more sold than collected.",
		"Balanced means within the Sacco's measuring allowance for each day worked.",
	}
	return nil
}

func saccoSummary(ctx context.Context, s *Service, in *input) error {
	ledger, err := s.reports.GetSaccoReconciliationLedger(ctx, in.from.Format(dateLayout), in.to.Format(dateLayout))
	if err != nil {
		return err
	}
	days, err := s.repo.Days(ctx, in.saccoID, in.from, in.to)
	if err != nil {
		return err
	}
	t := document.Table{
		Title: "Day by day",
		Columns: []document.Column{
			col("Date", day, 1.1), col("Farmers", cnt, 0.7), col("Collected L", ltr, 1), col("Cost of milk", money, 1.3),
			col("Sold L", ltr, 1), col("Sales", money, 1.3), col("Spoiled L", ltr, 0.9), col("Unaccounted L", ltr, 1.1), col("Margin", money, 1.3),
		},
	}
	var tc, tcost, ts, trev, tsp float64
	for _, d := range days {
		un := d.CollectedL - d.SoldL - d.SpoiledL
		if !d.HasActivities {
			t.Rows = append(t.Rows, []any{d.Date, nil, nil, nil, nil, nil, nil, nil, nil})
			continue
		}
		t.Rows = append(t.Rows, []any{d.Date, d.Farmers, d.CollectedL, d.PurchaseCost, d.SoldL, d.Revenue, d.SpoiledL, un, d.Revenue - d.PurchaseCost})
		tc, tcost, ts, trev, tsp = tc+d.CollectedL, tcost+d.PurchaseCost, ts+d.SoldL, trev+d.Revenue, tsp+d.SpoiledL
	}
	t.Totals = []any{"Total", nil, tc, tcost, ts, trev, tsp, tc - ts - tsp, trev - tcost}

	byType := document.Table{
		Title:   "Sales by customer type",
		Columns: []document.Column{col("Customer type", txt, 2), col("Litres", ltr, 1), col("Sales", money, 1.4)},
		Empty:   "No sales in this period.",
	}
	for _, x := range ledger.SalesByCustomerType {
		byType.Rows = append(byType.Rows, []any{title(x.CustomerType), x.Litres, x.Revenue})
	}

	in.doc.Figures = []document.Figure{
		{Label: "Milk collected", Value: litres(ledger.TotalFarmerIntakeLitres)},
		{Label: "Owed to farmers", Value: kes(ledger.TotalFarmerLiabilityKES)},
		{Label: "Sales", Value: kes(ledger.TotalSalesRevenueKES)},
		{Label: "Gross margin", Value: kes(ledger.GrossMarginKES)},
		{Label: "Milk sold", Value: litres(ledger.TotalSoldLitres)},
		{Label: "Spoiled", Value: litres(ledger.TotalSpoilageLitres)},
		{Label: "Unaccounted", Value: litres(ledger.UnaccountedLitres)},
		{Label: "Customers owe (today)", Value: kes(ledger.ReceivablesKES)},
	}
	in.doc.Tables = []document.Table{t, byType}
	in.doc.Notes = []string{"Margin = sales minus the cost of milk bought from farmers. Unaccounted = collected - sold - spoiled (transfers between collectors cancel out)."}
	return nil
}

func farmerRegister(ctx context.Context, s *Service, in *input) error {
	status := strings.ToUpper(strings.TrimSpace(in.req.Status))
	rows, err := s.repo.Farmers(ctx, in.saccoID, status)
	if err != nil {
		return err
	}
	if status != "" {
		in.doc.Subject = title(status) + " farmers"
	}
	t := document.Table{
		Columns: []document.Column{
			col("No.", txt, 0.6), col("Farmer", txt, 1.8), col("Gender", txt, 0.7), col("Phone", txt, 1.1), col("Location", txt, 1.4),
			col("Pay to", txt, 2), col("Next of kin", txt, 2.2), col("Status", txt, 0.8), col("Registered", day, 1),
		},
		Empty: "No farmers.",
	}
	counts := map[string]int{}
	for _, f := range rows {
		kin := deref(f.NextOfKinName)
		if kin != "" {
			kin += " (" + deref(f.NextOfKinRelationship) + ") " + deref(f.NextOfKinPhone)
		}
		t.Rows = append(t.Rows, []any{f.MembershipNumber, f.FullName(), title(deref(f.Gender)), f.Phone, deref(f.Location),
			payoutTo(f), strings.TrimSpace(kin), title(f.Status), f.CreatedAt})
		counts[f.Status]++
	}
	in.doc.Figures = []document.Figure{
		{Label: "Farmers", Value: count(len(rows))}, {Label: "Active", Value: count(counts["ACTIVE"])},
		{Label: "Inactive", Value: count(counts["INACTIVE"])}, {Label: "Suspended", Value: count(counts["SUSPENDED"])},
	}
	in.doc.Tables = []document.Table{t}
	return nil
}

// statementDetails describes a statement line in words; the litres and
// amounts have their own columns.
func statementDetails(kind customer.EntryKind, description string, debit, credit float64) string {
	if kind == customer.EntrySale {
		switch {
		case credit >= debit && debit > 0:
			return "Milk sale, paid at sale"
		case credit > 0:
			return "Milk sale, part paid at sale"
		}
		return "Milk sale"
	}
	return strings.NewReplacer("(MPESA)", "(M-Pesa)", "(BANK_TRANSFER)", "(bank transfer)", "(CASH)", "(cash)", "(CHEQUE)", "(cheque)").Replace(description)
}

// title writes an UPPER_CASE value as a word: "MORNING" -> "Morning".
func title(s string) string {
	s = strings.ReplaceAll(strings.ToLower(s), "_", " ")
	if s == "" {
		return s
	}
	return strings.ToUpper(s[:1]) + s[1:]
}

func abs(v float64) float64 {
	if v < 0 {
		return -v
	}
	return v
}
