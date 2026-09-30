#!/usr/bin/env bash
# Ships DairyGo: deploys the backend and publishes a new app version, in one go.
#
#   ./ship.sh --notes "What changed, in plain words"
#   ./ship.sh --notes "..." --required     # older apps must update before use
#   ./ship.sh --dry-run                    # show what would happen, change nothing
#
# What it does, in order:
#   1. checks that everything is committed, and runs the backend tests and
#      the app's analyzer (--tests also runs the app's full test suite);
#   2. if the app changed since the last published version: raises the version
#      in mobile/pubspec.yaml (unless you already did) and builds and signs it;
#   3. pushes to GitHub (this branch and main);
#   4. on the server: git pull, and if the backend changed, rebuilds and
#      restarts the API (which applies new database migrations) and waits
#      until it is healthy;
#   5. uploads the new app, so phones are offered the update;
#   6. checks the public address answers with the new version.
#
# Other options: --backend-only (never publish the app), --app (publish the
# app even if mobile/ did not change), --tests.
#
# The server is set in .ship.env (not in git); see .ship.env.example. Access is
# by SSH key: no password is stored anywhere.
set -euo pipefail

cd "$(dirname "$0")"
ROOT="$(pwd)"
[[ -f .ship.env ]] && source .ship.env
SERVER="${DAIRYGO_SERVER:-}"
SERVER_PATH="${DAIRYGO_SERVER_PATH:-}"
PUBLIC_URL="${DAIRYGO_PUBLIC_URL:-https://apis.dairy.urizon.co.ke}"
FLUTTER="${FLUTTER:-$(command -v flutter || echo "$HOME/flutter/bin/flutter")}"

NOTES=""; REQUIRED=0; DRY=0; TESTS=0; APP="auto"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --notes) NOTES="$2"; shift 2 ;;
    --required) REQUIRED=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --tests) TESTS=1; shift ;;
    --backend-only) APP="no"; shift ;;
    --app) APP="yes"; shift ;;
    -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option $1 (see ./ship.sh --help)" >&2; exit 2 ;;
  esac
done

say() { printf '\n== %s\n' "$*"; }
die() { echo "ship: $*" >&2; exit 1; }
remote() { ssh -o BatchMode=yes -o ConnectTimeout=15 "$SERVER" "$@"; }

[[ -n "$SERVER" && -n "$SERVER_PATH" ]] || die "set DAIRYGO_SERVER and DAIRYGO_SERVER_PATH in .ship.env (see .ship.env.example)"
remote true 2>/dev/null || die "cannot reach $SERVER with an SSH key (try: ssh $SERVER)"

# The root README.md holds uncommitted notes and is left alone.
DIRTY="$(git status --porcelain --untracked-files=no -- . ':!README.md')"
[[ -z "$DIRTY" ]] || die "commit or undo these changes first:
$DIRTY"
BRANCH="$(git branch --show-current)"
git fetch -q origin
git merge-base --is-ancestor origin/main HEAD ||
  die "main on GitHub has commits this branch lacks; run: git pull origin main"

# --- What needs shipping -----------------------------------------------------
SERVER_HEAD="$(remote "git -C '$SERVER_PATH' rev-parse HEAD")"
git cat-file -e "$SERVER_HEAD^{commit}" 2>/dev/null || die "the server is on commit $SERVER_HEAD, unknown here"
PUBLISHED_BUILD="$(remote "cat '$SERVER_PATH/backend/releases/latest.json' 2>/dev/null" |
  python3 -c 'import json,sys; print(json.load(sys.stdin)["build"])' 2>/dev/null || echo 0)"
LAST_TAG="$(git tag --list 'app-v*' --sort=-creatordate | head -1)"

if [[ "$APP" == "auto" ]]; then
  if [[ "$PUBLISHED_BUILD" == 0 || -z "$LAST_TAG" ]] || ! git diff --quiet "$LAST_TAG" HEAD -- mobile; then
    APP="yes"
  else
    APP="no"
  fi
fi

FULL="$(sed -n 's/^version: //p' mobile/pubspec.yaml)"
VERSION="${FULL%%+*}"; BUILD="${FULL##*+}"
BUMP=0
if [[ "$APP" == "yes" ]] && (( BUILD <= PUBLISHED_BUILD )); then
  IFS=. read -r major minor patch <<<"$VERSION"
  VERSION="$major.$minor.$((patch + 1))"; BUILD=$((PUBLISHED_BUILD + 1)); BUMP=1
fi

say "Plan"
echo "Server:   $SERVER:$SERVER_PATH (now at $(git log --oneline -1 "$SERVER_HEAD"))"
echo "Shipping: $(git log --oneline -1 HEAD) from branch $BRANCH"
if git diff --quiet "$SERVER_HEAD" HEAD -- backend; then
  echo "Backend:  no change, the API is not restarted"
else
  echo "Backend:  changed, the API is rebuilt and restarted"
  git diff --name-only "$SERVER_HEAD" HEAD -- backend/database/migrations | sed 's/^/          new migration: /'
