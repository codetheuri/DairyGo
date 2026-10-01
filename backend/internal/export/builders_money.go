package export

import (
	"context"
	"fmt"

	"github.com/codetheuri/tusk/pkg/document"
)

// Reports on farmers' deductions and balances, and the Sacco's own money.

func deductions(ctx context.Context, s *Service, in *input) error {
	totals, farmers, err := s.repo.Deductions(ctx, in.saccoID, in.from, in.to)
	if err != nil {
		return err
	}
	sum := document.Table{Title: "By deduction",
		Columns: []document.Column{col("Deduction", txt, 2.5), col("Kind", txt, 1.2), col("Farmers", cnt, 1), col("Amount", money, 1.5)},
		Empty:   "Nothing was taken from farmers' pay in this period."}
	total, savings := 0.0, 0.0
	for _, d := range totals {
		kind := "Income"
		if d.IsSavings {
			kind, savings = "Savings", savings+d.Amount
		}
		sum.Rows = append(sum.Rows, []any{d.Name, kind, d.Farmers, d.Amount})
		total += d.Amount
	}
	if len(totals) > 0 {
		sum.Totals = []any{"Total", nil, nil, total}
	}
	each := document.Table{Title: "By farmer",
		Columns: []document.Column{col("No.", txt, 0.7), col("Farmer", txt, 2.2), col("Deduction", txt, 2.2), col("Amount", money, 1.3)},
		Empty:   "None."}
	for _, f := range farmers {
		each.Rows = append(each.Rows, []any{f.MembershipNumber, f.FarmerName, f.Name, f.Amount})
	}
	in.doc.Figures = []document.Figure{{Label: "Taken from farmers", Value: kes(total)}, {Label: "Of which savings", Value: kes(savings)}}
	in.doc.Tables = []document.Table{sum, each}
	in.doc.Notes = []string{"Deductions are dated on the last day of the pay run that took them. Savings (shares) belong to the farmers; the rest is the Sacco's income."}
	return nil
}

func farmerBalances(ctx context.Context, s *Service, in *input) error {
	rows, err := s.repo.FarmerBalances(ctx, in.saccoID)
	if err != nil {
		return err
	}
	t := document.Table{
		Columns: []document.Column{col("No.", txt, 0.7), col("Farmer", txt, 2.2), col("Phone", txt, 1.2),
			col("Advances to recover", money, 1.3), col("Balance", money, 1.3), col("Shares", money, 1.2)},
		Empty: "No farmer owes or is owed anything, and nobody has shares yet.",
	}
	owe, owed, shares := 0.0, 0.0, 0.0
	for _, r := range rows {
		t.Rows = append(t.Rows, []any{r.MembershipNumber, r.FarmerName, r.Phone, r.OpenAdvances, r.Balance, r.Shares})
		if r.Balance < 0 {
			owe -= r.Balance
		} else {
			owed += r.Balance
		}
		shares += r.Shares
	}
	if len(rows) > 0 {
		t.Totals = []any{fmt.Sprintf("%d farmers", len(rows)), nil, nil, nil, nil, shares}
	}
	in.doc.Figures = []document.Figure{{Label: "Farmers owe the Sacco", Value: kes(owe)}, {Label: "Sacco owes farmers", Value: kes(owed)}, {Label: "Shares held", Value: kes(shares)}}
	in.doc.Tables = []document.Table{t}
	in.doc.Notes = []string{"A negative balance is what the farmer owes (advances, charges, arrears), recovered from their next pay. A positive balance is pay owed to them."}
	return nil
}

