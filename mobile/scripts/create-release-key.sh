#!/usr/bin/env bash
# Creates the key that signs every DairyGo release, once.
#
# Phones only accept an update signed with the same key as the installed app.
# Losing this key means every user must uninstall and reinstall; leaking it
# lets someone else publish "updates". Back it up (see the message at the end).
#
#   mobile/scripts/create-release-key.sh
#   mobile/scripts/create-release-key.sh --from-installed [keystore]
#
# --from-installed keeps the key the installed apps were signed with (by
# default this machine's Android debug key, which signed 1.3.x), so the next
# version installs over them without an uninstall. The key is copied under a
# new random password.
#
# Writes:
#   ~/.dairygo/dairygo-release.jks      the key (outside the repository)
#   mobile/android/key.properties       where it is and its password (git-ignored)
#   mobile/android/release-cert.sha256  its public fingerprint (committed);
#                                       release.sh publishes only APKs signed by it
set -euo pipefail

cd "$(dirname "$0")/.."
KEY_DIR="${DAIRYGO_KEY_DIR:-$HOME/.dairygo}"
KEYSTORE="$KEY_DIR/dairygo-release.jks"
PROPS="android/key.properties"
ALIAS="dairygo"
DNAME="${DAIRYGO_KEY_DNAME:-CN=DairyGo, O=DairyGo, C=KE}"
PIN="android/release-cert.sha256"

FROM=""
if [[ "${1:-}" == "--from-installed" ]]; then
  FROM="${2:-}"
  if [[ -z "$FROM" ]]; then
    for candidate in "$HOME/.android/debug.keystore" "$HOME/.config/.android/debug.keystore"; do
      [[ -f "$candidate" ]] && FROM="$candidate" && break
    done
  fi
  [[ -f "$FROM" ]] || { echo "No keystore found to copy; give its path." >&2; exit 1; }
elif [[ $# -gt 0 ]]; then
  echo "Unknown option $1" >&2; exit 2
fi

if [[ -e "$KEYSTORE" || -e "$PROPS" ]]; then
  echo "A release key already exists ($KEYSTORE or $PROPS). Not replacing it:" >&2
  echo "a new key would stop installed apps from accepting updates." >&2
  exit 1
fi
command -v keytool >/dev/null || { echo "keytool not found (install a JDK)." >&2; exit 1; }

mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"
PASSWORD="$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-32)"

if [[ -n "$FROM" ]]; then
  # The same private key, under our alias and a password nobody knows.
  SRC_PASS="${DAIRYGO_SOURCE_KEY_PASSWORD:-android}"
  SRC_ALIAS="${DAIRYGO_SOURCE_KEY_ALIAS:-androiddebugkey}"
  keytool -importkeystore -noprompt \
    -srckeystore "$FROM" -srcstorepass "$SRC_PASS" -srcalias "$SRC_ALIAS" -srckeypass "$SRC_PASS" \
    -destkeystore "$KEYSTORE" -deststoretype PKCS12 -deststorepass "$PASSWORD" \
    -destalias "$ALIAS" -destkeypass "$PASSWORD" >/dev/null 2>&1
else
  # PKCS12 uses one password for the store and the key. 10000 days (27 years)
  # because a key cannot be renewed without breaking updates.
  keytool -genkeypair -v \
    -storetype PKCS12 \
    -keystore "$KEYSTORE" \
    -alias "$ALIAS" \
    -keyalg RSA -keysize 4096 -validity 10000 \
    -dname "$DNAME" \
    -storepass "$PASSWORD" -keypass "$PASSWORD" >/dev/null 2>&1
fi
chmod 600 "$KEYSTORE"

umask 077
cat >"$PROPS" <<PROPS
# DairyGo release signing. Never commit or share this file.
storeFile=$KEYSTORE
storePassword=$PASSWORD
keyAlias=$ALIAS
keyPassword=$PASSWORD
PROPS

FINGERPRINT="$(keytool -list -keystore "$KEYSTORE" -storepass "$PASSWORD" -alias "$ALIAS" \
  | grep -o 'SHA-256.*' || true)"
# The public fingerprint, as apksigner prints it (lower case, no colons).
( umask 022; keytool -list -v -keystore "$KEYSTORE" -storepass "$PASSWORD" -alias "$ALIAS" \
  | sed -n 's/^[[:space:]]*SHA256: //p' | tr -d ':' | tr 'A-F' 'a-f' >"$PIN" )
[[ -s "$PIN" ]] || { echo "Could not read the key's fingerprint." >&2; exit 1; }

cat <<MSG
Release key created.

  Key:       $KEYSTORE
  Password:  in $(pwd)/$PROPS
  $FINGERPRINT

BACK IT UP NOW, in two places (for example a password manager and a USB drive):
  1. $KEYSTORE
  2. $(pwd)/$PROPS
Commit $PIN (it is public, not a secret).
Without both, no future update can be installed over this release.
MSG
