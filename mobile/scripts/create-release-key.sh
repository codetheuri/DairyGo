#!/usr/bin/env bash
# Creates the key that signs every DairyGo release, once.
#
# Phones only accept an update signed with the same key as the installed app.
# Losing this key means every user must uninstall and reinstall; leaking it
# lets someone else publish "updates". Back it up (see the message at the end).
#
#   mobile/scripts/create-release-key.sh
#
# Writes:
#   ~/.dairygo/dairygo-release.jks      the key (outside the repository)
#   mobile/android/key.properties       where it is and its password (git-ignored)
set -euo pipefail

cd "$(dirname "$0")/.."
KEY_DIR="${DAIRYGO_KEY_DIR:-$HOME/.dairygo}"
KEYSTORE="$KEY_DIR/dairygo-release.jks"
PROPS="android/key.properties"
ALIAS="dairygo"
DNAME="${DAIRYGO_KEY_DNAME:-CN=DairyGo, O=DairyGo, C=KE}"

if [[ -e "$KEYSTORE" || -e "$PROPS" ]]; then
  echo "A release key already exists ($KEYSTORE or $PROPS). Not replacing it:" >&2
  echo "a new key would stop installed apps from accepting updates." >&2
  exit 1
fi
command -v keytool >/dev/null || { echo "keytool not found (install a JDK)." >&2; exit 1; }

mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"
PASSWORD="$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-32)"

# PKCS12 uses one password for the store and the key. 10000 days (27 years)
# because a key cannot be renewed without breaking updates.
keytool -genkeypair -v \
  -storetype PKCS12 \
  -keystore "$KEYSTORE" \
  -alias "$ALIAS" \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -dname "$DNAME" \
  -storepass "$PASSWORD" -keypass "$PASSWORD" >/dev/null 2>&1
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

cat <<MSG
Release key created.

  Key:       $KEYSTORE
  Password:  in $(pwd)/$PROPS
  $FINGERPRINT

BACK IT UP NOW, in two places (for example a password manager and a USB drive):
  1. $KEYSTORE
  2. $(pwd)/$PROPS
Without both, no future update can be installed over this release.
MSG
