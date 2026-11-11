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
| | Farmers' accounts (each deduction) | where its money goes: its income account, Share capital (savings), or Owed to *supplier* |
| | Farmers' accounts (net pay) | Farmers' pay due |
| Farmers' pay sent (one journal per batch marked paid) | Farmers' pay due | cash |
| Other income | cash | the income category's account |
| Bill | the expense category's account | Suppliers |
| Bill paid (each payment) | Suppliers | cash |
| Money held for a supplier paid over | Owed to *supplier* | cash |
| Opening shares | Opening balances | the savings' account (Share capital) |
| Shares refunded | the savings' account | cash |
| Shares passed to another member | nothing: both members' shares are in the same account | |
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
| 2100 | Suppliers | Liability | yes: bills not yet paid |
| 2201… | Owed to *supplier*, one per supplier a deduction pays over to | Liability | yes: money held, not yet paid over |
| 2500 | Loans | Liability | |
| 3000 | Share capital (every savings deduction starts here) | Equity | |
| 3200 | Retained surplus | Equity | |
| 3900 | Opening balances | Equity | |
| 4000 | Milk sales | Income | |
| 4101… | one per deduction the Sacco keeps (fees) | Income | |
| 4200 | Charges to farmers | Income | |
| 4301… | one per income category (other income) | Income | |
| 5000 | Milk bought from farmers | Expense | |
| 5100 | Adjustments to farmers' accounts | Expense | |
| 6001… | one per expense category | Expense | |

A new cash account, category, deduction or payee gets its own account the
first time it is needed.

### Where records post (`/books/links`)

What a record posts to is data (`ledger_links`, keys like
`cash_account:<id>`, `expense_category:<id>`, `income_category:<id>`,
`deduction_type:<id>` (a deduction the Sacco keeps), `savings:<id>` (a savings
deduction), `payee:<supplier id>`, `role:CUSTOMERS`). The accountant points one
at another account of an allowed kind: cash accounts at assets; expense
categories at expenses or assets (a cooler bought is an asset); income
categories and kept deductions at income; savings at equity or liability;
payees at liabilities (payees may share one, like cash accounts). A change applies **from now on**; entries already
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

## Statements (phase 3)

Worked out from the journals alone, so they always agree with the trial
balance (`statements.go`).

- `GET /books/income-statement?from=&to=`: each income and expense account's
  movement in the period, totals and the surplus (negative: deficit),
  beside the period of the same length before it: whole months when the
  period starts on the 1st (a month, a quarter, a financial year), else the
  same number of days.
- `GET /books/balance-sheet?date=&previous=`: assets, liabilities and equity
  at the end of the day, beside another day (default the end of the last
  financial year), and whether assets equal liabilities plus equity. Until
  years are closed (phase 5), income and expenses stay in their accounts, so
  equity shows two lines for them: **Surplus this financial year** and
  **Surplus of earlier years (not yet closed)** since the books started.
  What was made before the start is already in Retained surplus.

The income statement's surplus equals the income and expenditure
(`/finance/summary`) for a month whose pay run is approved; they differ when
it isn't, because the books count milk bought when its pay run is approved,
and the income and expenditure counts it day by day.

## Downloads (phase 3)

On the report downloads list (`/sacco/exports`, `books.read`):

| Report | Period | Formats |
| :--- | :--- | :--- |
| Income Statement | a period, beside the one before | PDF, Excel |
| Balance Sheet | at the end of the period, beside its start | PDF, Excel |
| Trial Balance | at the end of the period | PDF, Excel, CSV |
| General Ledger | every account's entries, opening and closing | PDF, Excel, CSV |
| Journals | every journal line: date, journal, source, memo, reference, account code and name, debit, credit, line note | Excel, CSV, PDF |
| Chart of Accounts | today | PDF, Excel, CSV |

The CSV and Excel journal and ledger files are what the Sacco's own
accounting software imports: one row per debit or credit, plain dates
(2026-10-31) and amounts (1460.00) in CSV. The catalog lists each report's
`formats` (none listed: PDF and Excel) and `at_end` for reports that show a
day; older apps ignore both and keep PDF and Excel. Before the books start,
these downloads say to start them.

## Phase 4: the money flows the books could not see

Records added in phase 4 (migration `00032`; the records themselves are in
[finance.md](finance.md) and [payouts.md](payouts.md)):

- **Other income** posts like an expense the other way round.
- **Bills**: spending on the bill's date (accrual), owed to Suppliers until
  paid; each payment (in parts if need be) is its own journal. Suppliers is
  kept from records: the check compares it with the bills not yet paid.
