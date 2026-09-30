#!/usr/bin/env sh
# Prepares the .env file that docker-compose.yml reads, next to it.
#
#   make env            (or: sh scripts/init-env.sh [path/to/.env])
#
# - Creates .env if it does not exist (readable only by its owner).
# - Adds a random JWT_SECRET if there is none, or if it is empty, the public
#   example value, or shorter than 32 characters.
# - Never changes a good secret (changing it signs everyone out) and never
#   touches any other setting. The secret is never printed.
# Safe to run on every deploy.
set -eu

cd "$(dirname "$0")/.."
ENV_FILE=${1:-.env}
PLACEHOLDER=generate_a_secure_random_string_for_production

new_secret() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
  else
    head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n'
  fi
}

if [ ! -f "$ENV_FILE" ]; then
  umask 077
  printf '# DairyGo API settings for docker-compose.yml. Keep this file private.\n' > "$ENV_FILE"
  echo "Created $ENV_FILE"
fi
chmod 600 "$ENV_FILE"

current=$(sed -n 's/^JWT_SECRET=//p' "$ENV_FILE" | tail -n 1 | tr -d '"'"'"' \r')
if [ -n "$current" ] && [ "$current" != "$PLACEHOLDER" ] && [ "${#current}" -ge 32 ]; then
  echo "JWT_SECRET is already set; left unchanged."
  exit 0
fi

secret=$(new_secret)
if grep -q '^JWT_SECRET=' "$ENV_FILE"; then
  tmp=$(mktemp)
  # grep exits 1 when no other lines remain; that is fine.
  grep -v '^JWT_SECRET=' "$ENV_FILE" > "$tmp" || true
  cat "$tmp" > "$ENV_FILE"
  rm -f "$tmp"
  echo "Replaced a weak JWT_SECRET. Everyone will need to sign in again once."
else
  echo "Added a new JWT_SECRET."
fi
printf 'JWT_SECRET=%s\n' "$secret" >> "$ENV_FILE"
