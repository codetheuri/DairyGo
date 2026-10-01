package payout

import (
	"net/http"

	"github.com/danielgtaylor/huma/v2"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/config"
	"github.com/codetheuri/tusk/internal/letterhead"
	"github.com/codetheuri/tusk/pkg/authz"
	"github.com/codetheuri/tusk/pkg/logger"
)

const tag = "Farmer Payouts"

// RegisterRoutes wires the payout module's endpoints.
func RegisterRoutes(api huma.API, db *gorm.DB, cfg *config.Config, log logger.Logger) {
	handler := NewHandler(NewService(NewRepository(db), letterhead.New(db)), log)
	guard := authz.NewGuard(api, db)

	// Deductions
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-deduction-types", Method: http.MethodGet, Path: "/api/v1/sacco/deduction-types",
		Summary: "List deductions", Tags: []string{tag},
		Description: "The Sacco's deductions (shares, fees, subscriptions, transaction cost…) in the order they are taken.",
	}, PermRead), handler.ListTypes)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "create-deduction-type", Method: http.MethodPost, Path: "/api/v1/sacco/deduction-types",
		Summary: "Add a deduction", Tags: []string{tag},
		Description: "A new rule for what is taken from farmers' pay: a FIXED amount, a PERCENT, KES PER_LITRE or TIERED fee bands, taken EVERY_RUN, ONCE_PER_MEMBER, ONCE_PER_YEAR or UNTIL_TARGET.",
	}, PermDeductionsManage), handler.CreateType)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "update-deduction-type", Method: http.MethodPut, Path: "/api/v1/sacco/deduction-types/{id}",
		Summary: "Change a deduction", Tags: []string{tag},
		Description: "Only the fields sent change. Changes apply from the next pay run.",
	}, PermDeductionsManage), handler.UpdateType)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "delete-deduction-type", Method: http.MethodDelete, Path: "/api/v1/sacco/deduction-types/{id}",
		Summary: "Delete a deduction", Tags: []string{tag},
		Description: "Only a deduction never taken from anyone; otherwise switch it off (409).",
	}, PermDeductionsManage), handler.DeleteType)

	// A farmer's deductions and account
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "farmer-deductions", Method: http.MethodGet, Path: "/api/v1/sacco/members/{member_id}/deductions",
		Summary: "A farmer's deductions", Tags: []string{tag},
		Description: "Every deduction, whether this farmer pays it, their amount or target, and how much was taken so far.",
	}, PermRead), handler.FarmerDeductions)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "set-farmer-deduction", Method: http.MethodPut, Path: "/api/v1/sacco/members/{member_id}/deductions/{type_id}",
		Summary: "Set a deduction for a farmer", Tags: []string{tag},
		Description: "Add the farmer to a deduction, exempt them, or give them their own amount or target (e.g. a loan).",
	}, PermDeductionsManage), handler.SetFarmerDeduction)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "farmer-account", Method: http.MethodGet, Path: "/api/v1/sacco/members/{member_id}/account",
		Summary: "A farmer's account", Tags: []string{tag},
		Description: "Statement with a running balance (what the Sacco owes the farmer; negative = the farmer owes), plus the balance now, share balance and advances to recover.",
	}, PermRead), handler.Account)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "farmer-advance-info", Method: http.MethodGet, Path: "/api/v1/sacco/members/{member_id}/advance",
		Summary: "Before giving an advance", Tags: []string{tag},
		Description: "Milk delivered since the last pay run, advances already taken, and how much more the farmer may take.",
	}, PermAdvancesManage), handler.AdvanceInfo)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "record-advance", Method: http.MethodPost, Path: "/api/v1/sacco/members/{member_id}/advances",
		Summary: "Give an advance", Tags: []string{tag},
		Description: "Money paid to a farmer before pay day; recovered at the next pay run. Refused above the Sacco's limit per period.",
	}, PermAdvancesManage), handler.RecordAdvance)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "record-charge", Method: http.MethodPost, Path: "/api/v1/sacco/members/{member_id}/charges",
		Summary: "Record a charge", Tags: []string{tag},
		Description: "Something the farmer owes (feeds, AI or vet service, an item on credit); taken at the next pay run.",
	}, PermChargesManage), handler.RecordCharge)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "record-adjustment", Method: http.MethodPost, Path: "/api/v1/sacco/members/{member_id}/adjustments",
		Summary: "Adjust a farmer's account", Tags: []string{tag},
		Description: "A correction with a reason: positive adds to what the farmer is owed, negative takes off it.",
	}, PermChargesManage), handler.RecordAdjustment)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "void-account-entry", Method: http.MethodPost, Path: "/api/v1/sacco/account-entries/{id}/void",
		Summary: "Void an advance, charge or adjustment", Tags: []string{tag},
		Description: "Only before a pay run has settled it (409 after; record an adjustment instead).",
	}, PermChargesManage), handler.VoidEntry)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-advances", Method: http.MethodGet, Path: "/api/v1/sacco/advances",
		Summary: "Advances", Tags: []string{tag},
	}, PermRead), handler.ListAdvances)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-charges", Method: http.MethodGet, Path: "/api/v1/sacco/charges",
		Summary: "Charges", Tags: []string{tag},
	}, PermRead), handler.ListCharges)

	// Pay runs
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-pay-runs", Method: http.MethodGet, Path: "/api/v1/sacco/pay-runs",
		Summary: "Pay runs", Tags: []string{tag},
		Description: "Newest first, with the period the next run should cover.",
	}, PermRead), handler.ListRuns)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "create-pay-run", Method: http.MethodPost, Path: "/api/v1/sacco/pay-runs",
		Summary: "Start a pay run", Tags: []string{tag},
		Description: "Works out every farmer's pay for the period as a draft. Nothing is written to accounts until it is approved. One draft at a time; a run starts the day after the last paid period.",
	}, PermRunsManage), handler.CreateRun)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-pay-run", Method: http.MethodGet, Path: "/api/v1/sacco/pay-runs/{id}",
		Summary: "A pay run", Tags: []string{tag},
	}, PermRead), handler.GetRun)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "recompute-pay-run", Method: http.MethodPost, Path: "/api/v1/sacco/pay-runs/{id}/recompute",
		Summary: "Work a draft out again", Tags: []string{tag},
	}, PermRunsManage), handler.RecomputeRun)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "approve-pay-run", Method: http.MethodPost, Path: "/api/v1/sacco/pay-runs/{id}/approve",
		Summary: "Approve a pay run", Tags: []string{tag},
		Description: "Writes every farmer's milk, deductions and net pay to their accounts and closes the period: milk records dated in it can no longer change. Refused (409) if the figures changed since expected_total_net.",
	}, PermRunsApprove), handler.ApproveRun)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "cancel-pay-run", Method: http.MethodPost, Path: "/api/v1/sacco/pay-runs/{id}/cancel",
		Summary: "Discard or cancel a pay run", Tags: []string{tag},
		Description: "Discards a draft, or undoes the latest approved run if nobody has been marked paid (reason required); the period reopens.",
	}, PermRunsManage), handler.CancelRun)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "pay-pay-run", Method: http.MethodPost, Path: "/api/v1/sacco/pay-runs/{id}/pay",
		Summary: "Mark farmers paid", Tags: []string{tag},
		Description: "The listed farmers, or everyone not yet paid, with how and the reference. The run is PAID once everyone is.",
	}, PermRunsPay), handler.Pay)

	// Files and payslips
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "pay-run-payment-file", Method: http.MethodGet, Path: "/api/v1/sacco/pay-runs/{id}/payment-file",
		Summary: "Payment list (Excel)", Tags: []string{tag},
		Description: "Farmers still to be paid in an approved run: kind=mpesa (phone 2547…, amount, name) for an M-Pesa bulk payment, or kind=bank (bank, account, name, amount). Farmers without the details are listed separately.",
	}, PermRunsPay), handler.PaymentFile)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "pay-run-register", Method: http.MethodGet, Path: "/api/v1/sacco/pay-runs/{id}/register",
		Summary: "Pay run register (PDF or Excel)", Tags: []string{tag},
		Description: "Every farmer's milk, each deduction as a column, advances and charges, net pay, balances and how they were paid.",
	}, PermRead), handler.Register)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "pay-run-payslip", Method: http.MethodGet, Path: "/api/v1/sacco/pay-runs/{id}/payslips/{member_id}",
		Summary: "A farmer's payslip (PDF)", Tags: []string{tag},
	}, PermRead), handler.Payslip)
}
