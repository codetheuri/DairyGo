# Farmer status

Every farmer is **active**, **inactive** or **suspended**. The status decides
whether their milk can be recorded.

| Status | Milk taken? | How a farmer gets it |
| --- | --- | --- |
| **ACTIVE** | Yes | Registered; made active by staff; or brought milk while inactive |
| **INACTIVE** | Yes, and taking it makes the farmer **active again** | Made inactive by staff, or automatically after a period without milk |
| **SUSPENDED** | **No** (`409`: "This farmer is suspended…") | Only by staff, with a reason |

Only staff can lift a suspension. Bringing milk does not.

## Changing a status

- **App:** Farmer profile → **Change Status**. Only for users with
  `members.update_status` (Sacco administrators by default).
- **API:**

  ```
  PATCH /api/v1/sacco/members/{id}/status
  {"status": "SUSPENDED", "reason": "Water found in the milk"}
  ```

  A `reason` is required to suspend and optional otherwise.
- **Console:** Sacco → Farmers → **Change status**
  (`PATCH /api/v1/admin/saccos/{id}/members/{member_id}/status`).

Every change is kept in the farmer's history (`GET /sacco/members/{id}/history`,
action `STATUS`), with who made it, why, and the old and new status.
Automatic changes have no person; the app shows them as "DairyGo (automatic)".
Choosing the status a farmer already has is refused.

## Automatic inactivity

Once a day, and when the API starts, every **active** farmer who has brought
no milk for the Sacco's period is marked **inactive**. The code is
`member.MarkIdleInactive`, run from `app.Run`.

- **The period** is the setting `inactive_after_days`:
  - 60 by default;
  - `0` turns the rule off;
  - at most 365.

  It is changed in the app (Settings → **Mark farmers inactive**), in the
  console (the Sacco's page → **Change**), or with
  `PUT /api/v1/sacco/settings {"inactive_after_days": 30}`. No code change is
  needed.
- **Counted from** the latest of:
  - the farmer's last milk (rejected collections do not count);
  - when they were registered;
  - when their status last changed (`members.status_changed_at`).

  So a new farmer, or one just made active by hand, gets the full period.
- **Only active farmers** are changed. Suspended farmers stay suspended.
- It is safe to run any number of times.
- Each change is recorded in the farmer's history with the reason
  "No milk for N days: marked inactive automatically".

## Choosing a farmer to record milk

`GET /api/v1/sacco/members?can_supply=true` lists active and inactive farmers
but not suspended ones. The app's farmer picker uses it, and marks inactive
farmers "Inactive".
