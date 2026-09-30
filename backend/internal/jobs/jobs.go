// Package jobs runs the work the API does by itself on a schedule (clearing
// old logs, marking idle farmers inactive, ...), and records every run so
// platform operators can see what ran, when, and how it ended.
//
// Each job has its own goroutine that runs it once when the API starts, then
// every Job.Every, and whenever an operator asks (RunNow). Because one
// goroutine does all of a job's runs, a job never overlaps itself.
package jobs

import (
	"context"
	"errors"
	"fmt"
	"runtime/debug"
	"sync"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/pkg/logger"
)

// Job is one piece of scheduled work.
type Job struct {
	// Name identifies the job in URLs and the run history ("mark-idle-farmers").
	Name string
	// Title and Description say what it does, for people.
	Title       string
	Description string
	// Every is the time between scheduled runs.
	Every time.Duration
	// Run does the work and returns a short summary of what it did
	// ("3 farmers marked inactive"). It should stop when ctx is cancelled.
	Run func(ctx context.Context) (string, error)
}

// Trigger says why a run started.
type Trigger string

const (
	TriggerStart    Trigger = "START"    // the API started
	TriggerSchedule Trigger = "SCHEDULE" // its time came
	TriggerManual   Trigger = "MANUAL"   // an operator asked (RunNow)
)

// Status is how a run is going or ended.
type Status string

const (
	StatusRunning Status = "RUNNING"
	StatusOK      Status = "OK"
	StatusFailed  Status = "FAILED"
)

// Errors returned by RunNow.
var (
	ErrUnknownJob = errors.New("no such job")
	ErrBusy       = errors.New("the job is already running or about to run")
)

// Run is one run of a job, as stored in job_runs.
type Run struct {
	ID          int64      `json:"id" gorm:"primaryKey;autoIncrement"`
	Job         string     `json:"job"`
	Trigger     Trigger    `json:"trigger"`
	TriggeredBy *uint      `json:"triggered_by,omitempty"`
	Status      Status     `json:"status"`
	Summary     *string    `json:"summary,omitempty"`
	Error       *string    `json:"error,omitempty"`
	StartedAt   time.Time  `json:"started_at"`
	FinishedAt  *time.Time `json:"finished_at,omitempty"`
}

// TableName sets the table name.
func (Run) TableName() string { return "job_runs" }

// entry is a registered job and what the runner knows about it now.
type entry struct {
	job Job
	// manual carries RunNow requests to the job's goroutine. It holds one
	// request: a second one while the first waits is refused (ErrBusy).
	manual chan uint

	mu      sync.Mutex // guards the fields below
	running bool
	nextRun time.Time
}

// Runner starts the jobs and records their runs.
type Runner struct {
	db   *gorm.DB
	log  logger.Logger
	jobs []*entry
	wg   sync.WaitGroup
	now  func() time.Time
}

// NewRunner creates a runner that records runs in db.
func NewRunner(db *gorm.DB, log logger.Logger) *Runner {
	return &Runner{db: db, log: log, now: time.Now}
}

// Add registers a job. Call it before Start.
func (r *Runner) Add(j Job) {
	r.jobs = append(r.jobs, &entry{job: j, manual: make(chan uint, 1)})
}

// Start marks runs left RUNNING by a previous process as interrupted, then
// starts one goroutine per job. They stop when ctx is cancelled; Wait waits
// for them.
func (r *Runner) Start(ctx context.Context) {
	msg := "interrupted: the API stopped during the run"
	err := r.db.WithContext(ctx).Model(&Run{}).Where("status = ?", StatusRunning).
		Updates(map[string]any{"status": StatusFailed, "error": msg, "finished_at": r.now()}).Error
	if err != nil {
		r.log.Error("Failed to close interrupted job runs", err)
	}
	for _, e := range r.jobs {
		r.wg.Add(1)
		go r.loop(ctx, e)
	}
}

// Wait blocks until every job goroutine has stopped (after ctx is cancelled
// and any run in progress has returned).
func (r *Runner) Wait() { r.wg.Wait() }

// loop is a job's goroutine: run now, then on each tick or manual request,
// until ctx is cancelled. select waits on all three at once.
func (r *Runner) loop(ctx context.Context, e *entry) {
	defer r.wg.Done()
	ticker := time.NewTicker(e.job.Every)
	defer ticker.Stop()
	e.setNext(r.now().Add(e.job.Every))
	r.run(ctx, e, TriggerStart, nil)
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			e.setNext(r.now().Add(e.job.Every))
			r.run(ctx, e, TriggerSchedule, nil)
		case by := <-e.manual:
			r.run(ctx, e, TriggerManual, &by)
		}
	}
}

