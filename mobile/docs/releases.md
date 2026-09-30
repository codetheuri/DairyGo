# Releasing the app

DairyGo is not in an app store. Phones get it from the download page, and
from version 1.4 the app updates itself.

| What | Where |
| :--- | :--- |
| Download page to share | `https://apis.dairy.urizon.co.ke/app` |
| Latest version (for the app) | `GET /api/v1/app/version` |
| APKs | `/app/download/arm64` (most phones), `/app/download/armv7` (older phones) |

Share the page link, not APK files: WhatsApp sends an APK as a "document",
and many phones then offer a PDF reader instead of the installer. The page
serves the file as an Android package, so Chrome opens the installer. It
has install steps in English and Swahili, and fixes for common problems.

## The release key (once)

Android installs an update only when it is signed with the same key as the
installed app. Up to 1.3.x the app was signed with this laptop's debug key.
From 1.4.0 it uses a release key:

```bash
mobile/scripts/create-release-key.sh
```

This creates `~/.dairygo/dairygo-release.jks` and
`mobile/android/key.properties` (its password), both outside git.
**Back up both files in two places**, for example a password manager and a
USB drive. Without them no future update can be installed over the app, and
every user would have to uninstall and reinstall. On another computer, copy
both files back to the same places.

A release build fails without the key rather than falling back to the debug
key.

Moving from 1.3.x to 1.4.0 needs **one** uninstall and reinstall on each
phone, because the key changes. Records are on the server; users only log in
again. The download page explains this under "If it does not work".

## Publishing a version

1. Raise `version:` in `pubspec.yaml` (for example `1.4.1+11`; the number
   after `+` must go up).
2. Build and prepare the release:

   ```bash
   mobile/scripts/release.sh --notes "Faster sales screen. Fixes the report totals."
   ```

   Add `--required` when older apps must stop working. Use it for backend
   changes they cannot handle. Those phones then show only a "Please update"
   screen.
3. Copy `backend/releases/` to the server's `backend/releases/`, APKs first
   and `latest.json` last. The script does this in the right order when
   `DAIRYGO_RELEASE_TARGET=user@server:/path/to/backend/releases` is set.
   No restart is needed.

The script builds one APK per phone type, refuses a debug-signed APK, keeps
only the new APKs in the repository root, and writes `latest.json` with each
file's size and SHA-256.

## What users see

- **A green bar at the bottom of every screen**: "New version … is ready",
  with **Update** and **Later**. Later hides it until the app is next opened.
- **Update** downloads in the background, with progress, while they keep
  working. A dropped connection continues where it stopped (21 MB takes
  about half an hour at 100 kbps). The file is checked against the
  release's SHA-256.
- **The first time**, Android asks to allow installs from DairyGo. The bar
  says so and its **Allow** button opens the switch. After the user turns it
  on and presses Back, the install continues by itself.
- Android's installer then asks **Update?**. No app outside an app store can
  skip this tap.
- **More → App version** shows the version, with **Check** and **Update**.
- With `--required`, older apps show only the update screen, even before
  login, with the download page address as a fallback.

The app checks at start and when it comes back to the front, at most every
6 hours (any time with **Check**). The check is public, so an app that
cannot log in can still update.

## Security

- Only a phone's own installer can install, and only an APK signed with the
  release key. A changed file fails the SHA-256 check first.
- Releases are copied to the server by the developer. The API has no upload
  endpoint, so a stolen password cannot replace the app.
- The app asks Android for `REQUEST_INSTALL_PACKAGES`. Google Play restricts
  this permission. If the app moves to Play, the Play build should update
  through Play instead (the `in_app_update` package).

## Checking on a phone

Before sharing a release, on one phone with the previous version:

1. Open the app and wait for the green bar (or More → App version → Check).
2. Tap Update and watch the progress. Turn mobile data off and on midway;
   tapping Update again should continue from where it stopped.
3. Allow installs when asked, press Back, and confirm the Android update.
4. The app restarts on the new version; More shows it.
