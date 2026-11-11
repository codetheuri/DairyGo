package superadmin

import (
	"context"
	"encoding/base64"
	"errors"
	"strings"
	"time"

	"github.com/danielgtaylor/huma/v2"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/internal/payout"
	"github.com/codetheuri/tusk/pkg/response"
)

// Opening shares from a spreadsheet: the shares each farmer held before
// DairyGo, by membership number (see payout/shares_import.go). The console
// checks the file first (preview) and then imports it.

type ImportSharesInput struct {
	ID   string `path:"id" doc:"Sacco UUID"`
	Body struct {
		File            string `json:"file" doc:"The spreadsheet as a data: URL or base64 (Excel .xlsx or CSV)"`
		Date            string `json:"date" doc:"The day the shares were held, YYYY-MM-DD; usually the day before the books start"`
		DeductionTypeID string `json:"deduction_type_id,omitempty" doc:"The savings deduction they count towards, when the Sacco has more than one"`
		Preview         bool   `json:"preview,omitempty" doc:"Only check the file and say what would be imported"`
	}
}

type ImportSharesResult struct {
	payout.ShareImport
	Preview  bool     `json:"preview"`
	Problems []string `json:"problems"`
}

type ImportSharesOutput struct {
	Body response.Data[ImportSharesResult]
}

// ImportShares checks or imports a spreadsheet of opening shares.
func (h *MoneyHandler) ImportShares(ctx context.Context, in *ImportSharesInput) (*ImportSharesOutput, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, huma.Error403Forbidden("Platform operators only")
	}
	raw := in.Body.File
	if i := strings.Index(raw, ","); strings.HasPrefix(raw, "data:") && i > 0 {
		raw = raw[i+1:]
	}
	data, err := base64.StdEncoding.DecodeString(raw)
	if err != nil || len(data) == 0 {
		return nil, huma.Error400BadRequest("Attach the spreadsheet (Excel or CSV)")
	}
	if len(data) > 5<<20 {
		return nil, huma.Error400BadRequest("The file must be under 5 MB")
	}
	day, err := time.Parse("2006-01-02", strings.TrimSpace(in.Body.Date))
	if err != nil {
		return nil, huma.Error400BadRequest("Give the date the shares were held, like 2026-09-30")
	}
	if day.After(time.Now()) {
		return nil, huma.Error400BadRequest("The date cannot be in the future")
	}
	rows, problems := payout.ParseShareRows(data)
	out := &ImportSharesOutput{}
	out.Body.Success = true
	res := &out.Body.Data
	res.Preview, res.Problems = in.Body.Preview || len(problems) > 0, problems
	if res.Problems == nil {
		res.Problems = []string{}
	}
	actor := middleware.GetUserID(ctx)
	imp, err := payout.ImportOpeningShares(ctx, h.db, in.ID, rows, day, in.Body.DeductionTypeID, &actor, res.Preview)
	if err != nil {
		if errors.Is(err, payout.ErrInvalid) {
			msg := strings.TrimPrefix(err.Error(), "invalid: ")
			return nil, huma.Error400BadRequest(strings.ToUpper(msg[:1]) + msg[1:])
		}
		return nil, huma.Error500InternalServerError("Could not import the shares", err)
	}
	res.ShareImport = *imp
	switch {
	case len(problems) > 0:
		out.Body.Message = "Fix the file first; nothing was imported"
	case res.Preview:
		out.Body.Message = "Nothing saved yet"
	default:
		out.Body.Message = "Opening shares imported"
	}
	return out, nil
}