// run does one run of e and records it. A panic in the job is recovered and
// recorded as a failure, so one faulty job cannot stop the API.
func (r *Runner) run(ctx context.Context, e *entry, trigger Trigger, by *uint) {
	e.setRunning(true)
	defer e.setRunning(false)

	rec := &Run{Job: e.job.Name, Trigger: trigger, TriggeredBy: by, Status: StatusRunning, StartedAt: r.now()}
	if err := r.db.WithContext(ctx).Create(rec).Error; err != nil {
		r.log.Error("Failed to record a job run", err, "job", e.job.Name)
	}

	summary, err := safeRun(ctx, e.job.Run)

	finished := r.now()
	rec.FinishedAt = &finished
	rec.Status = StatusOK
	if summary != "" {
		rec.Summary = &summary
	}
	if err != nil {
		msg := err.Error()
		rec.Status, rec.Error = StatusFailed, &msg
		r.log.Error("Background job failed", err, "job", e.job.Name)
	} else if summary != "" {
		r.log.Info(fmt.Sprintf("Background job %s: %s", e.job.Name, summary))
	}
	// Recorded even if ctx was cancelled during the run.
	if rec.ID != 0 {
		if err := r.db.WithContext(context.WithoutCancel(ctx)).Save(rec).Error; err != nil {
			r.log.Error("Failed to record a job run", err, "job", e.job.Name)
		}
	}
}

// safeRun calls run, turning a panic into an error.
func safeRun(ctx context.Context, run func(context.Context) (string, error)) (summary string, err error) {
	defer func() {
		if p := recover(); p != nil {
			err = fmt.Errorf("panic: %v\n%s", p, debug.Stack())
		}
	}()
	return run(ctx)
}

// RunNow asks for a job to run now, on behalf of platform user by. It returns
// at once; the run appears in the history. A job already running or with a
// run already asked for is refused with ErrBusy.
func (r *Runner) RunNow(name string, by uint) error {
	e := r.find(name)
	if e == nil {
		return ErrUnknownJob
	}
	if e.isRunning() {
		return ErrBusy
	}
	select {
	case e.manual <- by:
		return nil
	default: // a request is already waiting
		return ErrBusy
	}
}

func (r *Runner) find(name string) *entry {
	for _, e := range r.jobs {
		if e.job.Name == name {
			return e
		}
	}
	return nil
}

// JobStatus is a job as the console shows it.
type JobStatus struct {
	Name         string    `json:"name"`
	Title        string    `json:"title"`
	Description  string    `json:"description"`
	EverySeconds int64     `json:"every_seconds"`
	Running      bool      `json:"running"`
	NextRun      time.Time `json:"next_run"`
	LastRun      *Run      `json:"last_run,omitempty"`
}

// Status lists the jobs with their latest run.
func (r *Runner) Status(ctx context.Context) ([]JobStatus, error) {
	out := make([]JobStatus, 0, len(r.jobs))
	for _, e := range r.jobs {
		var last Run
		err := r.db.WithContext(ctx).Where("job = ?", e.job.Name).Order("started_at DESC, id DESC").Take(&last).Error
		s := JobStatus{
			Name: e.job.Name, Title: e.job.Title, Description: e.job.Description,
			EverySeconds: int64(e.job.Every / time.Second),
			Running:      e.isRunning(), NextRun: e.next(),
		}
		switch {
		case err == nil:
			s.LastRun = &last
		case !errors.Is(err, gorm.ErrRecordNotFound):
			return nil, err
		}
		out = append(out, s)
	}
	return out, nil
}

// Runs returns a job's latest runs, newest first.
func (r *Runner) Runs(ctx context.Context, name string, limit int) ([]Run, error) {
	if r.find(name) == nil {
		return nil, ErrUnknownJob
	}
	var runs []Run
	err := r.db.WithContext(ctx).Where("job = ?", name).Order("started_at DESC, id DESC").Limit(limit).Find(&runs).Error
	return runs, err
}

// PurgeRuns deletes runs that started before cutoff.
func (r *Runner) PurgeRuns(ctx context.Context, cutoff time.Time) (int64, error) {
	res := r.db.WithContext(ctx).Where("started_at < ?", cutoff).Delete(&Run{})
	return res.RowsAffected, res.Error
}

func (e *entry) setRunning(v bool) { e.mu.Lock(); e.running = v; e.mu.Unlock() }
func (e *entry) isRunning() bool   { e.mu.Lock(); defer e.mu.Unlock(); return e.running }
func (e *entry) setNext(t time.Time) {
	e.mu.Lock()
	e.nextRun = t
	e.mu.Unlock()
}
func (e *entry) next() time.Time { e.mu.Lock(); defer e.mu.Unlock(); return e.nextRun }
