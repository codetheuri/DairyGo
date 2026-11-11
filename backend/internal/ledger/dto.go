package ledger

import "github.com/codetheuri/tusk/pkg/response"

type BooksStatusData struct {
	Books *BooksStatus `json:"books"`
	Made  int          `json:"journals_made" doc:"Journals this request made (starting, or bringing up to date)"`
}

type BooksStatusOutput struct {
	Body response.Data[BooksStatusData]
}

type BooksStartInput struct {
	Body StartRequest
}

type LedgerAccountsData struct {
	Accounts []LedgerAccount `json:"accounts"`
}

type LedgerAccountsOutput struct {
	Body response.Data[LedgerAccountsData]
}

type LedgerAccountData struct {
	Account *LedgerAccount `json:"account"`
}

type LedgerAccountOutput struct {
	Body response.Data[LedgerAccountData]
}

type LedgerCreateAccountInput struct {
	Body AccountRequest
}

type LedgerUpdateAccountInput struct {
	ID   string `path:"id"`
	Body AccountRequest
}

type BooksLinksData struct {
	Links []LinkRow `json:"links"`
}

type BooksLinksOutput struct {
	Body response.Data[BooksLinksData]
}

type BooksSetLinkInput struct {
	Body SetLinkRequest
}

type JournalsInput struct {
	From      string `query:"from" doc:"YYYY-MM-DD (default the 1st of this month)"`
	To        string `query:"to" doc:"YYYY-MM-DD (default today)"`
	Kind      string `query:"kind" enum:"AUTO,MANUAL," doc:"AUTO (from records), MANUAL, or empty for both"`
	AccountID string `query:"account_id"`
	Search    string `query:"search" doc:"A journal number (J-12) or words in the memo or reference"`
	Page      int    `query:"page" minimum:"0"`
	Limit     int    `query:"limit" minimum:"0" maximum:"200"`
}

type JournalsData struct {
	JournalList
}

type JournalsOutput struct {
	Body response.Data[JournalsData]
}

type JournalData struct {
	Journal *Journal `json:"journal"`
}

type JournalOutput struct {
	Body response.Data[JournalData]
}

type JournalIDInput struct {
	ID string `path:"id"`
}

type JournalCreateInput struct {
	Body JournalRequest
}

type JournalReverseInput struct {
	ID   string `path:"id"`
	Body ReverseRequest
}

type TrialBalanceInput struct {
	Date string `query:"date" doc:"YYYY-MM-DD (default today): balances at the end of the day"`
}

type TrialBalanceData struct {
	TrialBalance *TrialBalance `json:"trial_balance"`
}

type TrialBalanceOutput struct {
	Body response.Data[TrialBalanceData]
}

type AccountLedgerInput struct {
	ID   string `path:"id"`
	From string `query:"from" doc:"YYYY-MM-DD (default the 1st of this month)"`
	To   string `query:"to" doc:"YYYY-MM-DD (default today)"`
}

type AccountLedgerData struct {
	Ledger *AccountLedger `json:"ledger"`
}

type AccountLedgerOutput struct {
	Body response.Data[AccountLedgerData]
}
