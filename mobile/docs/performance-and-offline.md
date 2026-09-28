# Speed and offline use

Collectors often work on 2G/3G at around 100 kbps (about 12 KB per second) or
with no signal. The app is built for that.

## What was measured

At 100 kbps against a Sacco with 150 farmers and 150 collections a day:

| Screen | Before | After |
| :--- | :--- | :--- |
| Intake list | 91.7 KB, about 7 s (100 collections + 100 farmers, uncompressed) | 2.6 KB, about 0.2 s (first 30, compressed) |
| Farmer directory | 40.8 KB, about 3 s | 1.9 KB, about 0.2 s |
| Farmer search in the picker | whole list downloaded first | 0.9 KB per search |

## How

**Smaller responses**
- The API compresses JSON with gzip (about 85% smaller); the app accepts it
  automatically.
- Lists load 30 rows at a time and fetch more on scrolling
  (`PagedListNotifier`, `PagedListFooter`).
- Collection rows carry the farmer's name, so no farmer list is downloaded
  to label them.
- Searches wait for a pause in typing, and run on the server.
- Report detail screens ask the server for one collector's or one farmer's
  rows instead of everyone's.
- Recording something reloads only the figures it changes, and only for
  screens that are open.
- Fonts are bundled (450 KB, Latin subset) instead of downloaded at start.
- APKs are built per phone type (`--split-per-abi`), about 20 MB each instead of 56 MB.

**Slow and dropped connections**
- Timeouts: 20 s to connect, 45 s to receive.
- Reads (GET) that drop or time out are retried twice (after 1 s and 3 s).
  Writes are never retried: a sale whose reply was lost may have been saved,
  and repeating it would record the milk twice.
- A timeout says the network is slow, not that there is no internet.

**Saved data (`lib/core/cache/response_cache.dart`)**
- The last response of every GET is kept on the phone, per user, in the
  app's private folder (at most 400).
- Opening a screen shows the saved copy at once and asks the server in the
  background. A copy under 20 s old is used without asking. If the server's
  answer differs, open screens reload from the new copy; paged lists do so
  only while on page 1, so scrolling is never reset.
- After the user records or changes anything, saved copies are not shown
  first any more until refreshed, so a list never misses the record just
  added.
- With no answer from the server (no signal, timeout, server down), the saved
  copy is shown. Real errors from the server (403, 404, 422) still show.
- Logging out, or a session the server ends, deletes the saved data, so a
  shared phone shows nothing of the previous user.

**Starting without signal**
- The user's profile is saved at login. If the server cannot be reached at
  start-up the saved profile is used and the user stays signed in. Only a
  rejected session (for example a deactivated account) signs them out.

## Online-only by decision

Recording milk, sales, spoilage and payments needs a connection; there is no
offline recording queue (the Sacco owner's decision, 2026-09-28). Saved data
is only used to show screens quickly and to let users read the last figures
when the signal drops.

## Connection status (`lib/core/network/connection_monitor.dart`)

The app judges the connection from real traffic, because a phone can show
Wi-Fi or mobile data "on" with no data bundle, and then nothing loads.

| Status | How it is decided | What the user sees |
| :--- | :--- | :--- |
| Online | Recent requests answered quickly | Nothing |
| Slow | Median of the last 5 answers over 2.5 s, or a request waiting over 4 s | Amber strip: "Slow connection · loading and saving may take a little longer" |
| No internet | Two requests without any answer, or the phone reports no network, and the server's `/health` does not answer | Dark strip: "No internet connection · showing data from 10:42 · saving needs a connection", with Retry |

- The strip is shown on every screen (it sits at the app root), clear of the
  gesture bar, and says "Back online" for 3 s when the connection returns.
- While offline, `/health` is checked after 5, 10, 20, then every 30 s, and
  whenever the app comes back to the foreground.
- While offline, reads fail at once so saved data shows without waiting for
  a timeout. A save checks `/health` once first, so a stale status never
  blocks a real save; if there is still no connection the form says it was
  not saved and why.
- The saving overlay dims the form, blocks taps, and on a slow connection
  asks the user to wait and keep the app open.

## Saves are recorded once

Every save (POST/PUT/PATCH/DELETE) carries an `Idempotency-Key`
(`IdempotencyInterceptor`). A save that got no definite answer (timeout,
dropped connection, "still processing") keeps its key for 10 minutes, so an
automatic retry or the user tapping Save again is recognised by the server
and recorded once. Because of that, saves are now retried automatically
(after 1 s and 3 s) like reads. See `backend/docs/sessions-and-idempotency.md`.

## Sessions

- Sign-in stores the access token (1 hour), the refresh token and both
  expiry times in secure storage.
- `TokenRefresher` renews the access token 2 minutes before it expires, or
  after a 401, and retries the request. Concurrent renewals share one
  request.
- Only the server refusing the renewal signs the user out ("Your session has
  ended"). No signal while renewing never signs anyone out.
- A user who does not use the app for 30 days (the server's
  `SESSION_IDLE_TIMEOUT`) is signed out; the phone also checks this at start
  and when the app returns to the foreground, with "You were signed out
  because the app was not used for a long time".
- Logout ends the session on the server too, and deletes the saved data.

## Start-up and loading

- The app opens straight into the saved profile and confirms the session
  with the server in the background, instead of waiting a round trip.
- One connection pool is shared by the whole app and connections are kept
  for 55 s between requests (Dart's default is 15 s), saving a new TCP and
  TLS handshake (0.6–2.6 s on a slow link) after short pauses.
- A second after the home screen opens, the data behind the role's other
  bottom-bar tabs is fetched, so the first tap on each tab is instant.
- Loading shows placeholders shaped like the content (`skeleton.dart`)
  instead of a spinner; they pulse gently and stay still with reduced
  motion.
