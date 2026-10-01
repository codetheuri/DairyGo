# Report downloads (PDF and Excel)

Reports are made **on the server**. The app asks for a report, a period and
a format, and receives a finished file (usually 10–100 KB, under 1 MB for a
month of every collection). Phones do no adding up, so they stay fast on
slow connections. Making a report takes 5–250 ms.

## Reports

| Key | Report | Permission | Asks for |
| --- | --- | --- | --- |
| `farmer-payouts` | What each farmer is owed, with M-Pesa or bank details | `reports.payout.read` | period |
| `farmer-statement` | Every delivery by one farmer (to give to the farmer) | `reports.payout.read` | period, `member_id` |
| `collections` | Every intake | `milk.collections.read` | period, `collector_id`, `shift` |
| `sales` | Every sale, paid and owed | `milk.sales.read` | period, `collector_id` |
| `customer-statement` | A customer's sales, payments and running balance | `customers.statement.read` | period, `customer_id` |
| `customers-owing` | Customers who owe money, largest first | `customers.statement.read` | as at today |
| `milk-balance` | Per collector: collected, received, sold, transferred, spoiled, unaccounted | `reports.collector.read` | period, `collector_id` |
| `sacco-summary` | Day by day litres, cost of milk, sales and margin, with totals | `reports.reconciliation.read` | period |
| `farmer-register` | Farmers with contacts, payout details, next of kin | `reports.payout.read` | `status` |

- **Permissions:** each report uses the permission that already guards its
  data, so changing a role in the console changes which reports it can
  download.
- **Collectors:** anyone who sees only their own records (without
  `milk.records.read_all`) gets only their own rows, whatever
  `collector_id` they ask for.

## API

```
GET /api/v1/sacco/exports                     the reports the caller may download
GET /api/v1/sacco/exports/{key}?format=pdf|xlsx&from=YYYY-MM-DD&to=YYYY-MM-DD[&member_id=…]
```

- **Period:**
  - this month so far by default;
  - at most a year;
  - an end date after today becomes today.
- **The file comes back** with `Content-Disposition` naming it, e.g.
  `maru-dairy-farmers-society-ltd-farmer-payouts-2026-10-01-to-2026-10-31.pdf`,
  and `Cache-Control: no-store`, because reports hold personal and money
  details.
- **Errors:** a bad request says why in `message` ("Choose a farmer",
  "Choose a period of at most a year").

## Formats

- **PDF** for printing and sharing: A4, landscape for wide tables. It has:
  - the letterhead: logo, Sacco name, address, phone and email, report title and period;
  - key figures in boxes;
  - tables with column titles repeated on every page, and a bold totals row;
  - on every page, "Page X of Y", who generated it and when, and "This is a
    computer generated document. If found please return to …".
- **Excel (.xlsx)** for accounting. It has:
  - the same letterhead text and key figures;
  - one sheet per table, with frozen column titles and filters;
  - amounts and litres stored as numbers (they add up), membership numbers
    and phones as text (so "002" and "0712…" keep their leading zeros, which
    CSV would lose in Excel).

The look is defined once in `pkg/document` (`pdf.go`, `xlsx.go`). Reports
only fill in a `document.Document` (`internal/export/builders.go`).

## The logo

Each Sacco's logo is stored in `saccos.logo` (migration `00020`): PNG or
JPEG, at most 512 KB, checked by decoding the whole image. Without a logo,
reports show the name alone.

- Console: the Sacco's page → **Logo** (`PUT/GET/DELETE /api/v1/admin/saccos/{id}/logo`).
- A Sacco administrator: `PUT /api/v1/sacco/logo` (`sacco.settings.manage`).
- Body: `{"image": "<base64 or data: URL>"}`.

## Adding a report

1. Add an entry to `catalog` (`internal/export/catalog.go`): key, title,
   description, permission, what it needs.
2. Write its builder in `builders.go`. Query the whole period in a few grouped
   queries (`repository.go`), then fill in `Figures` and `Tables`.
3. Add it to `exports.sh` checks and the app's report list. The app lists
   whatever `GET /sacco/exports` returns.
