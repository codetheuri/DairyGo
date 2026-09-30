# Deploying an update

What to do on the server after new code is merged. The API runs in Docker
(`docker-compose.yml`, container `dairy-api`, port 9002).

## Every backend update

```bash
cd /path/to/DairyGo            # the repository on the server
git pull

cd backend
make env                       # first time only matters: creates .env with a JWT_SECRET; never changes a good one
mkdir -p releases              # the folder the app downloads are served from
docker compose up -d --build dairy-api
```

That is all. When the container starts it applies any new database migrations
(`AUTO_MIGRATE=true` in `docker-compose.yml`) and then begins serving. If a
migration fails the API does not start, so it never runs against a
half-updated database.

No `make` on the server? Use `sh scripts/init-env.sh` instead of `make env`.

## Check it worked

```bash
docker compose ps                                   # dairy-api is "Up ... (healthy)"
docker compose logs --tail=50 dairy-api             # "Database migrations are up to date", no errors
curl -s http://localhost:9002/health                # {"status":"ok",...}
docker compose exec dairy-api ./dairy-migrate status   # every migration "Applied"
```

Then open `https://apis.dairy.urizon.co.ke/platform` and sign in.

## If something goes wrong

- **The container keeps restarting**: read `docker compose logs dairy-api`. The
  usual causes are a missing `JWT_SECRET` (`make env`) or a failed migration
  (the log names the file and the SQL error).
- **Go back to the previous version**: `git checkout <previous commit>` and
  `docker compose up -d --build dairy-api`. Migrations only add things the old
  code ignores, so the old code keeps working. Undo a migration
  (`./dairy-migrate down`, one at a time) only if you must.
- **Back up first** when a release has migrations:
  `docker exec <postgres container> pg_dump -U <user> dairy_db > backup-$(date +%F).sql`

## Publishing a new app version

Do this after the backend it depends on is deployed. On the development
machine (see [mobile/docs/releases.md](../../mobile/docs/releases.md)):

```bash
cd mobile
scripts/create-release-key.sh      # once only; back up the key and its passwords
scripts/release.sh --notes "What changed"  # builds, signs and writes backend/releases/
```

Copy `backend/releases/` to the server's `backend/releases/`, the APKs first
and `latest.json` last (or set `DAIRYGO_RELEASE_TARGET=user@server:/path/to/backend/releases`
and the script uploads it). No restart is needed: phones see the new version
within minutes, and new users install from
`https://apis.dairy.urizon.co.ke/app`.

## Order for a release with both

1. Merge to `main`.
2. Server: the four commands above.
3. Check the health and the console.
4. Publish the app version.
