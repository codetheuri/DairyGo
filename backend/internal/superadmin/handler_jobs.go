package superadmin

import (
	"context"
	"errors"

	"github.com/danielgtaylor/huma/v2"

	"github.com/codetheuri/tusk/internal/jobs"
	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/response"
)

// JobsHandler shows the API's background jobs in the console.
type JobsHandler struct {
	runner *jobs.Runner
}

type JobsData struct {
	Jobs []jobs.JobStatus `json:"jobs"`
}

type JobsOutput struct {
	Body response.Data[JobsData]
}

type JobNameInput struct {
	Name string `path:"name" doc:"Job name, e.g. mark-idle-farmers"`
}

type JobRunsInput struct {
	Name  string `path:"name" doc:"Job name"`
	Limit int    `query:"limit" minimum:"1" maximum:"100" default:"20" doc:"How many runs"`
}

type JobRunsData struct {
	Runs []jobs.Run `json:"runs"`
}

type JobRunsOutput struct {
	Body response.Data[JobRunsData]
}

type JobStartedOutput struct {
	Status int `status:"202"`
	Body   response.Data[map[string]string]
}

func (h *JobsHandler) List(ctx context.Context, _ *struct{}) (*JobsOutput, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, toHTTPError(err)
	}
	list, err := h.runner.Status(ctx)
	if err != nil {
		return nil, huma.Error500InternalServerError("Could not read the jobs", err)
	}
	resp := &JobsOutput{}
	resp.Body.Success, resp.Body.Message = true, "Background jobs"
	resp.Body.Data.Jobs = list
	return resp, nil
}

func (h *JobsHandler) Runs(ctx context.Context, in *JobRunsInput) (*JobRunsOutput, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, toHTTPError(err)
	}
	runs, err := h.runner.Runs(ctx, in.Name, in.Limit)
	if errors.Is(err, jobs.ErrUnknownJob) {
		return nil, huma.Error404NotFound("No job called " + in.Name)
	}
	if err != nil {
		return nil, huma.Error500InternalServerError("Could not read the runs", err)
	}
	resp := &JobRunsOutput{}
	resp.Body.Success, resp.Body.Message = true, "Job runs"
	resp.Body.Data.Runs = runs
	return resp, nil
}

func (h *JobsHandler) RunNow(ctx context.Context, in *JobNameInput) (*JobStartedOutput, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, toHTTPError(err)
	}
	switch err := h.runner.RunNow(in.Name, middleware.GetUserID(ctx)); {
	case errors.Is(err, jobs.ErrUnknownJob):
		return nil, huma.Error404NotFound("No job called " + in.Name)
	case errors.Is(err, jobs.ErrBusy):
		return nil, huma.Error409Conflict("This job is already running. Wait for it to finish.")
	case err != nil:
		return nil, huma.Error500InternalServerError("Could not start the job", err)
	}
	resp := &JobStartedOutput{Status: 202}
	resp.Body.Success, resp.Body.Message = true, "The job has started"
	resp.Body.Data = map[string]string{"job": in.Name}
	return resp, nil
}
