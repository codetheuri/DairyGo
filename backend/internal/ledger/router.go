package ledger

import (
	"net/http"

	"github.com/danielgtaylor/huma/v2"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/config"
	"github.com/codetheuri/tusk/pkg/authz"
	"github.com/codetheuri/tusk/pkg/logger"
)

const tag = "Books"

// The books' permissions (registered by the finance module, migration
// 00030): books.read to look, books.manage to start the books, change the
// chart and where records post, and make or reverse journals.
const (
	PermRead   = "books.read"
	PermManage = "books.manage"
)

// RegisterRoutes wires the books' endpoints.
func RegisterRoutes(api huma.API, db *gorm.DB, _ *config.Config, log logger.Logger) {
	h := NewHandler(NewService(db), log)
	guard := authz.NewGuard(api, db)
	op := func(id, method, path, summary, desc string) huma.Operation {
		return huma.Operation{OperationID: id, Method: method, Path: "/api/v1/sacco/books" + path, Summary: summary, Description: desc, Tags: []string{tag}}
	}

	huma.Register(api, guard.Protected(op("books-status", http.MethodGet, "", "The books",
		"Whether the books have started, and whether they agree with the records: customers, farmers' accounts, pay due and each cash account."), PermRead), h.Status)
	huma.Register(api, guard.Protected(op("books-start", http.MethodPost, "/start", "Start the books, or move their start",
		"Makes the chart of accounts, posts every record from the start date and sums everything before it into one opening journal. Moving the start rebuilds the journals from records; give a reason."), PermManage), h.Start)
	huma.Register(api, guard.Protected(op("books-bring-up-to-date", http.MethodPost, "/sync", "Bring the books up to date",
		"Compares every record with the books now (the nightly check does the same) and posts what is missing."), PermManage), h.BringUpToDate)

	huma.Register(api, guard.Protected(op("books-accounts", http.MethodGet, "/accounts", "Chart of accounts",
		"Every account by code with its balance now."), PermRead), h.Accounts)
	huma.Register(api, guard.Protected(op("books-create-account", http.MethodPost, "/accounts", "Add an account", ""), PermManage), h.CreateAccount)
	huma.Register(api, guard.Protected(op("books-update-account", http.MethodPut, "/accounts/{id}", "Change an account",
		"Code, name, description, switched on or off; what it records only while nothing has posted to it."), PermManage), h.UpdateAccount)
	huma.Register(api, guard.Protected(op("books-account-ledger", http.MethodGet, "/accounts/{id}/ledger", "Account ledger",
		"An account's entries over a period with the running balance."), PermRead), h.AccountLedger)

	huma.Register(api, guard.Protected(op("books-links", http.MethodGet, "/links", "Where records post",
		"Each cash account, expense category and deduction, and the accounts records use by role, with the account each posts to."), PermRead), h.Links)
	huma.Register(api, guard.Protected(op("books-set-link", http.MethodPut, "/links", "Change where records post",
		"From now on; journals already posted stay where they are."), PermManage), h.SetLink)

	huma.Register(api, guard.Protected(op("books-journals", http.MethodGet, "/journals", "Journals",
		"Over a period, newest first."), PermRead), h.Journals)
	huma.Register(api, guard.Protected(op("books-journal", http.MethodGet, "/journals/{id}", "A journal", "With its lines."), PermRead), h.Journal)
	huma.Register(api, guard.Protected(op("books-create-journal", http.MethodPost, "/journals", "Make a journal",
		"The accountant's own: balanced, dated from the start of the books to today, not on accounts kept from records."), PermManage), h.CreateJournal)
	huma.Register(api, guard.Protected(op("books-reverse-journal", http.MethodPost, "/journals/{id}/reverse", "Reverse a journal",
		"Only the accountant's own; a record's journal is reversed by voiding or correcting the record."), PermManage), h.ReverseJournal)

	huma.Register(api, guard.Protected(op("books-trial-balance", http.MethodGet, "/trial-balance", "Trial balance",
		"Each account's balance at the end of a day, debits and credits in their columns."), PermRead), h.TrialBalance)
}