func incomeExpenditure(ctx context.Context, s *Service, in *input) error {
	sum, err := s.finance.Summary(ctx, in.from.Format(dateLayout), in.to.Format(dateLayout))
	if err != nil {
		return err
	}
	two := []document.Column{col("", txt, 3), col("KES", money, 1.4)}
	income := document.Table{Title: "Income", Columns: two}
	income.Rows = append(income.Rows, []any{"Milk sales", sum.MilkSales})
	for _, f := range sum.Fees {
		income.Rows = append(income.Rows, []any{f.Name, f.Amount})
	}
	if sum.FarmerCharges != 0 {
		income.Rows = append(income.Rows, []any{"Charges to farmers (feeds, services)", sum.FarmerCharges})
	}
	totalIn := sum.MilkSales + sum.FeesTotal + sum.FarmerCharges
	income.Totals = []any{"Total income", totalIn}

	spend := document.Table{Title: "Expenditure", Columns: two}
	spend.Rows = append(spend.Rows, []any{"Milk bought from farmers", sum.MilkPurchases})
	for _, e := range sum.Expenses {
		spend.Rows = append(spend.Rows, []any{e.Name, e.Amount})
	}
	spend.Totals = []any{"Total expenditure", sum.MilkPurchases + sum.ExpensesTotal}

	label := "Surplus"
	if sum.Surplus < 0 {
		label = "Deficit"
	}
	position := document.Table{Title: "Position today", Columns: two, Rows: [][]any{
		{"Cash in all accounts", sum.Cash},
		{"Customers owe the Sacco", sum.Receivables},
		{"Farmers owe the Sacco (advances, charges, arrears)", sum.FarmersOwe},
		{"Farmers' pay approved, not yet sent", sum.FarmerPayDue},
		{"Farmers' shares (all time)", sum.ShareCapital},
	}}
	in.doc.Figures = []document.Figure{{Label: "Income", Value: kes(totalIn)}, {Label: "Expenditure", Value: kes(sum.MilkPurchases + sum.ExpensesTotal)}, {Label: label, Value: kes(sum.Surplus)}}
	in.doc.Tables = []document.Table{income, spend, position}
	for _, sh := range sum.SharesRaised {
		in.doc.Notes = append(in.doc.Notes, fmt.Sprintf("%s raised in the period: %s (savings, not income).", sh.Name, kes(sh.Amount)))
	}
	in.doc.Notes = append(in.doc.Notes, "Advances are not income or expenditure: they are recovered from farmers' pay.")
	return nil
}

func expenses(ctx context.Context, s *Service, in *input) error {
	list, err := s.finance.ExpensesFor(ctx, in.from, in.to)
	if err != nil {
		return err
	}
	t := document.Table{
		Columns: []document.Column{col("Date", day, 1), col("Category", txt, 1.6), col("Payee", txt, 1.8), col("Account", txt, 1.3),
			col("Reference", txt, 1.1), col("Details", txt, 2), col("Amount", money, 1.2)},
		Empty: "No expenses in this period.",
	}
	for _, e := range list.Expenses {
		t.Rows = append(t.Rows, []any{e.ExpenseDate, e.CategoryName, e.Payee, e.AccountName, deref(e.Reference), deref(e.Description), e.Amount})
	}
	if len(list.Expenses) > 0 {
		t.Totals = []any{"Total", nil, nil, nil, nil, nil, list.Total}
	}
	by := document.Table{Title: "By category", Columns: []document.Column{col("Category", txt, 3), col("Amount", money, 1.4)}}
	for _, c := range list.ByCategory {
		by.Rows = append(by.Rows, []any{c.Name, c.Amount})
	}
	in.doc.Figures = []document.Figure{{Label: "Total spent", Value: kes(list.Total)}, {Label: "Expenses", Value: count(len(list.Expenses))}}
	in.doc.Tables = []document.Table{t}
	if len(by.Rows) > 0 {
		by.Totals = []any{"Total", list.Total}
		in.doc.Tables = append(in.doc.Tables, by)
	}
	return nil
}

func cashbooks(ctx context.Context, s *Service, in *input) error {
	accounts, total, err := s.finance.Accounts(ctx)
	if err != nil {
		return err
	}
	figures := []document.Figure{{Label: "All accounts now", Value: kes(total)}}
	for _, a := range accounts {
		if !a.IsActive {
			continue
		}
		cb, err := s.finance.Cashbook(ctx, a.ID, in.from.Format(dateLayout), in.to.Format(dateLayout))
		if err != nil {
			return err
		}
		t := document.Table{Title: a.Name,
			Columns: []document.Column{col("Date", day, 1), col("Details", txt, 3), col("Reference", txt, 1.2),
				col("In", money, 1.2), col("Out", money, 1.2), col("Balance", money, 1.3)}}
		t.Rows = append(t.Rows, []any{in.from, "Opening balance", nil, nil, nil, cb.OpeningBalance})
		for _, l := range cb.Lines {
			var inV, outV any
			if l.In != 0 {
				inV = l.In
			}
			if l.Out != 0 {
				outV = l.Out
			}
			t.Rows = append(t.Rows, []any{l.Date, l.Description, deref(l.Reference), inV, outV, l.Balance})
		}
		t.Totals = []any{"Closing balance", nil, nil, cb.TotalIn, cb.TotalOut, cb.ClosingBalance}
		in.doc.Tables = append(in.doc.Tables, t)
		if len(figures) < 4 {
			figures = append(figures, document.Figure{Label: a.Name, Value: kes(cb.ClosingBalance)})
		}
	}
	if len(in.doc.Tables) == 0 {
		in.doc.Tables = []document.Table{{Columns: []document.Column{col("", txt, 1)}, Empty: "No accounts yet. Add petty cash, bank and M-Pesa accounts in Expenses."}}
	}
	in.doc.Figures = figures
	return nil
}
