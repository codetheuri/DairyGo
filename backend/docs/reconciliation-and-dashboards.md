# Milk Reconciliation & Dashboards

## The balancing rule

Every litre a collector receives from farmers must leave as a **sale to a
customer** (coolers included) or be logged as **spoilage**:

```
collected (non-rejected)  =  sold (non-voided)  +  spoiled  +  unaccounted
unaccounted = collected − sold − spoiled
```

| Unaccounted | Status | Meaning |
| :--- | :--- | :--- |
| within tolerance | `BALANCED` | All milk is accounted for |
| above tolerance | `MISSING` | Milk collected but never sold or logged: loss, theft, or an unrecorded delivery |
| below −tolerance | `OVERSOLD` | More sold than collected: a recording mistake, a missing collection entry, or added water |

Before this change, "net delivered to cooler" was *assumed* to be whatever was not
sold or spoiled, so every day balanced by definition and losses were invisible.

The rule lives in one place, `pkg/reconcile.Compute`, and is used by collector
reconciliation, both reports and both dashboards.

### Tolerance

Scales and dip-sticks are never exact. Each Sacco sets
`reconciliation_tolerance_litres` (default `0`) in `PUT /api/v1/sacco/settings`:
the litres of difference allowed **per collector per day**. Period and Sacco-wide
views allow `tolerance × collector-days`.

A Sacco-wide total can balance while individual collectors do not (one collector's
missing milk cancels another's oversold milk). The Sacco ledger therefore lists
the **collectors to check** separately.

## Where it appears

| Endpoint | Scope |
| :--- | :--- |
| `GET /sacco/reconciliation?date=` | One collector's day. Collectors see only their own. |
| `GET /sacco/reports/reconciliation?from_date&to_date` | Sacco ledger: volumes, sales by customer type, unaccounted litres, money (owed to farmers, revenue, paid at sale, credit, gross margin, customers owe now), per-collector summaries |
| `GET /sacco/reports/collector-audit` | Per-collector balance over a period, with `tolerance_litres` (per collector per day) so the app balances each day of the period the same way |
| `GET /sacco/dashboard/summary?days=` | Executive cards (today's balance status, month gross margin, receivables) and daily trend including unaccounted litres |
| `GET /sacco/dashboard/collector` | A collector's day, including unaccounted litres and cash received |

There is no "to station" or "net handover" figure: deliveries to coolers and
stations are sales to a customer like any other.

**Breaking change:** `net_delivered_litres`, `net_coolant_*` and `discrepancy_litres`
were removed. Use `unaccounted_litres`, `balance_status`, `is_balanced` and
`allowance_litres` instead.

## Performance

The dashboards and reports used to run one query **per day** and **per
collector** (about 90 queries for a 30-day trend, and 3 per user for the
collector audit). They now use:

- **One grouped query per table** (`GROUP BY collection_date`, or `GROUP BY collector_id`),
  merged in Go with zero-filled days. The executive dashboard runs 7 queries
  for any range, and the collector audit runs 3 however many collectors there are.
- **Plain date comparisons** (`collection_date BETWEEN ? AND ?`) instead of
  `DATE(collection_date)`. The columns are already `DATE`, and wrapping them in a
  function stops the database using the `(sacco_id, date)` and
  `(sacco_id, collector_id, date)` indexes.

At Sacco scale (thousands of records a day) this answers in milliseconds.
Summary tables or caching are not needed unless measurements show otherwise.
Webhooks would not help here: they push events to other systems and do not make
reads faster.
