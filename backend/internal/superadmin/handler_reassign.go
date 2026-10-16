package superadmin

import (
	"context"
	"errors"
	"time"

	"github.com/danielgtaylor/huma/v2"

	"github.com/codetheuri/tusk/internal/collection"
	"github.com/codetheuri/tusk/pkg/response"
)

// Records saved on the wrong collector's account (see
// collection/reassign.go): the console lists one account's day and moves
// the chosen records to the collector who made them.

type CollectorDayInput struct {
	ID          string `path:"id" doc:"Sacco UUID"`
	CollectorID uint   `query:"collector_id" doc:"The account to list; empty lists only the collectors"`
	Date        string `query:"date" doc:"The day, YYYY-MM-DD (default today)"`
}

type CollectorDayData struct {
	Records    []collection.DayRecord         `json:"records"`
	Collectors []collection.TransferRecipient `json:"collectors"`
}

type CollectorDayOutput struct {
	Body response.Data[CollectorDayData]
}

type ReassignInput struct {
	ID   string `path:"id" doc:"Sacco UUID"`
	Body collection.ReassignRequest
}

type ReassignOutput struct {
	Body response.Data[collection.ReassignResult]
}

// CollectorDay lists what an account saved on a day, and the collectors the
// records can move to.
func (h *LateHandler) CollectorDay(ctx context.Context, in *CollectorDayInput) (*CollectorDayOutput, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, huma.Error403Forbidden("Platform operators only")
	}
	day, err := time.Now(), error(nil)
	if in.Date != "" {
		if day, err = time.Parse("2006-01-02", in.Date); err != nil {
			return nil, huma.Error400BadRequest("date must be YYYY-MM-DD")
		}
	}
	ctx = inSacco(ctx, in.ID)
	out := &CollectorDayOutput{}
	out.Body.Data.Records = []collection.DayRecord{}
	if in.CollectorID != 0 {
		if out.Body.Data.Records, err = h.milk.CollectorDay(ctx, in.CollectorID, day); err != nil {
			return nil, huma.Error500InternalServerError("Could not load the day's records", err)
		}
	}
	if out.Body.Data.Collectors, err = h.milk.Collectors(ctx); err != nil {
		return nil, huma.Error500InternalServerError("Could not load collectors", err)
	}
	out.Body.Success, out.Body.Message = true, "Records"
	return out, nil
}

// Reassign moves the chosen records to the collector who made them.
func (h *LateHandler) Reassign(ctx context.Context, in *ReassignInput) (*ReassignOutput, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, huma.Error403Forbidden("Platform operators only")
	}
	res, err := h.milk.Reassign(inSacco(ctx, in.ID), &in.Body)
	switch {
	case errors.Is(err, collection.ErrForbidden):
		return nil, huma.Error403Forbidden(err.Error())
	case errors.Is(err, collection.ErrNotFound):
		return nil, huma.Error404NotFound(err.Error())
	case err != nil:
		return nil, huma.Error400BadRequest(err.Error())
	}
	out := &ReassignOutput{}
	out.Body.Success, out.Body.Data = true, *res
	out.Body.Message = "Records moved to " + res.To
	return out, nil
}