- **Where a deduction's money goes** (`deduction_types.goes_to`): `INCOME`
  (the Sacco's), `SAVINGS` (the farmer's shares) or `PAYEE` (owed to a
  supplier, with `payee_id`). Each deduction taken in a pay run keeps its
  payee in `member_transactions.payee_id`, so changing the deduction later
  never moves money already taken: the pay run's journal is worked out from
  what each deduction said when it was taken. Money held posts to **Owed to
  *supplier*** (2201…), kept from records: the check compares it with what
  pay runs took for them less what was paid over.
- **Shares** moved outside pay runs (`share_entries`): opening shares (Dr
  Opening balances), refunds (from a cash account) and transfers between
  members (no journal).
- **The accountant's opening balances** (`ledger_opening_lines`, `GET/PUT
  /books/opening`): one debit or credit per balance sheet account no record
  keeps (fixed assets, loans, money owed from before DairyGo). They go into
  the opening journal, with Opening balances taking the other side. Accounts
  kept from records are refused: their opening comes from the records dated
  before the start (bills, opening shares, cash accounts' opening balances,
  customers' and farmers' records).

## Phase 5: months, years and the bank

**Closing months** (`ledger_books.closed_through`, `/books/periods`): the
accountant closes the books through the end of a month that is over. The
books are brought up to date first and must balance and agree with the
records, or closing is refused. Afterwards nothing is dated on or before that
day, so a closed month's statements never change:

- a manual journal there is refused; reversing one is dated on the first open
  day;
- staff keep recording as before. A record dated in a closed month that is
  added, changed or voided later posts its journal (or reversal) on the
  **first open day**, its memo saying "(for 12 Sep 2026, in a closed month)".
  The comparison matches a closed month's records to their journals by
  amounts only, so this never repeats (`matches` in `sync.go`);
- the start of the books cannot move while any month is closed.

**Reopening** moves the closed date back (any earlier month end, or nothing
closed) with a reason; every close, reopen and year end is kept in
`ledger_period_events`, shown under Months and years.

**Year end** (`POST /books/periods/year-end`, the year's last day): years
close in order. After the same checks, one journal on the year's last day
(`source_type` `year_end`) moves every income and expense account's balance to
Retained surplus, and the year's months are closed. The income statement
leaves year-end journals out, so a closed year's statement still shows the
year; the trial balance and balance sheet on and after the year's last day
show the position after closing (income and expenses empty, the surplus in
Retained surplus). Corrections to a closed year's records land in the next
year. Reopening a month of a closed year reverses its year-end journal on its
own date; closing the year again posts a new one.

**Bank reconciliation** is in [finance.md](finance.md#bank-reconciliation).

## Permissions

`books.read` (admin, accountant) to look; `books.manage` (admin, accountant)
to start the books, bring them up to date, change the chart and where
records post, and make or reverse journals. Granted in migration `00030`.

## App

The accountant's bar is Home · Money · Pay · **Books** · More (Customers is
on More and on the Home). Admins open Books from More. Screens: Books (the
check, start, bring up to date, move the start), Trial balance, Journals,
a journal (reverse your own), New journal, Chart of accounts (add, change),
an account's ledger, Where records post, Opening balances (add, change or
remove your own), Months and years (close, reopen, the year end, history),
Income statement (says when the period is closed) (a month or a financial year), Balance
sheet, and Download.

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
- `~/.dairygo/localtest/flows.sh` (115 checks, after reset and setup): phase
  4. A deduction for an insurer lands as owed, not income, and paying it over
  clears it; changing the deduction afterwards moves nothing; other income;
  a bill paid in parts, overpaying refused, a payment voided; the income
  statement equals the income and expenditure for October; opening shares
  typed and imported (console), counting towards the shares target; a refund
  and a transfer, and voiding them; the accountant's opening balances; the
  links; the books balance and agree with the records after each step.
- `~/.dairygo/localtest/periods.sh` (71 checks, after reset and setup):
  closing, what may be dated where, a voided and a late record in a closed
  month posting on the first open day with September's surplus unchanged and
  no churn on bringing up to date, reopening with a reason, the year end
  (surplus to retained, the year's statement unchanged, income and expenses
  empty after, reopening reverses it), then a bank statement: preview,
  import, matched straight away, imported twice, the leftovers both ways,
  balances, candidates, matching, unmatching, the cashbook ticks, removing.
- `~/.dairygo/localtest/statements.sh` (45 checks, after books.sh): the
  income statement against the sales records, the income and expenditure and
  the trial balance; the balance sheet balances on several days and with
  another financial year; every download in each format, CSV columns,
  journals CSV has every line and balances, the general ledger's bank
  closing equals the cashbook; refusals.
- `flutter test test/layout/books_test.dart`: every books screen at 320 dp
  with 2× text and at 412 dp, and what each action sends.
