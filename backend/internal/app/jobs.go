package app

import (
	"context"
	"fmt"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/auth"
	"github.com/codetheuri/tusk/internal/idempotency"
	"github.com/codetheuri/tusk/internal/jobs"
	"github.com/codetheuri/tusk/internal/member"
	"github.com/codetheuri/tusk/internal/superadmin"
	"github.com/codetheuri/tusk/pkg/logger"
)

const day = 24 * time.Hour

// How long records kept only for troubleshooting are kept.
const (
	keepFailedRequests = 30 * day
	keepJobRuns        = 90 * day
	// Saved answers matter only while a phone may retry (minutes).
	keepIdempotencyKeys = 2 * day
	// Ended sessions matter only while they could be presented again.
	keepEndedSessions = 7 * day
)

// newJobRunner lists the API's background jobs. Each runs once when the API
// starts and then every Every; the platform console shows them (Background
// jobs) and can run one now. To add a job, add it here.
func newJobRunner(db *gorm.DB, log logger.Logger, platform *superadmin.Repository,
	keys *idempotency.Store, sessions *auth.Repository) *jobs.Runner {
	runner := jobs.NewRunner(db, log)
	members := member.NewRepository(db)

	runner.Add(jobs.Job{
		Name:        "mark-idle-farmers",
		Title:       "Mark idle farmers inactive",
		Description: "Active farmers who brought no milk for their Sacco's period (Settings: days without milk) become inactive.",
		Every:       day,
		Run: func(ctx context.Context) (string, error) {
			n, err := members.MarkIdleInactive(ctx, time.Now())
			return fmt.Sprintf("%d farmers marked inactive", n), err
		},
	})

	runner.Add(jobs.Job{
		Name:        "clean-old-logs",
		Title:       "Clear old logs",
		Description: "Deletes failed-request logs older than 30 days and background job runs older than 90 days.",
		Every:       day,
		Run: func(ctx context.Context) (string, error) {
			logs, err := platform.PurgeSystemLogs(ctx, time.Now().Add(-keepFailedRequests))
			if err != nil {
				return "", err
			}
			runs, err := runner.PurgeRuns(ctx, time.Now().Add(-keepJobRuns))
			return fmt.Sprintf("%d failed-request logs and %d job runs deleted", logs, runs), err
		},
	})

	runner.Add(jobs.Job{
		Name:        "clean-retries-and-sessions",
		Title:       "Clear saved retries and ended sessions",
		Description: "Deletes saved answers to app requests older than 2 days and sessions that ended over 7 days ago.",
		Every:       day,
		Run: func(ctx context.Context) (string, error) {
			k, err := keys.Purge(ctx, time.Now().Add(-keepIdempotencyKeys))
			if err != nil {
				return "", err
			}
			s, err := sessions.PurgeRefreshTokens(ctx, time.Now().Add(-keepEndedSessions))
			return fmt.Sprintf("%d saved retries and %d ended sessions deleted", k, s), err
		},
	})

	return runner
}
