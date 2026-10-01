package payout

import "github.com/codetheuri/tusk/pkg/authz"

// Payout permissions. Grants for the Sacco roles are in migration 00022.
const (
	PermRead             = "payouts.read"
	PermDeductionsManage = "payouts.deductions.manage"
	PermAdvancesManage   = "payouts.advances.manage"
	PermChargesManage    = "payouts.charges.manage"
	PermRunsManage       = "payouts.runs.manage"
	PermRunsApprove      = "payouts.runs.approve"
	PermRunsPay          = "payouts.runs.pay"
)

// Permissions exported by the payout module.
var Permissions = []authz.Permission{
	{Name: PermRead, Description: "Allows viewing pay runs, payslips and farmer accounts"},
	{Name: PermDeductionsManage, Description: "Allows setting up deductions and which farmers pay them"},
	{Name: PermAdvancesManage, Description: "Allows giving and voiding farmer advances"},
	{Name: PermChargesManage, Description: "Allows recording charges and adjustments on farmer accounts"},
	{Name: PermRunsManage, Description: "Allows preparing and cancelling pay runs"},
	{Name: PermRunsApprove, Description: "Allows approving pay runs, which closes the period"},
	{Name: PermRunsPay, Description: "Allows marking farmers as paid"},
}

func init() {
	authz.Register(Permissions...)
}