fi
if [[ "$APP" == "yes" ]]; then
  echo "App:      publish $VERSION (build $BUILD); published now: build $PUBLISHED_BUILD$( ((REQUIRED)) && echo '; REQUIRED update')"
  [[ -n "$NOTES" || $DRY == 1 ]] || die 'give --notes "what changed" (users see it on the update bar)'
  [[ -f mobile/android/key.properties ]] || die "no signing key (mobile/android/key.properties); see mobile/docs/releases.md"
else
  echo "App:      not published (no change in mobile/ since $LAST_TAG)"
fi
(( DRY )) && { echo; echo "Dry run: nothing was changed."; exit 0; }

# --- Checks -----------------------------------------------------------------
say "Checks"
(cd backend && go build ./... && go vet ./... && go test ./... >/dev/null) 2> >(grep -v 'sqlite3\|zTail\|\^\|^[0-9]* |' >&2) ||
  die "backend build or tests failed (run: cd backend && go test ./...)"
echo "backend tests passed"
(cd mobile && "$FLUTTER" analyze >/dev/null) || die "app analyzer found problems (run: cd mobile && flutter analyze)"
echo "app analyzer passed"
if (( TESTS )); then
  (cd mobile && "$FLUTTER" test >/dev/null) || die "app tests failed (run: cd mobile && flutter test)"
  echo "app tests passed"
fi

# --- Build the app before touching the server --------------------------------
if [[ "$APP" == "yes" ]]; then
  if (( BUMP )); then
    sed -i "s/^version: .*/version: $VERSION+$BUILD/" mobile/pubspec.yaml
    git commit -q -m "chore(mobile): version $VERSION+$BUILD" mobile/pubspec.yaml
  fi
  say "Building app $VERSION (build $BUILD)"
  # Start from what the server publishes, so the script compares with that.
  mkdir -p backend/releases
  rm -f backend/releases/latest.json
  rsync -a "$SERVER:$SERVER_PATH/backend/releases/latest.json" backend/releases/ 2>/dev/null || true
  RELEASE_ARGS=(--notes "$NOTES"); (( REQUIRED )) && RELEASE_ARGS+=(--required)
  DAIRYGO_RELEASE_TARGET="" mobile/scripts/release.sh "${RELEASE_ARGS[@]}" | tail -3
fi

# --- GitHub -----------------------------------------------------------------
say "Pushing to GitHub"
git push -q origin "HEAD:refs/heads/$BRANCH"
[[ "$BRANCH" == "main" ]] || git push -q origin HEAD:main
echo "main is at $(git log --oneline -1 HEAD)"

# --- Server -----------------------------------------------------------------
say "Updating the server"
remote "set -e; cd '$SERVER_PATH'; git pull -q --ff-only origin main; git log --oneline -1"
if git diff --quiet "$SERVER_HEAD" HEAD -- backend; then
  echo "backend unchanged; API left running"
else
  remote "set -e; cd '$SERVER_PATH/backend'; sh scripts/init-env.sh >/dev/null; mkdir -p releases
    docker compose up -d --build dairy-api 2>&1 | tail -3
    for i in \$(seq 1 40); do
      curl -fs http://localhost:9002/health >/dev/null 2>&1 && { echo 'API is healthy'; exit 0; }
      sleep 3
    done
    echo 'API did not become healthy. Last log lines:' >&2
    docker compose logs --tail=40 dairy-api >&2
    exit 1" || die "the server update failed; the app was NOT published. Fix it, then run ./ship.sh again"
fi

# --- Publish the app ---------------------------------------------------------
if [[ "$APP" == "yes" ]]; then
  say "Publishing app $VERSION"
  TARGET="$SERVER:$SERVER_PATH/backend/releases/"
  remote "mkdir -p '$SERVER_PATH/backend/releases'"
  # APKs first, the manifest last, then drop the previous version's APKs.
  rsync -a --exclude latest.json backend/releases/ "$TARGET"
  rsync -a backend/releases/latest.json "$TARGET"
  rsync -a --delete --exclude latest.json backend/releases/ "$TARGET"
  git tag -f "app-v$VERSION+$BUILD" >/dev/null
  git push -q -f origin "app-v$VERSION+$BUILD"
fi

# --- Verify -----------------------------------------------------------------
say "Checking $PUBLIC_URL"
curl -fsS --max-time 20 "$PUBLIC_URL/health" >/dev/null || die "$PUBLIC_URL/health does not answer"
echo "health: ok"
if [[ "$APP" == "yes" ]]; then
  LIVE="$(curl -fsS --max-time 20 "$PUBLIC_URL/api/v1/app/version" |
    python3 -c 'import json,sys; d=json.load(sys.stdin).get("data") or {}; print(d.get("build") or (d.get("release") or {}).get("build"))')"
  [[ "$LIVE" == "$BUILD" ]] || die "the server reports app build $LIVE, expected $BUILD"
  echo "app: $VERSION (build $BUILD) is live. Share $PUBLIC_URL/app"
fi
echo
echo "Shipped."
