package superadmin

import (
	"context"

	"github.com/danielgtaylor/huma/v2"

	"github.com/codetheuri/tusk/internal/finance"
	"github.com/codetheuri/tusk/internal/payout"
	"github.com/codetheuri/tusk/pkg/response"
)

// MoneyHandler shows a Sacco's pay runs and money to platform operators,
// read-only, for support: the Sacco services run on the Sacco's behalf.
type MoneyHandler struct {
	payouts *payout.Service
	finance *finance.Service
}

type SaccoMoneyInput struct {
	ID   string `path:"id" doc:"Sacco UUID"`
	From string `query:"from" doc:"YYYY-MM-DD (default the 1st of this month)"`
	To   string `query:"to" doc:"YYYY-MM-DD (default today)"`
}

type SaccoMoney struct {
	PayRuns  []payout.PayRun         `json:"pay_runs"`
	Accounts []finance.CashAccount   `json:"accounts"`
	Summary  *finance.FinanceSummary `json:"summary"`
}

type SaccoMoneyOutput struct {
	Body response.Data[SaccoMoney]
}

// Money is a Sacco's pay runs, accounts and income and expenditure.
func (h *MoneyHandler) Money(ctx context.Context, in *SaccoMoneyInput) (*SaccoMoneyOutput, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, huma.Error403Forbidden("Platform operators only")
	}
	ctx = inSacco(ctx, in.ID)
	runs, err := h.payouts.ListRuns(ctx)
	if err != nil {
		return nil, huma.Error500InternalServerError("Could not load pay runs", err)
	}
	accounts, _, err := h.finance.Accounts(ctx)
	if err != nil {
		return nil, huma.Error500InternalServerError("Could not load accounts", err)
	}
	sum, err := h.finance.Summary(ctx, in.From, in.To)
	if err != nil {
		return nil, huma.Error400BadRequest(err.Error())
	}
	out := &SaccoMoneyOutput{}
	out.Body.Success, out.Body.Message = true, "Sacco money"
	out.Body.Data = SaccoMoney{PayRuns: runs, Accounts: accounts, Summary: sum}
	return out, nil
}
