# App releases

`internal/appupdate` publishes the Android app outside an app store.

| Route | Auth | Purpose |
| :--- | :--- | :--- |
| `GET /api/v1/app/version` | public | Latest release: `version`, `build`, `min_build`, `notes`, `published_at`, and per phone type (`arm64`, `armv7`) the download `url`, `sha256` and `size`. 404 when nothing is published. |
| `GET /app` | public | Download page to share (English and Swahili steps). |
| `GET /app/download/{abi}` | public | The APK, as `application/vnd.android.package-archive` with `Range` support. |

These are public because an app too old to use must still be able to update.

## Where releases live

The folder `APP_RELEASES_DIR` (default `releases`; in Docker
`./releases` mounted read-only at `/app/releases`) holds the APKs and
`latest.json`, written by `mobile/scripts/release.sh` and copied to the
server. There is no upload endpoint, so a stolen password cannot replace
the app.

- `latest.json` is re-read when it changes, so publishing needs no restart.
- A manifest is rejected if a file is missing, is not the listed size (still
  copying), has a name with a path, or if `min_build` is above `build`. The
  API then answers 503 instead of sending phones a broken release. Copy the
  APKs first and `latest.json` last.
- `min_build` forces an update: apps with a lower build show only an update
  screen.

## Long downloads

The server's write timeout is 10 s, far too short for a 21 MB file on a
100 kbps connection. The download handler extends its own deadline to 2 hours
with `http.ResponseController`. This works through the middleware because
every response wrapper implements `Unwrap()`, and a test checks it. A new
middleware that wraps the `ResponseWriter` must implement `Unwrap()` too.

Publishing steps and what users see: [mobile/docs/releases.md](../../mobile/docs/releases.md).
