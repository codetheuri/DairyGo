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
- APKs are built per phone type (`--split-per-abi`), about 17 MB each.

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

## Not done yet: recording offline

Recording milk, sales or spoilage still needs a connection. Doing it offline
needs a queue of records on the phone that is sent when the signal returns,
and the API must recognise a record sent twice (an idempotency key per
record) so a retry never counts milk twice. This is planned as its own
piece of work.
