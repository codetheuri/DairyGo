package finance

import "context"

// --- other income ---

func (h *Handler) IncomeCategories(ctx context.Context, _ *struct{}) (*Out[FinIncomeCategoriesData], error) {
	list, err := h.service.IncomeCategoryList(ctx)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Income categories", FinIncomeCategoriesData{list}), nil
}

func (h *Handler) CreateIncomeCategory(ctx context.Context, in *FinCreateIncomeCategoryInput) (*Out[FinIncomeCategoryData], error) {
	c, err := h.service.SaveIncomeCategory(ctx, "", &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Category added", FinIncomeCategoryData{c}), nil
}

func (h *Handler) UpdateIncomeCategory(ctx context.Context, in *FinUpdateIncomeCategoryInput) (*Out[FinIncomeCategoryData], error) {
	c, err := h.service.SaveIncomeCategory(ctx, in.ID, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Category saved", FinIncomeCategoryData{c}), nil
}

func (h *Handler) OtherIncome(ctx context.Context, in *FinListIncomeInput) (*Out[IncomeList], error) {
	list, err := h.service.OtherIncomeList(ctx, in)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Other income", *list), nil
}

func (h *Handler) RecordIncome(ctx context.Context, in *FinRecordIncomeInput) (*Out[FinIncomeData], error) {
	i, err := h.service.RecordIncome(ctx, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Income recorded", FinIncomeData{i}), nil
}

func (h *Handler) VoidIncome(ctx context.Context, in *FinVoidInput) (*Out[FinIncomeData], error) {
	i, err := h.service.VoidIncome(ctx, in.ID, in.Body.Reason)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Income voided", FinIncomeData{i}), nil
}

// --- suppliers ---

func (h *Handler) Suppliers(ctx context.Context, _ *struct{}) (*Out[SupplierList], error) {
	list, err := h.service.Suppliers(ctx)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Suppliers", *list), nil
}

func (h *Handler) SupplierDetail(ctx context.Context, in *FinSupplierIDInput) (*Out[SupplierDetail], error) {
	d, err := h.service.SupplierDetail(ctx, in.ID)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Supplier", *d), nil
}

func (h *Handler) CreateSupplier(ctx context.Context, in *FinCreateSupplierInput) (*Out[FinSupplierData], error) {
	sp, err := h.service.SaveSupplier(ctx, "", &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Supplier added", FinSupplierData{sp}), nil
}

func (h *Handler) UpdateSupplier(ctx context.Context, in *FinUpdateSupplierInput) (*Out[FinSupplierData], error) {
	sp, err := h.service.SaveSupplier(ctx, in.ID, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Supplier saved", FinSupplierData{sp}), nil
}

func (h *Handler) UnpaidBills(ctx context.Context, _ *struct{}) (*Out[FinBillsData], error) {
	bills, err := h.service.UnpaidBills(ctx)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	total := 0.0
	for _, b := range bills {
		total += b.Unpaid
	}
	return ok("Bills to pay", FinBillsData{bills, round2(total)}), nil
}

func (h *Handler) RecordBill(ctx context.Context, in *FinRecordBillInput) (*Out[FinBillData], error) {
	b, err := h.service.RecordBill(ctx, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Bill recorded", FinBillData{b}), nil
}

func (h *Handler) VoidBill(ctx context.Context, in *FinVoidInput) (*Out[FinBillData], error) {
	b, err := h.service.VoidBill(ctx, in.ID, in.Body.Reason)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Bill voided", FinBillData{b}), nil
}

func (h *Handler) PayBill(ctx context.Context, in *FinPayBillInput) (*Out[FinSupplierPaymentData], error) {
	p, err := h.service.PayBill(ctx, in.ID, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Payment recorded", FinSupplierPaymentData{p}), nil
}

func (h *Handler) PayOver(ctx context.Context, in *FinPayOverInput) (*Out[FinSupplierPaymentData], error) {
	p, err := h.service.PayOver(ctx, in.ID, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Paid over", FinSupplierPaymentData{p}), nil
}

func (h *Handler) VoidSupplierPayment(ctx context.Context, in *FinVoidInput) (*Out[FinSupplierPaymentData], error) {
	p, err := h.service.VoidSupplierPayment(ctx, in.ID, in.Body.Reason)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Payment voided", FinSupplierPaymentData{p}), nil
}

// --- bank reconciliation ---

func (h *Handler) Statements(ctx context.Context, in *FinAccountIDInput) (*Out[FinStatementsData], error) {
	list, err := h.service.Statements(ctx, in.ID)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Statements", FinStatementsData{list}), nil
}

func (h *Handler) ImportStatement(ctx context.Context, in *FinImportStatementInput) (*Out[StatementImport], error) {
	imp, err := h.service.ImportStatement(ctx, in.ID, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	msg := "Statement imported"
	switch {
	case len(imp.Problems) > 0:
		msg = "Fix the file first; nothing was imported"
	case imp.Preview:
		msg = "Nothing saved yet"
	case imp.Statement == nil:
		msg = "Every line was imported already"
	}
	return ok(msg, *imp), nil
}

func (h *Handler) Reconcile(ctx context.Context, in *FinStatementIDInput) (*Out[FinReconciliationData], error) {
	r, err := h.service.Reconcile(ctx, in.ID)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Reconciliation", FinReconciliationData{r}), nil
}

func (h *Handler) DeleteStatement(ctx context.Context, in *FinStatementIDInput) (*Out[FinAutoMatchData], error) {
	if err := h.service.DeleteStatement(ctx, in.ID); err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Statement removed", FinAutoMatchData{}), nil
}

func (h *Handler) AutoMatch(ctx context.Context, in *FinStatementIDInput) (*Out[FinAutoMatchData], error) {
	n, err := h.service.AutoMatch(ctx, in.ID)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Matched", FinAutoMatchData{n}), nil
}

func (h *Handler) Candidates(ctx context.Context, in *FinLineIDInput) (*Out[FinCandidatesData], error) {
	list, err := h.service.Candidates(ctx, in.ID)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Movements it may match", FinCandidatesData{list}), nil
}

func (h *Handler) Match(ctx context.Context, in *FinMatchInput) (*Out[FinLineData], error) {
	l, err := h.service.Match(ctx, in.ID, in.Body.MatchKey)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Matched", FinLineData{l}), nil
}

func (h *Handler) Unmatch(ctx context.Context, in *FinLineIDInput) (*Out[FinLineData], error) {
	l, err := h.service.Unmatch(ctx, in.ID)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return ok("Unmatched", FinLineData{l}), nil
}
