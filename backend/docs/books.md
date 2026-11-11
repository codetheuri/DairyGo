# The books: a double-entry ledger kept from the records

Phase 2 of the accountant's work (phase 1, the accountant and accounts on
every payment, is in [finance.md](finance.md)). Package `internal/ledger`,
migration `00031`, routes under `/api/v1/sacco/books`.

The Sacco's staff keep recording what they already record: sales, customer
payments, expenses, transfers, advances, charges, adjustments, pay runs and
payments of farmers' pay. Each of those posts a **balanced journal** by itself,
in the same transaction as the record. The accountant reads the books (trial
balance, journals, account ledgers), adds their own journals for anything the
records don't cover, and decides which account each kind of record posts to.

## What each record posts

| Record | Debit | Credit |
| :--- | :--- | :--- |
| Milk sale | Customers (unpaid part), cash (paid part) | Milk sales |
| Customer payment | cash | Customers |
| Expense | the category's account | cash |
| Money moved between accounts | cash (to) | cash (from) |
| Advance | Farmers' accounts | cash |
| Charge (feeds, AI…) | Farmers' accounts | Charges to farmers |
| Adjustment in the farmer's favour | Adjustments to farmers' accounts | Farmers' accounts |
| Pay run approved | Milk bought from farmers | Farmers' accounts |
| | Farmers' accounts (each deduction) | the deduction's account |
| | Farmers' accounts (net pay) | Farmers' pay due |
| Farmers' pay sent (one journal per batch marked paid) | Farmers' pay due | cash |
| Cash account opened | the cash account | Opening balances |

"Cash" is the account the money went through (phase 1 makes every payment
name one). With none named it is **Money not in an account** (1099); dated
before the account's opening date it is **Opening balances**, because the
opening balance already holds it, just as the cashbook counts nothing before
that date.

Milk is bought in the books when its pay run is approved, dated on the run's
last day, not day by day. Unpaid milk between pay runs is not in the books.

The rules are plain functions of each record (`rules.go`, tested in
`rules_test.go` without a database); `sources.go` reads the records.

## How the books follow the records

Every money record is saved with an **audit entry** in the same transaction.
`ledger.Install` (called once in `app.New`) adds a hook to `pkg/audit`: after
each entry for a money record (`milk_sale`, `customer_payment`, `expense`,
`account_transfer`, `member_transaction`, `pay_run`, `cash_account`) the
ledger brings that record's journals up to date. So every screen, console
tool and batch (late entries, customer repricing, cancelling a pay run) is
covered without calling the ledger itself.

