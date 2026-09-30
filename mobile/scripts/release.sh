#!/usr/bin/env bash
# Builds a signed release and prepares it for the in-app updater and the
# download page (https://apis.dairy.urizon.co.ke/app).
#
#   mobile/scripts/release.sh --notes "What changed, in plain words"
#   mobile/scripts/release.sh --notes "..." --required   # everyone must update
#
# Raise `version:` in pubspec.yaml first. The script:
#   1. builds one APK per phone type, signed with the release key;
#   2. refuses an APK not signed with the DairyGo key;
#   3. keeps only this version's APKs in the repository root;
#   4. writes backend/releases/ (APKs + latest.json) to copy to the server.
#
# Upload with DAIRYGO_RELEASE_TARGET=user@host:/path/to/backend/releases set,
# or copy the folder yourself: APKs first, latest.json last.
set -euo pipefail

cd "$(dirname "$0")/.."
MOBILE="$(pwd)"
ROOT="$(dirname "$MOBILE")"
RELEASES="$ROOT/backend/releases"
FLUTTER="${FLUTTER:-$(command -v flutter || echo /home/joseph/flutter/bin/flutter)}"

NOTES=""
REQUIRED=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --notes) NOTES="$2"; shift 2 ;;
    --required) REQUIRED=1; shift ;;
    *) echo "Unknown option $1" >&2; exit 2 ;;
  esac
done
[[ -n "$NOTES" ]] || { echo 'Give --notes "what changed" (shown to users).' >&2; exit 2; }
[[ -f android/key.properties ]] || {
  echo "No release key (android/key.properties). See docs/releases.md." >&2; exit 1; }

FULL="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
VERSION="${FULL%%+*}"
BUILD="${FULL##*+}"
[[ "$VERSION" != "$FULL" && "$BUILD" =~ ^[0-9]+$ ]] || {
  echo "pubspec.yaml version must look like 1.4.0+10" >&2; exit 1; }

PREVIOUS_BUILD=0
PREVIOUS_MIN=0
if [[ -f "$RELEASES/latest.json" ]]; then
  read -r PREVIOUS_BUILD PREVIOUS_MIN < <(python3 -c '
import json,sys; m=json.load(open(sys.argv[1])); print(m["build"], m["min_build"])' "$RELEASES/latest.json")
fi
(( BUILD > PREVIOUS_BUILD )) || {
  echo "Build $BUILD is not newer than the published $PREVIOUS_BUILD: raise version in pubspec.yaml." >&2; exit 1; }
# Apps older than MIN_BUILD must update; otherwise the previous rule stays.
if (( REQUIRED )); then MIN_BUILD=$BUILD; else MIN_BUILD=$PREVIOUS_MIN; fi

"$FLUTTER" build apk --release --split-per-abi

OUT="$MOBILE/build/app/outputs/flutter-apk"
# Only an APK signed with the DairyGo key is published: phones refuse any
# other as an update. The fingerprint is public (android/release-cert.sha256).
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$(sed -n 's/^sdk\.dir=//p' android/local.properties 2>/dev/null)}}"
APKSIGNER="$(ls -d "${SDK:-$HOME/Android/Sdk}"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -1 || true)"
[[ -x "$APKSIGNER" ]] || { echo "apksigner not found (Android SDK build-tools); cannot check the signature." >&2; exit 1; }
EXPECTED="$(tr -d '[:space:]' < android/release-cert.sha256 2>/dev/null || true)"
[[ -n "$EXPECTED" ]] || { echo "android/release-cert.sha256 is missing. See docs/releases.md." >&2; exit 1; }
declare -A ABI_FILE=([arm64]=app-arm64-v8a-release.apk [armv7]=app-armeabi-v7a-release.apk)

mkdir -p "$RELEASES"
rm -f "$ROOT"/DairyGo-v*.apk "$ROOT"/DairyGo.apk
for abi in arm64 armv7; do
  src="$OUT/${ABI_FILE[$abi]}"
  signer="$("$APKSIGNER" verify --print-certs "$src" | sed -n 's/^Signer #1 certificate SHA-256 digest: //p')"
  if [[ "$signer" != "$EXPECTED" ]]; then
    echo "$src is not signed with the DairyGo key (got ${signer:-none}); refusing to publish it." >&2; exit 1
  fi
  cp "$src" "$ROOT/DairyGo-v$VERSION-$abi.apk"
  cp "$src" "$RELEASES/DairyGo-v$VERSION-$abi.apk"
done
# Older APKs are no longer offered.
find "$RELEASES" -maxdepth 1 -name 'DairyGo-v*.apk' ! -name "DairyGo-v$VERSION-*.apk" -delete

python3 - "$RELEASES" "$VERSION" "$BUILD" "$MIN_BUILD" "$NOTES" <<'PY'
import datetime, hashlib, json, os, sys
releases, version, build, min_build, notes = sys.argv[1:]
files = {}
for abi in ("arm64", "armv7"):
    name = f"DairyGo-v{version}-{abi}.apk"
    data = open(os.path.join(releases, name), "rb").read()
    files[abi] = {"name": name, "sha256": hashlib.sha256(data).hexdigest(), "size": len(data)}
manifest = {
    "version": version, "build": int(build), "min_build": int(min_build), "notes": notes,
    "published_at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
    "files": files,
}
tmp = os.path.join(releases, "latest.json.tmp")
with open(tmp, "w") as f:
    json.dump(manifest, f, indent=2)
os.replace(tmp, os.path.join(releases, "latest.json"))
PY

echo
echo "Release $VERSION (build $BUILD) ready in $RELEASES"
(( REQUIRED )) && echo "Required: apps older than build $MIN_BUILD must update before use."
if [[ -n "${DAIRYGO_RELEASE_TARGET:-}" ]]; then
  # APKs first, the manifest last, so phones never see a release whose
  # files are still uploading.
  rsync -av --exclude latest.json "$RELEASES/" "$DAIRYGO_RELEASE_TARGET/"
  rsync -av "$RELEASES/latest.json" "$DAIRYGO_RELEASE_TARGET/"
  # Then remove the previous version's APKs, no longer listed.
  rsync -av --delete --exclude latest.json "$RELEASES/" "$DAIRYGO_RELEASE_TARGET/"
  echo "Uploaded. Phones will see it within minutes."
else
  echo "Upload: rsync the APKs to the server's backend/releases/, then latest.json last."
fi
