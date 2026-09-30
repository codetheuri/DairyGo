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

## The signing key

Android installs an update only when it is signed with the same key as the
installed app. DairyGo keeps **the key the first versions (1.3.x) were signed
with**, so 1.4.0 and everything after installs over them with no uninstall
and users stay logged in. (That key began as this laptop's Android debug key;
it was copied under a new random password.)

- The key: `~/.dairygo/dairygo-release.jks`
- Its password: `mobile/android/key.properties`
- Its public fingerprint: `mobile/android/release-cert.sha256` (in git)

The first two are outside git. **Back up both files in two places**, for
example a password manager and a USB drive. Without them no future update can
be installed over the app, and every user would have to uninstall and
reinstall. On another computer, copy both files back to the same places.

A release build fails without the key, and `release.sh` refuses to publish
an APK whose signature does not match the fingerprint.

`scripts/create-release-key.sh --from-installed` is how the key was set up;
it refuses to run when a key already exists. Without the flag it would make a
brand-new key, which is only right for an app nobody has installed yet.

Users on 1.3.x install 1.4.0 once from the download page (1.3.x has no
Update button). After that the app updates itself.

## Publishing a version

The short way, from the repository root, does everything below and deploys
the backend too (see [deployment](../../backend/docs/deployment.md)):

```bash
./ship.sh --notes "Faster sales screen. Fixes the report totals."
```

By hand:

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

The script builds one APK per phone type, refuses an APK not signed with the DairyGo key, keeps
only the new APKs in the repository root, and writes `latest.json` with each
file's size and SHA-256.

### Build numbers and Android's versionCode

`release.sh` builds one APK per phone type (`--split-per-abi`). Flutter then
adds 1000 (armv7) or 2000 (arm64) to the build number to make each APK's
Android `versionCode`: build 12 is installed as 1012 or 2012. Releases are
published by build number, so the app takes the offset off again
(`releaseBuild` in `app_release.dart`) and asks the server with `scheme=2`.
Keep build numbers below 1000.

Versions 1.4.0 and 1.4.1 compared the raw `versionCode` and so never saw an
update. The server answers apps that send no `scheme` in that scale (build +
2000), which lets them update to a fixed version.

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
