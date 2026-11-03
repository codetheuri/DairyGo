# Farmer pay: accounts, deductions, advances and pay runs

Code: `internal/payout`. Migrations `00021_farmer_accounts` and `00022_pay_runs`.
App: More → Farmer pay, and Farmer → Account.

## Every farmer has an account

`member_transactions` holds one row per money event, with a **signed** amount:
positive means the Sacco owes the farmer more. The balance is what the
Sacco owes the farmer; a negative balance is what the farmer owes.

| Kind | Amount | Written when |
| :--- | :--- | :--- |
| `ADVANCE` | − | an admin gives an advance |
| `CHARGE` | − | an admin records something the farmer owes (feeds, AI, vet) |
| `ADJUSTMENT` | ± | an admin corrects the account, with a reason |
| `MILK` | + gross | a pay run is approved |
| `DEDUCTION` | − each | a pay run is approved |
| `PAYOUT` | − net | a pay run is approved (the net pay to be sent) |

Advances, charges and adjustments have no `pay_run_id` until a pay run
settles them. Until then they can be voided (with a reason); afterwards
only an adjustment corrects them.

## Deductions are data

`deduction_types` are the Sacco's own rules, edited in the app (Farmer pay →
Deductions). A new kind of deduction is a new row, never new code.

| Field | Meaning |
| :--- | :--- |
| `method` | `FIXED` KES · `PERCENT` of the base · `PER_LITRE` KES per litre · `TIERED` fee bands (`tiers` JSON) |
| `base` | `GROSS` (milk value) or `NET` (the pay left; taken last, e.g. M-Pesa charges) |
| `frequency` | `EVERY_RUN` · `ONCE_PER_MEMBER` · `ONCE_PER_YEAR` · `UNTIL_TARGET` (`target_amount`) |
| `applies_to` | `ALL` farmers (unless exempted) or `ENROLLED` farmers only |
| `priority` | order of taking, lowest first |
| `is_savings` | builds the farmer's share balance |

`member_deductions` gives one farmer their own amount or target (a loan),
adds them to an `ENROLLED` deduction, or exempts them (`is_active = false`).

Every Sacco starts with four switched-off examples to complete: registration
fee, annual subscription, shares, transaction cost.

## Working out pay (`payout.Compute`)

A pure function, table-tested in `compute_test.go`:

```
available = opening balance + gross + advances/charges/adjustments
for each due deduction (GROSS ones by priority, then NET ones):
    fees are taken in full     → a shortfall becomes arrears
    savings take what is left  → a shortfall is not a debt
    NET costs only from money sent, skipped if they would take all of it
net pay = max(0, what is left);  carried forward = min(0, what is left)
```

Deductions apply only to farmers who delivered milk in the period.

## Pay runs

```
DRAFT ──approve──► APPROVED ──(everyone paid)──► PAID
  ├ recompute / discard          └ cancel (latest run, nobody paid yet)
```

- **Create**: the period starts the day after the last paid one (no gaps,
  so no milk is ever locked unpaid), at most 93 days, never in the future.
  One draft at a time. Every farmer with milk, a balance or open entries
  gets a line; nothing is written to accounts.
- **Approve** (`payouts.runs.approve`): in one transaction, works the run
  out again; refuses (409) if the net total differs from
  `expected_total_net` (what the approver saw); writes MILK, DEDUCTION and
  PAYOUT entries; settles the open advances and charges recorded up to that
  moment; and sets `sacco_settings.payroll_closed_through`. From then on,
  milk collections dated on or before it cannot be recorded, edited or
  re-statused (`collection.checkPeriodOpen`, 409).
- **Pay** (`payouts.runs.pay`): one farmer or everyone left, with the method,
  a reference (not for cash) and optionally the account it left from.
  Each line is paid once; a repeated tap is answered from the idempotency
  store. The run is `PAID` when every farmer with net pay is paid.
- **Cancel**: only the latest approved run, only before anyone is paid; its
  entries are removed, open items wait for the next run, the period
  reopens.

## Files

- `GET /pay-runs/{id}/payment-file?kind=mpesa|bank` (approved runs, Excel):
  the list to pay from. **The bank list is what goes to the bank**; the M-Pesa
  list is for the bulk payment. Each farmer is on exactly one list, by their
  payout method (below); farmers whose details are missing for that method are
  in a second sheet and never fall back to the other list.
- `GET /pay-runs/{id}/register?format=pdf|xlsx`, the **pay sheet** ("Farmers'
  Pay Sheet"; the app's **Pay sheet** button): every farmer, a column per
  deduction.
- `GET /pay-runs/{id}/payslips/{member_id}`: a farmer's payslip PDF.

Payslip SMS were taken out (migration `00024`) until the Sacco has SMS for
them; the payslip PDF can be shared instead.

Milk is shown by price: `ratesByFarmer` groups the period's collections by
`price_per_litre`, so a month with a price change gives the payslip one line
per price ("Milk 300 L @ KES 42"). The register's Rate column shows the price,
or gross ÷ litres marked * when there was more than one. **Brought fwd** is
the farmer's balance from earlier runs (minus = owed the Sacco); **Carried
fwd** is what they still owe after this run. Each deduction taken in a run is
its own register column, so a new deduction appears from its first run.

Reports in the download catalog: **Deductions** and **Farmer Balances**.

## How each farmer is paid

Every farmer has a payout method (`members.payout_method`, migration 00029):
**M-Pesa**, to their M-Pesa number or their phone when none is set, or
**Bank**, which needs the account number (bank name and branch optional). The
migration set Bank where a bank account was on file and M-Pesa for everyone
else; a new farmer defaults the same way unless chosen. One rule
(`pkg/payto`) decides where pay goes and what is missing, for the farmer
record, the payouts report's Pay to column and the payment lists. Pay run lines
keep the method as worked out. The app shows only the chosen method's fields
(M-Pesa | Bank) and the farmer list filters by **Paid by** (M-Pesa, Bank,
Details missing); `GET /sacco/members?paid_by=MPESA|BANK|MISSING`.

## Advance rules

Three optional settings in `sacco_settings` (app: Settings → Advance rules),
applied when an advance is recorded (`roomFor`, table-tested in
`advance_test.go`):

| Setting | Rule |
| :--- | :--- |
| `advance_max_per_period` | at most this many KES in advances between pay runs |
| `advance_from_day` | advances dated from this day of the month to its end only (e.g. 15: none from the 1st to the 14th) |
| `advance_milk_percent` | the advance may not go past this % of the milk delivered since the last pay run, plus the account balance (open advances, charges and arrears are negative). 100 = no milk, no advance |

When more than one is set, the smallest room wins. The refusal says which
rule stopped it, e.g. "Jane Muthoni can take at most KES 2,000 now: 100% of
the milk delivered (KES 3,000) less what they owe (KES 1,000)".
`GET /members/{id}/advance` shows the same figures before an advance is given.

## Permissions

| Permission | Granted to |
| :--- | :--- |
| `payouts.read` | admin, board |
| `payouts.deductions.manage`, `payouts.advances.manage`, `payouts.charges.manage`, `payouts.runs.manage`, `payouts.runs.pay` | admin |
| `payouts.runs.approve` | admin, board |

## Testing

`go test ./internal/payout/` for the rules; `~/.dairygo/localtest/payouts.sh`
(85 checks) runs the whole story on a throwaway Postgres.
