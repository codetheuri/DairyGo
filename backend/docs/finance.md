# The Sacco's money: accounts, expenses and income and expenditure

Code: `internal/finance`. Migration `00023_finance`. App: More → Expenses &
money. Console: a Sacco → Pay & money (read-only).

## Accounts and the cashbook

`cash_accounts` are where the Sacco keeps money: petty cash, a bank account,
an M-Pesa till or paybill. Each has an opening balance on an opening date.

Money recorded anywhere can name the account it went through
(`cash_account_id`), so nothing is entered twice:

| In | Out |
| :--- | :--- |
| customer payments | expenses |
| cash paid at a sale | advances to farmers |
| transfers in | farmers' pay (one line per pay run and day) |
| | transfers out |

One SQL query (`movementsSQL`, a `UNION ALL` over those tables) is the only
source for an account's balance, its cashbook and the totals. The cashbook
(`buildCashbook`, unit-tested) applies movements in date order to a running
balance. Movements before the opening date are ignored. Deductions kept
from farmers' pay are not cash movements; they just reduce what is paid out.

`account_transfers` move money between accounts (a petty cash top-up from
the bank, banking cash).

### Every payment names its account

Money staff record names the account it went through, so the cashbooks are
complete. When the person recording does not choose one (an older app, a quick
sale), the server uses the Sacco's account for that way of paying
(`finance.AccountFor`): cash to its cash account, M-Pesa to its M-Pesa account,
bank transfers and cheques to its bank. With two accounts of a kind, the one
opened first is used. This covers customer payments, money paid at a sale
(including money paid later by editing the sale), advances and farmers' pay. A
Sacco with no account of that kind records the money with none rather than
refusing it; the income and expenditure counts those payments
(`not_in_account`, `not_in_account_amount`) so the accountant sees what the
cashbooks leave out.

`GET /sacco/cash-accounts/choices` lists the accounts in use (names and kinds,
no balances) and the default for each kind. It is open to anyone who records
money (`finance.read`, `customers.payments.manage`, `milk.sales.create`,
`payouts.advances.manage` or `payouts.runs.pay`). The app's picker shows the
default for the way of paying and sends an account only when another is
picked.

## Financial year

`sacco_settings.financial_year_start_month` (1 = January, migration `00030`).
`GET /sacco/financial-year` (`finance.read`, `books.read` or
`sacco.settings.read`) gives the start month and this and last financial
year's dates; `PUT /sacco/financial-year` (`books.manage`) changes it, with a
history line. It only groups dates: the app offers "Financial year" on Expenses
& Money and "This / last financial year" when downloading reports. No record
changes.

## The accountant

Role 4, **Accountant** (migration `00030`): `books.read`, `books.manage`, all
`finance.*`, farmer pay (`payouts.read`, `payouts.runs.manage`,
`payouts.runs.pay`, advances, charges; **not** `payouts.runs.approve`, so the
person who prepares a pay run is not the one who approves it), customers and
their payments, payout and ledger reports, `members.read`, `milk.prices.read`
and `sacco.settings.read`. No milk recording. Sacco admins also get
`books.read` and `books.manage`. The role's permissions stay editable in the
console like any role.

The app gives anyone who keeps the books and records no milk (`books.manage`
without `milk.collections.create`) the money layout: Home (the money position
today and this month, whether the books agree with the records, customers),
Money, Farmer pay, Books, More. It is chosen from permissions, never the
role's name. The books themselves (ledger, journals, trial balance) are in
[books.md](books.md).

## Expenses

`expenses`: date, category, account, amount, payee, reference, details.
Voided with a reason, never deleted. `expense_categories` are data; every
Sacco starts with salaries and wages, petty cash spending, transport and
fuel, rent, electricity and water, repairs, stationery, bank and M-Pesa
charges, meetings and AGM, and other. Salaries are recorded as expenses;
there is no PAYE/NSSF calculation.

## Other income

`other_income` (`/sacco/other-income`): money received besides milk sales,
into one of the Sacco's accounts, under an `income_categories` category
(every Sacco starts with interest received, rent received, sale of items,
grants and donations, and other income). Recorded and voided like an
expense; in the cashbook as money in. App: Expenses & Money → Other income.

## Suppliers and bills

`suppliers` (`/sacco/suppliers`) are who the Sacco pays, for two reasons:

- **bills** (`/sacco/bills`): bought now, paid later. A bill counts as
  spending on its date, under an expense category; `POST /bills/{id}/pay`
  pays it in full or in parts (never more than is unpaid, never before the
  bill's date). A bill with payments cannot be voided until they are.
- **money held for them**: a deduction whose money goes to a supplier
  (`goes_to: PAYEE`, see [payouts.md](payouts.md)) holds what each pay run
  takes until `POST /suppliers/{id}/pay-over` pays it (never more than is
  held).

Payments (`supplier_payments`, kind `BILL` or `PAY_OVER`) come from one of
the Sacco's accounts and show in its cashbook; voiding one makes the bill
unpaid, or the money held, again. App: the shop icon on Expenses & Money,
and Suppliers & bills on the accountant's Home: each supplier's bills, money
taken for them by pay run, and payments.

## Income and expenditure (`GET /sacco/finance/summary`)

For a period (default this month):

```
income   = milk sales + fees kept from farmers' pay + charges to farmers + other income
spending = milk bought from farmers + expenses + bills dated in the period
surplus  = income − spending (negative = deficit)
```

Shares raised are listed apart: they are the farmers' savings, not income;
so is money taken for suppliers (`held_for_others`): it is owed to them.
Advances are neither. Where the Sacco stands now: cash in all accounts,
what customers owe (only those who owe; one in credit does not hide
others), farmers' pay approved but not sent, what farmers owe, members'
shares (savings taken plus opening shares, less refunds), bills not yet paid
and money to pay over.

Reports in the download catalog: **Income and Expenditure**, **Expenses**,
**Cashbooks** (a sheet per account in Excel).

## Permissions

`finance.read` (admin, board, accountant), `finance.expenses.manage`
(expenses, other income, bills, payments to suppliers) and
`finance.accounts.manage` (accounts, expense and income categories) (admin,
accountant); suppliers may also be listed and added by whoever sets up
deductions; `books.read` and `books.manage`
(admin, accountant).

## Testing

`go test ./internal/finance/`; `~/.dairygo/localtest/finance.sh` (54 checks),
`flows.sh` (115 checks: other income, bills, paying over, shares)
and `accountant.sh` (34 checks: the role, the financial year, accounts on
every payment).
