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
