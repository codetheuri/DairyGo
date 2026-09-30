# Milk transfers between collectors

A collector can hand milk to another collector, for example to share a route,
a vehicle or a cooler trip. The transfer is recorded by the giver and **counts
at once for both** (owner's decision, 2026-09-30: no acceptance step):

```
Alice: collected 80 − sold 55 − transferred out 20 − spoiled 5 = 0     BALANCED
Bob:   collected 100 + received 20 − sold 110                  = 10 L  MISSING
```

Without the transfer, Alice would show 20 L missing and Bob 10 L oversold: the
gap would be blamed on the wrong person. Sacco totals are unchanged by
transfers.

## Rules

| Who | Can |
| :--- | :--- |
| Collector (`milk.transfers.create`) | Transfer their own milk to an active colleague who records milk. Correct the receiver, litres or note, or cancel it, **on the day it was recorded**. |
| Receiver | See it in their lists and balances. Cannot change it: they ask the sender or an admin. |
| Admin (`milk.transfers.manage`) | Record a transfer for any collector (`from_collector_id`), and correct or cancel any transfer; a reason is required when it is another collector's. |
| Board member (`milk.transfers.read`) | See every transfer. |

- Litres must be above 0; the date defaults to today and cannot be in the
  future.
- Receivers are active users of the same Sacco whose role can record milk
  (`milk.collections.create`), which includes admins.
- Cancelled transfers stay on record (`voided_at`, `void_reason`) but no longer
  count. Every create, correction and cancellation is in the audit history
  with who did it and when.
- Saves use the `Idempotency-Key` protection like other saves, so a retry on a
  slow connection records a transfer once.

## API

| Endpoint | Permission |
| :--- | :--- |
| `GET /api/v1/sacco/milk-transfers/recipients` | `milk.transfers.create` |
| `POST /api/v1/sacco/milk-transfers` | `milk.transfers.create` |
| `GET /api/v1/sacco/milk-transfers?collector_id&direction=in\|out&from_date&to_date&include_cancelled` | `milk.transfers.read` (collectors: only their own) |
| `GET /api/v1/sacco/milk-transfers/{id}` and `/{id}/history` | `milk.transfers.read` |
| `PUT /api/v1/sacco/milk-transfers/{id}` | `milk.transfers.create` (+ rules above) |
| `POST /api/v1/sacco/milk-transfers/{id}/cancel` | `milk.transfers.create` (+ rules above) |

Table `milk_transfers` (migration `00015`), with indexes by Sacco and date and
by each collector and date. The migration also adds the three permissions and
grants them (admins: all; collectors: read and create; board members: read).

## In the app

- **Sales → Transfers tab**: the day's transfers ("To Grace −20 L", "From
  Peter +12.5 L", with the time and note), what the collector received and
  gave, and **Transfer milk to a collector**. Tapping one shows its details,
  history and, when allowed, Correct litres / Cancel transfer.
- **Transfer milk** form: pick a colleague from a list, type the litres (a
  shortcut fills in all the milk they hold today), optional note and day,
  then confirm. It warns when the litres exceed what the collector holds.
- **Home**: the balance line includes received and given milk, a Transfers
  card appears when there were any, and a Transfer Milk quick action.
- **Reports**: each collector in the audit shows what they received and gave;
  a collector's day-by-day audit lists each transfer; the ledger shows litres
  moved between collectors. The board dashboard has Transfers Today.
