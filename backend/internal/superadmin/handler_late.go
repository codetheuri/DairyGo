package superadmin

import (
	"context"
	"errors"
	"strings"

	"github.com/danielgtaylor/huma/v2"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/collection"
	"github.com/codetheuri/tusk/internal/customer"
	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/response"
)

// LateHandler lets platform operators enter milk records and payments for an earlier day
// or unrecorded events, which Sacco staff cannot do (they record only today). Each entry
// runs the Sacco's own rules on its behalf, needs a reason, and is marked as entered late.
type LateHandler struct {
	milk      *collection.Service
	customers *customer.Service
	db        *gorm.DB
}

type LateCollectionInput struct {
	ID   string `path:"id" doc:"Sacco UUID"`
	Body collection.RecordCollectionRequest
}

type LateSaleInput struct {
	ID   string `path:"id" doc:"Sacco UUID"`
	Body collection.RecordSaleRequest
}

type LateSpoilageInput struct {
	ID   string `path:"id" doc:"Sacco UUID"`
	Body collection.RecordSpoilageRequest
}

type LateTransferInput struct {
	ID   string `path:"id" doc:"Sacco UUID"`
	Body collection.RecordTransferRequest
}

type LatePaymentRequest struct {
	CustomerID    string  `json:"customer_id" required:"true" doc:"Customer UUID"`
	Amount        float64 `json:"amount" required:"true" minimum:"0.01" doc:"Amount received (KES)"`
	PaymentDate   string  `json:"payment_date" required:"true" doc:"YYYY-MM-DD date received"`
	Method        string  `json:"method" required:"true" enum:"CASH,MPESA,BANK_TRANSFER,CHEQUE" doc:"Payment method"`
	Reference     *string `json:"reference,omitempty" doc:"Transaction reference e.g. M-Pesa code"`
	CollectorID   *uint   `json:"collector_id,omitempty" doc:"Collector or staff who received the payment (optional)"`
	CashAccountID *string `json:"cash_account_id,omitempty" doc:"Sacco cash account ID (optional)"`
	LateReason    string  `json:"late_reason" required:"true" doc:"Why the payment is being entered late / was unrecorded"`
	Notes         *string `json:"notes,omitempty" doc:"Optional notes"`
}

type LatePaymentInput struct {
	ID   string `path:"id" doc:"Sacco UUID"`
	Body LatePaymentRequest
}

type LateSaved struct {
	Record any `json:"record"`
}

type LateSavedOutput struct {
	Body response.Data[LateSaved]
}

// LateRecordsData is a Sacco's late entries and what the console's forms
// choose from: its collectors, active customers and cash accounts.
type LateRecordsData struct {
	Records    []collection.LateRecord        `json:"records"`
	Collectors []collection.TransferRecipient `json:"collectors"`
	Customers  []LateCustomer                 `json:"customers"`
	Accounts   []LateAccount                  `json:"accounts"`
}

// LateCustomer is a customer a late sale or payment can be recorded for.
type LateCustomer struct {
	ID                   string   `json:"id"`
	Name                 string   `json:"name"`
	CustomerType         string   `json:"customer_type"`
	DefaultPricePerLitre *float64 `json:"default_price_per_litre,omitempty"`
}

// LateAccount is a Sacco cash account a payment can be deposited into.
type LateAccount struct {
	ID            string `json:"id"`
	Name          string `json:"name"`
	Kind          string `json:"kind"`
	AccountNumber string `json:"account_number,omitempty"`
}

type LateRecordsOutput struct {
	Body response.Data[LateRecordsData]
}

