#!/usr/bin/env bash
# Captures the API responses the layout test uses (test/layout/fixtures).
#
# Run it against a local API that has test data, with one account per role:
#   API=http://localhost:18081 \
#   ADMIN=user:pass COLLECTOR=user:pass BOARD=user:pass \
#   test/layout/capture_fixtures.sh
#
# Never point it at production: fixtures are committed to the repository.
# The admin-noprice fixtures are edited by hand from the admin ones.
set -euo pipefail
API=${API:?set API, e.g. http://localhost:18081}
case "$API" in *urizon*) echo "refusing to capture from production" >&2; exit 1;; esac
OUT="$(dirname "$0")/fixtures"
TODAY=$(TZ=Africa/Nairobi date +%F)
FROM=$(TZ=Africa/Nairobi date +%Y-%m-01)
TO=$(TZ=Africa/Nairobi date -d "$FROM +1 month -1 day" +%F)

token() { # user:pass
  curl -s -X POST "$API/api/v1/auth/login" -H 'Content-Type: application/json' \
    -d "{\"login\":\"${1%%:*}\",\"password\":\"${1#*:}\"}" | jq -r '.data.access_token'
}

grab() { # role token path query
  local file="$OUT/$1/$(echo "$3" | sed 's#^/api/v1/##; s#/#_#g').json" out code
  out=$(curl -s -w '\n%{http_code}' -H "Authorization: Bearer $2" "$API$3?$4")
  code=$(tail -n1 <<<"$out")
  sed '$d' <<<"$out" | jq --argjson s "$code" '{status: $s, body: .}' > "$file"
  printf '%-10s %-45s %s\n' "$1" "$3" "$code"
}

for role in admin collector board; do
  var=$(tr '[:lower:]' '[:upper:]' <<<"$role")
  T=$(token "${!var:?set $var=user:pass}")
  if [ -z "$T" ] || [ "$T" = null ]; then echo "login failed for $role" >&2; exit 1; fi
  mkdir -p "$OUT/$role"
  grab $role "$T" /api/v1/auth/me ""
  grab $role "$T" /api/v1/auth/users "per_page=100"
  grab $role "$T" /api/v1/sacco/dashboard/collector ""
  grab $role "$T" /api/v1/sacco/dashboard/summary "days=7"
  grab $role "$T" /api/v1/sacco/members "per_page=30"
  grab $role "$T" /api/v1/sacco/milk-collections "per_page=30&from_date=$TODAY&to_date=$TODAY"
  grab $role "$T" /api/v1/sacco/milk-sales "per_page=100&from_date=$TODAY&to_date=$TODAY"
  grab $role "$T" /api/v1/sacco/milk-spoilage "per_page=100&from_date=$TODAY&to_date=$TODAY"
  grab $role "$T" /api/v1/sacco/reconciliation ""
  grab $role "$T" /api/v1/sacco/customers "per_page=30"
  grab $role "$T" /api/v1/sacco/customers/balances ""
  grab $role "$T" /api/v1/sacco/milk-prices/active ""
  grab $role "$T" /api/v1/sacco/milk-prices "per_page=50"
  grab $role "$T" /api/v1/sacco/profile ""
  grab $role "$T" /api/v1/sacco/settings ""
  grab $role "$T" /api/v1/sacco/reports/farmer-payout "from_date=$FROM&to_date=$TO"
  grab $role "$T" /api/v1/sacco/reports/reconciliation "from_date=$FROM&to_date=$TO"
  grab $role "$T" /api/v1/sacco/reports/collector-audit "from_date=$FROM&to_date=$TO"
done
