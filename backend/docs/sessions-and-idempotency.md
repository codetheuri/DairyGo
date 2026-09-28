# Sessions and safe retries

## Sessions

A login returns two tokens:

| Token | Lifetime | Stored | Used for |
| :--- | :--- | :--- | :--- |
| Access token (JWT) | `ACCESS_TOKEN_TTL`, default **1 hour** | on the phone | every API request |
| Refresh token (random, 256-bit) | `SESSION_IDLE_TIMEOUT`, default **720h (30 days)** | only its SHA-256 hash, in `refresh_tokens` | `POST /api/v1/auth/refresh` |

The login and refresh responses include `access_expires_at` and
`session_expires_at`.

- **Staying signed in.** The app refreshes the access token shortly before it
  expires. Each refresh issues a new refresh token valid for another
  `SESSION_IDLE_TIMEOUT`, so a user who keeps using the app is never asked to
  sign in again.
- **Signed out when idle.** A user who does not open the app for
  `SESSION_IDLE_TIMEOUT` (30 days) must sign in again. There is no fixed
  maximum for active users (owner's decision, 2026-09-28). To change the
  limit, set `SESSION_IDLE_TIMEOUT` (for example `72h`) and restart.
- **Rotation.** A refresh marks the old refresh token `replaced_at` and
  issues a new pair. The old token keeps working for **2 minutes**, so a
  client whose refresh response was lost on a weak connection, or two
  requests refreshing at once, are not signed out.
- **Theft detection.** A replaced token presented after those 2 minutes
  means the client is broken or the token was copied: every session of that
  user is revoked and they must sign in again.
- **Logout** (`POST /api/v1/auth/logout` with the refresh token) revokes it.
  Deactivating a user or suspending their Sacco blocks them at once on every
  request, whatever their tokens say.
- Expired or revoked refresh tokens are deleted after 7 days by a daily job.

### Secret

`JWT_SECRET` signs access tokens. The API refuses to start if it is empty,
the example value that was committed in `docker-compose.yml`, or shorter than
32 characters in production (`APP_MODE=prod`). Generate one with
`openssl rand -hex 32` and keep it in `.env` next to `docker-compose.yml`.
Changing it signs everyone out once.

## Safe retries (idempotency)

On a slow connection a save can reach the server while its response is lost.
The app then retries, or the user taps again. Without protection that
records the sale, payment or spoilage twice.

The app sends a unique `Idempotency-Key` header (a UUID) with every save and
reuses it for retries of the same save. `internal/idempotency` then:

| Situation | Response |
| :--- | :--- |
| First request with the key | Runs normally; the response is stored |
| Same key again, same request | The stored response, with `Idempotent-Replayed: true`. Nothing is saved again |
| Same key while the first is still running | `409`, `Retry-After: 2` |
| Same key, different request | `422` (a client bug) |
| Key not 8–64 letters, digits, `-` or `_` | `400` |

- It applies to `POST`, `PUT`, `PATCH` and `DELETE` under `/api/` with a
  valid bearer token. Keys are scoped per user.
- Successes and validation errors are stored; `401`, `403`, `408`, `409`,
  `429` and server errors are not, so a retry runs again.
- The first request claims the key with a unique `(user_id, idem_key)` row
  before running, so simultaneous duplicates cannot both run.
- If a request crashed and left its key "running" for over 2 minutes, a retry
  takes the key over.
- If the key table cannot be reached, requests are served without protection
  rather than failed.
- Keys are deleted after 48 hours by a daily job.

Clients that do not send the header behave as before.
