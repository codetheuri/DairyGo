# Milk Collections, Pricing & Audit History

How farmer milk intake is recorded, priced, corrected and audited. The rules live
in `internal/collection` (`service.go`, `rules.go`); the audit store is `pkg/audit`.

---

## Recording a collection

`POST /api/v1/sacco/milk-collections` is accepted only when:

- the farmer (`member_id`) exists **in the caller's Sacco** (otherwise `404`);
- the farmer is `ACTIVE` (suspended or inactive farmers get `400`);
- there is no other collection for the same farmer, date and shift;
- a buying price is in force on the collection date (see below).

The farmer receives an SMS receipt when an SMS provider is configured.

## Buying prices are a schedule

Each `POST /api/v1/sacco/milk-prices` adds a row with an `effective_date`. Nothing is
overwritten, so the rows form a rate schedule:

| Effective date | Price / L |
| :--- | :--- |
| 1 Sep | 40 |
| 26 Sep | 50 |
| 7 Oct (future) | 60 |

A collection is priced at **the latest price whose effective date is on or before
the collection date**, and that price is snapshotted on the record. In the example,
a collection dated 20 Sep costs 40/L, one dated today costs 50/L, and the 60/L
price starts applying automatically on 7 Oct. `GET /milk-prices/active` returns the
price in force today.

`is_active = false` marks a price row as voided; voided rows are never used.

## Who can edit, and when

| Caller | May edit |
| :--- | :--- |
| Collector | Only their **own** records, only while `SUBMITTED`, only on the **day the record was created** |
| Sacco admin (`milk.collections.manage`) | Any `SUBMITTED` or `ADJUSTED` record; must give a `reason` |
| Anyone | Never a `VERIFIED` or `REJECTED` record (`409`); an admin must reopen it first |

An admin edit to a `SUBMITTED` record marks it `ADJUSTED`, so the collector can no
longer overwrite the correction. Quantity changes recalculate the total at the
record's **original** snapshot price. A shift change is refused if the farmer
already has a record for that shift and date.

Errors: `403` = not your record, `409` = the record's state does not allow the change.

## Status flow

```
SUBMITTED ──► VERIFIED ──► ADJUSTED (reopen) ──► VERIFIED
    │    └──► REJECTED ──► ADJUSTED (reopen) ──► REJECTED
    └──────► ADJUSTED
```

`PATCH /milk-collections/{id}/status` needs `milk.collections.manage`. Moving to
`REJECTED` or `ADJUSTED` requires a `reason`. Rejected collections are excluded from
payouts, reconciliation and dashboards.

## Audit history

Every create, edit and status change writes an `audit_logs` row **in the same
transaction** as the change: who did it, when, why, and JSON snapshots of the
values before and after.

`GET /api/v1/sacco/milk-collections/{id}/history` returns the trail, oldest first.

`pkg/audit` is generic (`entity_type` + `entity_id`), so other modules record their
history the same way:

```go
entry := audit.Entry{SaccoID: c.SaccoID, EntityType: "milk_collection", EntityID: c.ID,
    Action: audit.ActionUpdate, ActorID: userID, Reason: reason, OldValues: before, NewValues: after}
return r.db.Transaction(func(tx *gorm.DB) error {
    if err := tx.Save(c).Error; err != nil {
        return err
    }
    return audit.Record(tx, entry)
})
```
