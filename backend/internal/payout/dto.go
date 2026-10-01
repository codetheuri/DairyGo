package payout

import (
	"strings"

	"github.com/codetheuri/tusk/pkg/response"
)

// --- deduction types ---

// DeductionTypeRequest creates or changes a deduction. On update, only the
// fields sent change.
type DeductionTypeRequest struct {
	Name        *string  `json:"name,omitempty" doc:"e.g. Shares, Registration fee"`
	Description *string  `json:"description,omitempty"`
	Method      *string  `json:"method,omitempty" enum:"FIXED,PERCENT,PER_LITRE,TIERED" doc:"FIXED amount, PERCENT of the base, KES PER_LITRE delivered, or TIERED fee bands"`
	Base        *string  `json:"base,omitempty" enum:"GROSS,NET" doc:"What PERCENT and TIERED are worked out on: the milk value (GROSS) or the pay left after other deductions (NET, taken last)"`
	Amount      *float64 `json:"amount,omitempty" minimum:"0" doc:"KES (FIXED), percent (PERCENT) or KES per litre (PER_LITRE)"`
	Tiers       *Tiers   `json:"tiers,omitempty" doc:"TIERED: fee bands, lowest first; the last may have no up_to"`
	Frequency   *string  `json:"frequency,omitempty" enum:"EVERY_RUN,ONCE_PER_MEMBER,ONCE_PER_YEAR,UNTIL_TARGET" doc:"How often it is taken"`
	Target      *float64 `json:"target_amount,omitempty" minimum:"0" doc:"UNTIL_TARGET: stop once a farmer has paid this much"`
	AppliesTo   *string  `json:"applies_to,omitempty" enum:"ALL,ENROLLED" doc:"Every farmer, or only farmers added to it"`
	Priority    *int     `json:"priority,omitempty" doc:"Lower is taken first"`
	IsSavings   *bool    `json:"is_savings,omitempty" doc:"Builds the farmer's share balance; taken only from what is left, never as arrears"`
	IsActive    *bool    `json:"is_active,omitempty" doc:"Switched off deductions are not taken"`
}

func (r *DeductionTypeRequest) apply(t *DeductionType) {
	if r.Name != nil {
		t.Name = *r.Name
	}
	if r.Description != nil {
		t.Description = trimOrNil(*r.Description)
	}
	if r.Method != nil {
		t.Method = Method(strings.ToUpper(*r.Method))
	}
	if r.Base != nil {
		t.Base = Base(strings.ToUpper(*r.Base))
	}
	if r.Amount != nil {
		t.Amount = round2(*r.Amount)
	}
	if r.Tiers != nil {
		t.Tiers = *r.Tiers
	}
	if r.Frequency != nil {
		t.Frequency = Frequency(strings.ToUpper(*r.Frequency))
	}
	if r.Target != nil {
		t.Target = positiveOrNil(r.Target)
	}
	if r.AppliesTo != nil {
		t.AppliesTo = AppliesTo(strings.ToUpper(*r.AppliesTo))
	}
	if r.Priority != nil {
		t.Priority = *r.Priority
	}
	if r.IsSavings != nil {
		t.IsSavings = *r.IsSavings
	}
	if r.IsActive != nil {
		t.IsActive = *r.IsActive
	}
}

type CreateDeductionTypeInput struct {
	Body DeductionTypeRequest
}

type UpdateDeductionTypeInput struct {
	ID   string `path:"id" doc:"Deduction UUID"`
	Body DeductionTypeRequest
}

type DeductionTypeIDInput struct {
	ID string `path:"id" doc:"Deduction UUID"`
}

type DeductionTypeData struct {
	Deduction *DeductionType `json:"deduction"`
}

type DeductionTypeOutput struct {
	Body response.Data[DeductionTypeData]
}

type DeductionTypesData struct {
	Deductions []DeductionType `json:"deductions"`
}

type DeductionTypesOutput struct {
	Body response.Data[DeductionTypesData]
}

// --- a farmer's deductions ---

type MemberIDInput struct {
	MemberID string `path:"member_id" doc:"Farmer UUID"`
}

type FarmerDeductionsData struct {
	Deductions []FarmerDeduction `json:"deductions"`
}

type FarmerDeductionsOutput struct {
	Body response.Data[FarmerDeductionsData]
}

// FarmerDeductionRequest sets how a deduction applies to one farmer.
type FarmerDeductionRequest struct {
	Applies bool     `json:"applies" doc:"Whether this farmer pays it (false exempts them from a deduction for everyone)"`
	Amount  *float64 `json:"amount,omitempty" minimum:"0" doc:"This farmer's own amount; empty or 0 uses the usual one"`
	Target  *float64 `json:"target_amount,omitempty" minimum:"0" doc:"This farmer's own target (e.g. a loan); empty or 0 uses the usual one"`
	Notes   *string  `json:"notes,omitempty"`
}

type SetFarmerDeductionInput struct {
	MemberID string `path:"member_id" doc:"Farmer UUID"`
	TypeID   string `path:"type_id" doc:"Deduction UUID"`
	Body     FarmerDeductionRequest
}

type FarmerDeductionData struct {
	Setting *MemberDeduction `json:"farmer_setting"`
}

type FarmerDeductionOutput struct {
	Body response.Data[FarmerDeductionData]
}

// --- advances, charges, adjustments ---

