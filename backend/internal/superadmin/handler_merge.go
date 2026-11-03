package superadmin

import (
	"context"
	"errors"
	"strings"

	"github.com/danielgtaylor/huma/v2"

	"github.com/codetheuri/tusk/internal/payout"
	"github.com/codetheuri/tusk/pkg/response"
)

// One farmer registered twice (see payout/merge.go): the console merges the
// farmer recorded under the wrong name into the right one.

type MergeFarmersInput struct {
	ID   string `path:"id" doc:"Sacco UUID"`
	Body payout.MergeRequest
}

type MergeFarmersOutput struct {
	Body response.Data[payout.MergeResult]
}

// MergeFarmers previews or carries out the merge.
func (h *MoneyHandler) MergeFarmers(ctx context.Context, in *MergeFarmersInput) (*MergeFarmersOutput, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, huma.Error403Forbidden("Platform operators only")
	}
	res, err := h.payouts.MergeFarmers(inSacco(ctx, in.ID), &in.Body)
	if err != nil {
		msg := err.Error()
		if i := strings.Index(msg, ": "); i > 0 {
			msg = msg[i+2:]
		}
		msg = strings.ToUpper(msg[:1]) + msg[1:]
		switch {
		case errors.Is(err, payout.ErrForbidden):
			return nil, huma.Error403Forbidden(msg)
		case errors.Is(err, payout.ErrNotFound):
			return nil, huma.Error404NotFound(msg)
		case errors.Is(err, payout.ErrInvalid):
			return nil, huma.Error400BadRequest(msg)
		}
		return nil, huma.Error500InternalServerError("Could not merge the farmers", err)
	}
	out := &MergeFarmersOutput{}
	out.Body.Success, out.Body.Data = true, *res
	out.Body.Message = "Merged into " + res.To
	if res.Preview {
		out.Body.Message = "Nothing saved yet"
	}
	return out, nil
}
