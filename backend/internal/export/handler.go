package export

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/danielgtaylor/huma/v2"

	"github.com/codetheuri/tusk/internal/customer"
	"github.com/codetheuri/tusk/pkg/logger"
	"github.com/codetheuri/tusk/pkg/response"
)

// Handler serves the report list and the report files.
type Handler struct {
	service *Service
	log     logger.Logger
}

// NewHandler creates the export handler.
func NewHandler(service *Service, log logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

type CatalogData struct {
	Reports []Report `json:"reports"`
	// MaxDays is the longest period one report may cover.
	MaxDays int `json:"max_days"`
}

type CatalogOutput struct {
	Body response.Data[CatalogData]
}

// Catalog lists the reports the caller may download.
func (h *Handler) Catalog(ctx context.Context, _ *struct{}) (*CatalogOutput, error) {
	out := &CatalogOutput{}
	out.Body.Success, out.Body.Message = true, "Reports you can download"
	out.Body.Data.Reports = h.service.Catalog(ctx)
	if out.Body.Data.Reports == nil {
		out.Body.Data.Reports = []Report{}
	}
	out.Body.Data.MaxDays = MaxDays
	return out, nil
}

type ExportInput struct {
	Report      string `path:"report" doc:"Report key from GET /sacco/exports, e.g. farmer-payouts"`
	Format      string `query:"format" enum:"pdf,xlsx" default:"pdf" doc:"pdf or xlsx (Excel)"`
	From        string `query:"from" doc:"First day, YYYY-MM-DD (default: the 1st of this month)"`
	To          string `query:"to" doc:"Last day, YYYY-MM-DD (default: today)"`
	MemberID    string `query:"member_id" doc:"The farmer, for farmer-statement"`
	CustomerID  string `query:"customer_id" doc:"The customer, for customer-statement"`
	CollectorID uint   `query:"collector_id" doc:"Only this collector's records (reports with a collector filter)"`
	Shift       string `query:"shift" enum:"MORNING,EVENING," doc:"Only this shift (collections)"`
	Status      string `query:"status" enum:"ACTIVE,INACTIVE,SUSPENDED," doc:"Only farmers of this status (farmer-register)"`
}

// ExportOutput is the file itself.
type ExportOutput struct {
	ContentType        string `header:"Content-Type"`
	ContentDisposition string `header:"Content-Disposition"`
	CacheControl       string `header:"Cache-Control"`
	Body               []byte
}

// Export builds a report and returns it as a file.
func (h *Handler) Export(ctx context.Context, in *ExportInput) (*ExportOutput, error) {
	file, err := h.service.Build(ctx, Request{
		Report: in.Report, Format: Format(strings.ToLower(in.Format)), From: in.From, To: in.To,
		MemberID: in.MemberID, CustomerID: in.CustomerID, CollectorID: in.CollectorID,
		Shift: in.Shift, Status: in.Status,
	})
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return &ExportOutput{
		ContentType:        file.ContentType,
		ContentDisposition: fmt.Sprintf(`attachment; filename="%s"`, file.Name),
		// Reports hold personal and money details: never kept by caches.
		CacheControl: "no-store",
		Body:         file.Data,
	}, nil
}

func (h *Handler) toHTTPError(err error) error {
	switch {
	case errors.Is(err, ErrUnknownReport), errors.Is(err, errNotFound), errors.Is(err, customer.ErrNotFound):
		return huma.Error404NotFound(sentence(err))
	case errors.Is(err, ErrForbidden):
		return huma.Error403Forbidden(sentence(err))
	case errors.Is(err, ErrInvalid):
		return huma.Error400BadRequest(sentence(err))
	default:
		h.log.Error("Failed to build a report", err)
		return huma.Error500InternalServerError("The report could not be made. Please try again.")
	}
}

// sentence drops the "invalid request: " style prefix and capitalises.
func sentence(err error) string {
	msg := err.Error()
	for _, kind := range []error{ErrUnknownReport, ErrForbidden, ErrInvalid, errNotFound, customer.ErrNotFound} {
		msg = strings.TrimPrefix(msg, kind.Error()+": ")
	}
	if msg == "" {
		return msg
	}
	return strings.ToUpper(msg[:1]) + msg[1:]
}
