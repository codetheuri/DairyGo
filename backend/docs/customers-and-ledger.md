# Customers, Sales & the Customer Ledger

**Every litre that leaves a collector is a sale to a customer**, including
deliveries to coolers. Coolers, processors, hotels, shops and individuals are
all customers. Code: `internal/customer` (customers, payments, statements) and
the sales part of `internal/collection`.

---

## Customers

| Field | Notes |
| :--- | :--- |
| `customer_type` | `COOLER`, `PROCESSOR`, `HOTEL`, `SHOP`, `INDIVIDUAL`, `OTHER` |
| `phone` | Optional, **unique per Sacco** (spaces removed). A second customer with the same phone gets `409`. |
| `default_price_per_litre` | The agreed selling price; prefilled on sales |
| `status` | `ACTIVE` / `INACTIVE`. Inactive customers keep their ledger and can still pay, but no new sales can be recorded for them. |

Collectors add customers on the spot while recording a sale
(search → not found → add → sell).

## Recording a sale

`POST /api/v1/sacco/milk-sales`

```json
{ "customer_id": "…", "quantity_litres": 100, "unit_price": 55, "amount_paid": 0, "payment_method": "CREDIT" }
```

- The customer must be `ACTIVE` and in the caller's Sacco.
- `unit_price` defaults to the customer's agreed price; if there is none it is required.
- `amount_paid` is what was paid **at the time of sale**. It defaults to the full
  total, or `0` when `payment_method` is `CREDIT`. It cannot exceed the total.
- `payment_status` is derived: nothing paid → `CREDIT`, part paid → `PARTIAL`,
  all paid → `PAID`. It describes the sale moment only. Later payments reduce the
  customer's balance, not individual sales.
- `buyer_name` / `buyer_phone` are snapshots of the customer at the time of sale.

**Corrections:** collectors may correct their own sales on the day they were
recorded; admins (`milk.sales.manage`) may correct any sale with a reason. Admins
**void** mistaken sales (`POST /milk-sales/{id}/void`, reason required). Voided
sales stay on record but are excluded from reconciliation, dashboards and
balances. Every change is in `GET /milk-sales/{id}/history`.

## The ledger: a running balance

```
balance = Σ sale totals − Σ amounts paid at sale − Σ customer payments   (voided entries excluded)
```

A positive balance is money the customer owes the Sacco; negative means they
paid in advance. Payments are **not** matched to individual sales.

| Endpoint | Who | Purpose |
| :--- | :--- | :--- |
| `POST /customers/{id}/payments` | Admin | Money received (M-Pesa, cash, bank, cheque) with a reference |
| `POST /customer-payments/{id}/void` | Admin | Cancel a payment recorded in error (reason required) |
| `GET /customers/{id}/statement?from_date&to_date` | Admin, board | Opening balance, sales and payments with running balance, closing balance |
| `GET /customers/balances?owing_only=true` | Admin, board | Who owes what, largest first, plus the total owed |

Collectors can search and add customers but never see balances.

### Statement example

| Date | Entry | Debit | Credit | Balance |
| :--- | :--- | ---: | ---: | ---: |
| | Opening balance | | | 0 |
| 22 Sep | Milk sale 40 L @ 55 (credit) | 2,200 | | 2,200 |
| 27 Sep | Milk sale 100 L @ 55 (credit) | 5,500 | | 7,700 |
| 27 Sep | Payment (MPESA) ref QX12AB | | 3,000 | 4,700 |

## Existing sales (migration 00010)

Sales recorded before customers existed were linked automatically. The migration
created one customer per distinct buyer in each Sacco: buyers with a phone are
grouped by phone, the rest by name ignoring case, and the most recent spelling
becomes the name. Their type is `OTHER`, so admins should set the right type,
e.g. `COOLER`. Old `PAID` sales count as fully paid. Old `PENDING` and `PARTIAL`
sales start as fully owed, because the amount actually paid was never captured;
record the payments already received to correct the balances.