// Records lists a Sacco's late entries, its collectors and customers.
func (h *LateHandler) Records(ctx context.Context, in *SaccoIDInput) (*LateRecordsOutput, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, huma.Error403Forbidden("Platform operators only")
	}
	ctx = inSacco(ctx, in.ID)
	out := &LateRecordsOutput{}
	var err error
	if out.Body.Data.Records, err = h.milk.LateRecords(ctx); err != nil {
		return nil, huma.Error500InternalServerError("Could not load late entries", err)
	}
	if out.Body.Data.Collectors, err = h.milk.Collectors(ctx); err != nil {
		return nil, huma.Error500InternalServerError("Could not load collectors", err)
	}
	if err = h.db.WithContext(ctx).Table("customers").
		Select("id, name, customer_type, default_price_per_litre").
		Where("sacco_id = ? AND status = ? AND deleted_at IS NULL", in.ID, "ACTIVE").
		Order("name").Scan(&out.Body.Data.Customers).Error; err != nil {
		return nil, huma.Error500InternalServerError("Could not load customers", err)
	}
	out.Body.Data.Accounts = []LateAccount{}
	_ = h.db.WithContext(ctx).Table("cash_accounts").
		Select("id, name, kind, account_number").
		Where("sacco_id = ? AND is_active = ?", in.ID, true).
		Order("name").Scan(&out.Body.Data.Accounts).Error
	out.Body.Success, out.Body.Message = true, "Late entries"
	return out, nil
}

func (h *LateHandler) Collection(ctx context.Context, in *LateCollectionInput) (*LateSavedOutput, error) {
	return h.save(ctx, in.ID, "Milk intake entered late", func(ctx context.Context) (any, error) {
		return h.milk.RecordCollection(ctx, &in.Body)
	})
}

func (h *LateHandler) Sale(ctx context.Context, in *LateSaleInput) (*LateSavedOutput, error) {
	return h.save(ctx, in.ID, "Sale entered late", func(ctx context.Context) (any, error) {
		return h.milk.RecordSale(ctx, &in.Body)
	})
}

func (h *LateHandler) Spoilage(ctx context.Context, in *LateSpoilageInput) (*LateSavedOutput, error) {
	return h.save(ctx, in.ID, "Spoilage entered late", func(ctx context.Context) (any, error) {
		return h.milk.RecordSpoilage(ctx, &in.Body)
	})
}

func (h *LateHandler) Transfer(ctx context.Context, in *LateTransferInput) (*LateSavedOutput, error) {
	return h.save(ctx, in.ID, "Transfer entered late", func(ctx context.Context) (any, error) {
		return h.milk.RecordTransfer(ctx, &in.Body)
	})
}

func (h *LateHandler) Payment(ctx context.Context, in *LatePaymentInput) (*LateSavedOutput, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, huma.Error403Forbidden("Platform operators only")
	}
	why := strings.TrimSpace(in.Body.LateReason)
	if len(why) < 3 {
		return nil, huma.Error400BadRequest("say why the payment is being entered late (reason)")
	}
	ctx = inSacco(ctx, in.ID)
	operatorID := middleware.GetUserID(ctx)
	req := &customer.RecordPaymentRequest{
		Amount:        in.Body.Amount,
		PaymentDate:   &in.Body.PaymentDate,
		Method:        &in.Body.Method,
		Reference:     in.Body.Reference,
		CashAccountID: in.Body.CashAccountID,
		Notes:         in.Body.Notes,
		RecordedByID:  in.Body.CollectorID,
		EnteredByID:   &operatorID,
		LateReason:    &why,
	}
	p, err := h.customers.RecordPayment(ctx, in.Body.CustomerID, req)
	if err != nil {
		return nil, huma.Error400BadRequest(err.Error())
	}
	out := &LateSavedOutput{}
	out.Body.Success, out.Body.Message, out.Body.Data.Record = true, "Payment entered", p
	return out, nil
}

// save runs record for the Sacco and maps the milk rules' errors.
func (h *LateHandler) save(ctx context.Context, saccoID, msg string, record func(context.Context) (any, error)) (*LateSavedOutput, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, huma.Error403Forbidden("Platform operators only")
	}
	rec, err := record(inSacco(ctx, saccoID))
	switch {
	case errors.Is(err, collection.ErrForbidden):
		return nil, huma.Error403Forbidden(err.Error())
	case errors.Is(err, collection.ErrNotFound):
		return nil, huma.Error404NotFound(err.Error())
	case errors.Is(err, collection.ErrLocked):
		return nil, huma.Error409Conflict(err.Error())
	case err != nil:
		return nil, huma.Error400BadRequest(err.Error())
	}
	out := &LateSavedOutput{}
	out.Body.Success, out.Body.Message, out.Body.Data.Record = true, msg, rec
	return out, nil
}
