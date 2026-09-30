package jobs

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/pkg/logger"
)

var dbCount atomic.Int64

func newRunner(t *testing.T) *Runner {
	t.Helper()
	// A database of its own, even when a test is repeated (-count).
	name := fmt.Sprintf("file:%s-%d?mode=memory&cache=shared", t.Name(), dbCount.Add(1))
	db, err := gorm.Open(sqlite.Open(name), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	// SQLite in memory allows one writer at a time: share one connection
	// so concurrent jobs queue instead of failing with "table is locked".
	sqlDB, err := db.DB()
	if err != nil {
		t.Fatal(err)
	}
	sqlDB.SetMaxOpenConns(1)
	t.Cleanup(func() { _ = sqlDB.Close() })
	if err := db.AutoMigrate(&Run{}); err != nil {
		t.Fatal(err)
	}
	return NewRunner(db, logger.NewConsoleLogger())
}

// eventually waits up to 2s for ok to hold.
func eventually(t *testing.T, what string, ok func() bool) {
	t.Helper()
	for deadline := time.Now().Add(2 * time.Second); time.Now().Before(deadline); time.Sleep(5 * time.Millisecond) {
		if ok() {
			return
		}
	}
	t.Fatalf("timed out waiting for %s", what)
}

func runsOf(t *testing.T, r *Runner, job string) []Run {
	t.Helper()
	runs, err := r.Runs(context.Background(), job, 10)
	if err != nil {
		t.Fatal(err)
	}
	return runs
}

func finished(runs []Run, n int) bool {
	if len(runs) < n {
		return false
	}
	for _, run := range runs {
		if run.Status == StatusRunning {
			return false
		}
	}
	return true
}

func TestRunsAtStartAndRecordsTheOutcome(t *testing.T) {
	r := newRunner(t)
	r.Add(Job{Name: "ok", Every: time.Hour, Run: func(context.Context) (string, error) { return "3 farmers marked inactive", nil }})
	r.Add(Job{Name: "bad", Every: time.Hour, Run: func(context.Context) (string, error) { return "", errors.New("database is down") }})
	r.Add(Job{Name: "panics", Every: time.Hour, Run: func(context.Context) (string, error) { panic("nil map") }})
	ctx, cancel := context.WithCancel(context.Background())
	r.Start(ctx)
	defer func() { cancel(); r.Wait() }()

	eventually(t, "all three runs", func() bool {
		return finished(runsOf(t, r, "ok"), 1) && finished(runsOf(t, r, "bad"), 1) && finished(runsOf(t, r, "panics"), 1)
	})
	ok := runsOf(t, r, "ok")[0]
	if ok.Status != StatusOK || ok.Trigger != TriggerStart || *ok.Summary != "3 farmers marked inactive" || ok.FinishedAt == nil {
		t.Errorf("ok run = %+v", ok)
	}
	bad := runsOf(t, r, "bad")[0]
	if bad.Status != StatusFailed || *bad.Error != "database is down" {
		t.Errorf("bad run = %+v", bad)
	}
	p := runsOf(t, r, "panics")[0]
	if p.Status != StatusFailed || !strings.HasPrefix(*p.Error, "panic: nil map") {
		t.Errorf("panicking run = %+v", p)
	}

	// The API is still up, and the status lists every job.
	status, err := r.Status(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if len(status) != 3 || status[0].Name != "ok" || status[0].LastRun == nil || status[0].EverySeconds != 3600 {
		t.Fatalf("status = %+v", status)
	}
	if next := status[0].NextRun; next.Before(time.Now().Add(59*time.Minute)) || next.After(time.Now().Add(61*time.Minute)) {
		t.Errorf("next run = %v, want in about an hour", next)
	}
}

func TestRunNow(t *testing.T) {
	r := newRunner(t)
	release := make(chan struct{})
	var calls atomic.Int32
	r.Add(Job{Name: "slow", Every: time.Hour, Run: func(ctx context.Context) (string, error) {
		n := calls.Add(1)
		if n == 2 { // the manual run waits until the test lets it finish
			select {
			case <-release:
			case <-ctx.Done():
			}
		}
		return "done", nil
	}})
	ctx, cancel := context.WithCancel(context.Background())
	r.Start(ctx)
	defer func() { cancel(); r.Wait() }()
	eventually(t, "the start-up run", func() bool { return finished(runsOf(t, r, "slow"), 1) })

	if err := r.RunNow("nope", 1); !errors.Is(err, ErrUnknownJob) {
		t.Errorf("unknown job: %v", err)
	}
	if err := r.RunNow("slow", 7); err != nil {
		t.Fatal(err)
	}
	eventually(t, "the manual run to start", func() bool { return r.find("slow").isRunning() })
	if err := r.RunNow("slow", 7); !errors.Is(err, ErrBusy) {
		t.Errorf("while running: %v, want ErrBusy", err)
	}
	close(release)
	eventually(t, "the manual run to finish", func() bool { return finished(runsOf(t, r, "slow"), 2) })
	manual := runsOf(t, r, "slow")[0]
	if manual.Trigger != TriggerManual || manual.TriggeredBy == nil || *manual.TriggeredBy != 7 || manual.Status != StatusOK {
		t.Errorf("manual run = %+v", manual)
	}
}

func TestStartClosesInterruptedRuns(t *testing.T) {
	r := newRunner(t)
	if err := r.db.Create(&Run{Job: "old", Trigger: TriggerSchedule, Status: StatusRunning, StartedAt: time.Now().Add(-time.Hour)}).Error; err != nil {
		t.Fatal(err)
	}
	r.Add(Job{Name: "old", Every: time.Hour, Run: func(context.Context) (string, error) { return "", nil }})
	ctx, cancel := context.WithCancel(context.Background())
	r.Start(ctx)
	defer func() { cancel(); r.Wait() }()
	eventually(t, "both runs finished", func() bool { return finished(runsOf(t, r, "old"), 2) })
	old := runsOf(t, r, "old")[1]
	if old.Status != StatusFailed || !strings.Contains(*old.Error, "interrupted") {
		t.Errorf("interrupted run = %+v", old)
	}
}

func TestStopsWhenCancelled(t *testing.T) {
	r := newRunner(t)
	r.Add(Job{Name: "waits", Every: time.Hour, Run: func(ctx context.Context) (string, error) {
		<-ctx.Done() // a long job that honours cancellation
		return "", ctx.Err()
	}})
	ctx, cancel := context.WithCancel(context.Background())
	r.Start(ctx)
	eventually(t, "the run to start", func() bool { return r.find("waits").isRunning() })
	cancel()
	done := make(chan struct{})
	go func() { r.Wait(); close(done) }()
	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("Wait did not return after cancel")
	}
	// The cancelled run is still recorded as finished.
	if run := runsOf(t, r, "waits")[0]; run.Status != StatusFailed || run.FinishedAt == nil {
		t.Errorf("cancelled run = %+v", run)
	}
}

func TestPurgeRuns(t *testing.T) {
	r := newRunner(t)
	for _, age := range []time.Duration{100 * 24 * time.Hour, time.Hour} {
		if err := r.db.Create(&Run{Job: "x", Trigger: TriggerSchedule, Status: StatusOK, StartedAt: time.Now().Add(-age)}).Error; err != nil {
			t.Fatal(err)
		}
	}
	n, err := r.PurgeRuns(context.Background(), time.Now().Add(-90*24*time.Hour))
	if err != nil || n != 1 {
		t.Fatalf("purged %d, %v; want 1", n, err)
	}
}
