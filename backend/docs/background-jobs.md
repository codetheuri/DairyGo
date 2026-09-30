# Background jobs

Some work the API does by itself, without a request: marking idle farmers
inactive and clearing old logs. Each piece of work is a **job**. The code is
in `internal/jobs`, and the list of jobs is in `internal/app/jobs.go`.

## The jobs

| Job | Every | What it does |
| --- | --- | --- |
| `mark-idle-farmers` | day | Active farmers with no milk for their Sacco's period become inactive ([farmer-status.md](farmer-status.md)) |
| `clean-old-logs` | day | Deletes failed-request logs older than 30 days and job runs older than 90 days |
| `clean-retries-and-sessions` | day | Deletes saved request replies older than 2 days and sessions that ended over 7 days ago |

## Seeing them

**Console → Background jobs** lists every job with:
- how often it runs;
- its last run: result, time, and what it did (for example "3 farmers marked inactive") or the error;
- its next run.

**History** shows the last 20 runs, with how each started (API start,
schedule or Run now) and how long it took. **Run now** starts a job at once;
it is refused while the job is running.

API, platform operators only:

```
GET  /api/v1/admin/jobs
GET  /api/v1/admin/jobs/{name}/runs?limit=20
POST /api/v1/admin/jobs/{name}/run      202; 409 while running
```

Every run is a row in `job_runs`:
- `trigger`: `START`, `SCHEDULE` or `MANUAL` (with `triggered_by`);
- `status`: `RUNNING`, `OK` or `FAILED`;
- `summary`, `error`, `started_at`, `finished_at`.

The API log also has a line for each run that did something or failed.

## How it works

- **One goroutine per job.** `Runner.Start` starts a goroutine for each job.
  The goroutine runs the job once, then waits in a `select` on three
  channels:
  - `ctx.Done()`: the API is stopping, so return;
  - `ticker.C` (a `time.Ticker` firing every `Every`): run on schedule;
  - `manual`: an operator pressed **Run now**.

  One goroutine does all of a job's runs, one at a time, so **a job never
  overlaps itself**, with no locks needed around the work.
- **Run now** sends the operator's id on the job's `manual` channel. The
  channel holds one request, and the send never waits (`select` with
  `default`). A second request while one is waiting or running is refused
  (`ErrBusy`, shown as 409).
- **Every run is recorded.** A `RUNNING` row is written before the run and
  updated after it. A **panic** in a job is recovered (`recover`) and recorded
  as `FAILED` with the stack, so one faulty job cannot crash the API.
- **Stopping.** On shutdown the API stops taking requests, then cancels the
  jobs' `context`. A job in progress sees `ctx.Done()`: its database queries
  are cancelled, and `Runner.Wait` (a `sync.WaitGroup`) waits for the
  goroutines, up to the shutdown deadline. If the process dies mid-run, the
  row stays `RUNNING`, and the next start marks it `FAILED` ("interrupted").
- **Schedules count from start-up.** A job runs when the API starts and then
  every `Every` after that, so a restart runs every job again. Every job is
  written to be safe to run twice. There is no fixed time of day; that would
  need a scheduler library (cron), which is not worth it yet.
- **One API instance.** The jobs run inside the API process. With several
  API containers, each would run them. They are safe to repeat, but if that
  day comes, add a database lock (`pg_try_advisory_lock`) so only one
  instance runs each job.

## Adding a job

Add a `jobs.Job` in `newJobRunner` (`internal/app/jobs.go`):

```go
runner.Add(jobs.Job{
    Name:        "send-payout-reminders",       // stable id, used in URLs
    Title:       "Send payout reminders",
    Description: "Texts farmers the day before payout.",
    Every:       24 * time.Hour,
    Run: func(ctx context.Context) (string, error) {
        n, err := reminders.Send(ctx)             // pass ctx to every query
        return fmt.Sprintf("%d reminders sent", n), err
    },
})
```

It appears in the console on the next deploy. Keep `Run` safe to repeat
and quick. Pass `ctx` on so the job stops when the API stops, and return a
short summary of what it did.