Bringing a record up to date (`sync.go`): the rules say which journals it
should have; they are compared with the journals it has (same day, same
amount per link; wording doesn't matter). A difference reverses the old
journal and posts the new one. **Journals are never edited or deleted.** A
voided expense gets a reversal; an edited sale gets a reversal and a new
journal; a cancelled pay run's journal is reversed.

Recording money **never fails because of the books**: the hook posts under a
savepoint, and if posting fails the record is still saved and the failure is
logged. The same comparison run over every record (`SyncAll`) posts whatever
is missing. It runs:

- when the books start (or their start moves);
- nightly, as the background job **check-books** (console → Background jobs);
- when the accountant taps **Bring up to date** (`POST /books/sync`).

A Sacco whose books have not started posts nothing; the hook only looks up
`ledger_books` and stops.

## Starting the books

`POST /books/start {start_date}` (books.manage). The chart is made, every
record from that day posts its journal, and everything dated before it is
summed into **one opening journal** on the start date: balance-sheet accounts
keep their balances, and income and expenses before then go to **Retained
surplus** (3200). A record from before the start that changes later (a late
payment, a voided old sale) re-works the opening journal the same way:
reversal and a new one.

Moving the start (`start_date` plus a `reason`) rebuilds the journals from
records; the accountant's own journals stay, so none may be dated before the
new start. With no journals of their own left, numbering starts again from 1.

## The chart of accounts

Every chart starts with these, editable (code, name, description, switched
off); what an account records can change only while nothing has posted to it,
and an account is never deleted.

| Code | Account | Kind | Kept from records |
| :--- | :--- | :--- | :--- |
| 1001… | one per cash account (by opening order) | Asset | the account's cashbook |
| 1099 | Money not in an account | Asset | yes |
| 1200 | Customers | Asset | yes |
| 1300 | Farmers' accounts | Asset | yes |
| 1500 | Fixed assets | Asset | |
| 2000 | Farmers' pay due | Liability | yes |
| 2100 | Suppliers | Liability | |
| 2200 | Loans | Liability | |
| 3001… | one per savings deduction (shares) | Equity | |
| 3200 | Retained surplus | Equity | |
| 3900 | Opening balances | Equity | |
| 4000 | Milk sales | Income | |
| 4101… | one per other deduction (fees) | Income | |
| 4200 | Charges to farmers | Income | |
| 4300 | Other income | Income | |
| 5000 | Milk bought from farmers | Expense | |
| 5100 | Adjustments to farmers' accounts | Expense | |
| 6001… | one per expense category | Expense | |

A new cash account, category or deduction gets its own account the first
time it is needed.

### Where records post (`/books/links`)

What a record posts to is data (`ledger_links`, keys like
`cash_account:<id>`, `expense_category:<id>`, `deduction_type:<id>`,
`role:CUSTOMERS`). The accountant points one at another account of an allowed
kind: cash accounts at assets; expense categories at expenses or assets (a
cooler bought is an asset); deductions at income, equity or liability (money
held for someone else). A change applies **from now on**; entries already
posted stay where they are (journal lines remember their link, so the
comparison is not upset). Moving an old balance is a manual journal.

## Kept from records, and the check

Customers, Farmers' accounts, Farmers' pay due, Money not in an account and
every cash account follow their records. **Manual journals cannot use them**,
and no other kind of record may point at them, so their balances always equal
what the rest of DairyGo shows:

| Account | Records |
| :--- | :--- |
| Customers | sales (total − paid at sale) − payments, not voided |
| Farmers' accounts | − the sum of farmers' account entries, not voided |
| Farmers' pay due | net pay of approved runs' farmers not yet paid |
| each cash account | its cashbook balance (opening + movements) |

`GET /books` returns this check (`controls`, `agrees`) and whether debits
equal credits (`balanced`). The app shows it on Books and on the accountant's
Home; a difference means a journal is missing, and **Bring up to date** fixes
it.

## Manual journals and reversing

`POST /books/journals` (books.manage): a date from the start of the books to
today, what it is for, 2–50 lines each a debit or a credit, equal totals, on
active accounts not kept from records. `POST /books/journals/{id}/reverse`
with a reason takes back the accountant's own journal (once; dated on its
own day unless another is given). A record's journal is taken back by
voiding or correcting the record.

## Reports

- `GET /books/trial-balance?date=`: each account's balance at the end of a
  day, debits and credits in their columns, totals and `balanced`.
- `GET /books/accounts/{id}/ledger?from=&to=`: an account's entries with the
  running balance, positive in the account's usual direction (debits for
  assets and expenses, credits otherwise).
- `GET /books/journals?from=&to=&kind=&account_id=&search=&page=`: newest
  first; search by number (`J-12`) or words in the memo or reference.
- `GET /books/accounts`: the chart with each balance now.

Statements (income statement, balance sheet) and exports are phase 3.

## Permissions

`books.read` (admin, accountant) to look; `books.manage` (admin, accountant)
to start the books, bring them up to date, change the chart and where
records post, and make or reverse journals. Granted in migration `00030`.

## App

The accountant's bar is Home · Money · Pay · **Books** · More (Customers is
on More and on the Home). Admins open Books from More. Screens: Books (the
check, start, bring up to date, move the start), Trial balance, Journals,
a journal (reverse your own), New journal, Chart of accounts (add, change),
an account's ledger, Where records post.

## Testing

- `go test ./internal/ledger/`: every rule balances, voided records post
  nothing, cash before an account's opening date, pay runs and payment
  batches, the opening journal, the comparison.
- `~/.dairygo/localtest/books.sh` (91 checks): history before the start
  becomes the opening journal with the right balances; later records post by
  themselves (staff, console late entries, edits, voids, pay run approve,
  cancel, pay); the chart and links; manual journals and reversals; trial
  balance; account ledger equals the cashbook; a record before the start
  re-works the opening; a deleted journal is found and posted again; the
  nightly job; a cash account's opening date moving; moving the start.
- `~/.dairygo/localtest/books_with.sh <script>`: runs any other scenario with
  the books started first, then checks the books agree with the records and
  nothing was missed (done for payouts, finance, custprices, saccoprice,
  merge, late, reassign, lateadvance, paymethod and accountant).
- `flutter test test/layout/books_test.dart`: every books screen at 320 dp
  with 2× text and at 412 dp, and what each action sends.
