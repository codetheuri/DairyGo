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

## Expenses

`expenses`: date, category, account, amount, payee, reference, details.
Voided with a reason, never deleted. `expense_categories` are data; every
Sacco starts with salaries and wages, petty cash spending, transport and
fuel, rent, electricity and water, repairs, stationery, bank and M-Pesa
charges, meetings and AGM, and other. Salaries are recorded as expenses;
there is no PAYE/NSSF calculation.

## Income and expenditure (`GET /sacco/finance/summary`)

For a period (default this month):

```
income   = milk sales + fees kept from farmers' pay + charges to farmers
spending = milk bought from farmers + expenses
surplus  = income − spending (negative = deficit)
```

Shares raised are listed apart: they are the farmers' savings, not income.
Advances are neither. Where the Sacco stands now: cash in all accounts,
what customers owe (only those who owe; one in credit does not hide
others), farmers' pay approved but not sent, what farmers owe, share
capital.

Reports in the download catalog: **Income and Expenditure**, **Expenses**,
**Cashbooks** (a sheet per account in Excel).

## Permissions

`finance.read` (admin, board), `finance.expenses.manage` and
`finance.accounts.manage` (admin).

## Testing

`go test ./internal/finance/`; `~/.dairygo/localtest/finance.sh` (54 checks).