// EntryRequest records an advance, a charge or an adjustment.
type EntryRequest struct {
	Amount        float64 `json:"amount" doc:"KES; for an adjustment, negative takes money off the farmer's account"`
	Date          string  `json:"date,omitempty" doc:"YYYY-MM-DD (default today)"`
	Description   string  `json:"description,omitempty" maxLength:"255" doc:"What it is for; required for charges and adjustments"`
	Method        string  `json:"method,omitempty" enum:"CASH,MPESA,BANK_TRANSFER,CHEQUE," doc:"How an advance was paid out"`
	Reference     string  `json:"reference,omitempty" maxLength:"100" doc:"M-Pesa or bank reference"`
	CashAccountID string  `json:"cash_account_id,omitempty" doc:"The Sacco account an advance was paid from (optional)"`
}

type RecordEntryInput struct {
	MemberID string `path:"member_id" doc:"Farmer UUID"`
	Body     EntryRequest
}

type EntryData struct {
	Entry *Transaction `json:"entry"`
}

type EntryOutput struct {
	Body response.Data[EntryData]
}

type VoidEntryInput struct {
	ID   string `path:"id" doc:"Account entry UUID"`
	Body struct {
		Reason string `json:"reason" minLength:"3" doc:"Why it is cancelled"`
	}
}

type ListEntriesInput struct {
	From     string `query:"from" doc:"YYYY-MM-DD (default three months ago)"`
	To       string `query:"to" doc:"YYYY-MM-DD (default today)"`
	OpenOnly bool   `query:"open_only" doc:"Only those the next pay run will recover"`
}

type EntriesData struct {
	Entries []EntryRow `json:"entries"`
	Total   float64    `json:"total" doc:"Sum of the listed entries that are not voided (as a positive amount for advances and charges)"`
}

type EntriesOutput struct {
	Body response.Data[EntriesData]
}

type AdvanceInfoData struct {
	Info *AdvanceInfo `json:"advance"`
}

type AdvanceInfoOutput struct {
	Body response.Data[AdvanceInfoData]
}

type AccountInput struct {
	MemberID string `path:"member_id" doc:"Farmer UUID"`
	From     string `query:"from" doc:"YYYY-MM-DD (default 1 January)"`
	To       string `query:"to" doc:"YYYY-MM-DD (default today)"`
}

type AccountData struct {
	Account *Account `json:"account"`
}

type AccountOutput struct {
	Body response.Data[AccountData]
}

// --- pay runs ---

// CreateRunRequest starts a pay run; empty dates use the next period due.
type CreateRunRequest struct {
	FromDate string `json:"from_date,omitempty" doc:"YYYY-MM-DD; default the day after the last paid period"`
	ToDate   string `json:"to_date,omitempty" doc:"YYYY-MM-DD; default the end of that month (not past today)"`
	Notes    string `json:"notes,omitempty" maxLength:"500"`
}

type CreateRunInput struct {
	Body CreateRunRequest
}

type RunIDInput struct {
	ID string `path:"id" doc:"Pay run UUID"`
}

type GetRunInput struct {
	ID         string `path:"id" doc:"Pay run UUID"`
	Search     string `query:"search" doc:"Farmer name, number or phone"`
	UnpaidOnly bool   `query:"unpaid_only" doc:"Only farmers still to be paid"`
}

type ApproveRunInput struct {
	ID   string `path:"id" doc:"Pay run UUID"`
	Body struct {
		ExpectedNet *float64 `json:"expected_total_net,omitempty" doc:"The net total the approver saw; approval is refused if the figures changed meanwhile"`
	}
}

type CancelRunInput struct {
	ID   string `path:"id" doc:"Pay run UUID"`
	Body struct {
		Reason string `json:"reason,omitempty" doc:"Required to cancel an approved run"`
	}
}

// PayRequest marks farmers as paid.
type PayRequest struct {
	LineIDs       []string `json:"line_ids,omitempty" doc:"The farmers' lines; empty marks everyone not yet paid"`
	Method        string   `json:"method" enum:"CASH,MPESA,BANK_TRANSFER,CHEQUE" doc:"How they were paid"`
	Reference     string   `json:"reference,omitempty" maxLength:"100" doc:"M-Pesa, bank or cheque reference (required unless cash)"`
	Date          string   `json:"date,omitempty" doc:"YYYY-MM-DD the money was sent (default now)"`
	CashAccountID string   `json:"cash_account_id,omitempty" doc:"The Sacco account the pay was sent from (optional)"`
}

type PayInput struct {
	ID   string `path:"id" doc:"Pay run UUID"`
	Body PayRequest
}

type RunOutput struct {
	Body response.Data[RunDetail]
}

type PeriodData struct {
	FromDate string `json:"from_date"`
	ToDate   string `json:"to_date"`
}

type RunsData struct {
	Runs []PayRun `json:"pay_runs"`
	// Next is the period the next pay run should cover.
	Next PeriodData `json:"next_period"`
}

type RunsOutput struct {
	Body response.Data[RunsData]
}

// Done is an empty result.
type Done struct{}

type MessageOutput struct {
	Body response.Data[Done]
}

// --- files ---

type PaymentFileInput struct {
	ID   string `path:"id" doc:"Pay run UUID"`
	Kind string `query:"kind" enum:"mpesa,bank" default:"mpesa" doc:"mpesa or bank"`
}

type RegisterInput struct {
	ID     string `path:"id" doc:"Pay run UUID"`
	Format string `query:"format" enum:"pdf,xlsx" default:"pdf" doc:"pdf or xlsx (Excel)"`
}

type PayslipInput struct {
	ID       string `path:"id" doc:"Pay run UUID"`
	MemberID string `path:"member_id" doc:"Farmer UUID"`
}

// FileOutput is a generated file.
type FileOutput struct {
	ContentType        string `header:"Content-Type"`
	ContentDisposition string `header:"Content-Disposition"`
	CacheControl       string `header:"Cache-Control"`
	Body               []byte
}

type SMSData struct {
	Queued int `json:"queued" doc:"Messages being sent"`
}

type SMSOutput struct {
	Body response.Data[SMSData]
}
