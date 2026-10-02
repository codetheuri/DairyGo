package superadmin

import (
	"context"
	"errors"

	"github.com/danielgtaylor/huma/v2"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/collection"
	"github.com/codetheuri/tusk/pkg/response"
)

// LateHandler lets platform operators enter milk records for an earlier day,
// which Sacco staff cannot do (they record only today). Each entry runs the
// Sacco's own rules on its behalf (collection.Service), needs a reason, is
// credited to the collector the milk belongs to and marked as entered late.
type LateHandler struct {
	milk *collection.Service
	db   *gorm.DB
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

type LateSaved struct {
	Record any `json:"record"`
}

type LateSavedOutput struct {
	Body response.Data[LateSaved]
}

// LateRecordsData is a Sacco's late entries and what the console's forms
// choose from: its collectors and active customers.
type LateRecordsData struct {
	Records    []collection.LateRecord        `json:"records"`
	Collectors []collection.TransferRecipient `json:"collectors"`
	Customers  []LateCustomer                 `json:"customers"`
}

// LateCustomer is a customer a late sale can be recorded for.
type LateCustomer struct {
	ID                   string   `json:"id"`
	Name                 string   `json:"name"`
	CustomerType         string   `json:"customer_type"`
	DefaultPricePerLitre *float64 `json:"default_price_per_litre,omitempty"`
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
