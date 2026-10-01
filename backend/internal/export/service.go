package export

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/codetheuri/tusk/internal/customer"
	"github.com/codetheuri/tusk/internal/finance"
	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/internal/report"
	"github.com/codetheuri/tusk/pkg/authz"
	"github.com/codetheuri/tusk/pkg/document"
)

// MaxDays is the longest period one report covers: a year keeps the largest
// report (every collection) to a file phones open easily.
const MaxDays = 366

// Domain errors, mapped to HTTP status codes by the handler.
var (
	ErrUnknownReport = errors.New("no such report")
	ErrForbidden     = errors.New("forbidden")
	ErrInvalid       = errors.New("invalid request")
)

// Format is a file format.
type Format string

const (
	PDF  Format = "pdf"
	XLSX Format = "xlsx"
)

// ContentType is the MIME type of the format.
func (f Format) ContentType() string {
	if f == XLSX {
		return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
	}
	return "application/pdf"
}

// Request is what to put in a report.
type Request struct {
	Report      string
	Format      Format
	From, To    string // YYYY-MM-DD; default: this month to today
	MemberID    string
	CustomerID  string
	CollectorID uint
	Shift       string
	Status      string
}

// File is a finished report.
type File struct {
	Name        string
	ContentType string
	Data        []byte
}

// Service builds reports.
type Service struct {
	repo      *Repository
	reports   *report.Service
	customers *customer.Service
	finance   *finance.Service
	authz     *authz.Evaluator
	now       func() time.Time
}

// NewService creates the export service.
func NewService(repo *Repository, reports *report.Service, customers *customer.Service, fin *finance.Service, evaluator *authz.Evaluator) *Service {
	return &Service{repo: repo, reports: reports, customers: customers, finance: fin, authz: evaluator, now: time.Now}
}

// Catalog lists the reports the caller may download.
func (s *Service) Catalog(ctx context.Context) []Report {
	var out []Report
	for _, r := range catalog {
		if s.allowed(ctx, r.permission) {
			out = append(out, r)
		}
	}
	return out
}

func (s *Service) allowed(ctx context.Context, permission string) bool {
	sub, ok := authz.DefaultSubjectExtractor(ctx)
	if !ok {
		return false
	}
	yes, err := s.authz.IsAuthorized(ctx, sub, authz.RequirePermissionPolicy{Permission: permission})
	return err == nil && yes
}

// input is what a report builder gets: the checked request and a document
// with the letterhead, title and period already filled in.
type input struct {
	saccoID  string
	from, to time.Time
	req      Request
	// collectorID limits rows to one collector: the caller when they see
	// only their own records, else the requested one (0 = everyone).
	collectorID uint
	doc         *document.Document
}

type builder func(ctx context.Context, s *Service, in *input) error

// Build makes the requested report.
func (s *Service) Build(ctx context.Context, req Request) (*File, error) {
	rep, ok := findReport(req.Report)
	if !ok {
		return nil, fmt.Errorf("%w: %s", ErrUnknownReport, req.Report)
	}
	if !s.allowed(ctx, rep.permission) {
		return nil, fmt.Errorf("%w: you may not download the %s report", ErrForbidden, rep.Title)
	}
	if req.Format != PDF && req.Format != XLSX {
		return nil, fmt.Errorf("%w: format must be pdf or xlsx", ErrInvalid)
	}
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, fmt.Errorf("%w: a Sacco account is needed to download reports", ErrForbidden)
	}
	from, to, err := s.period(req, rep.AsAt)
	if err != nil {
		return nil, err
	}
	switch {
	case rep.Needs == NeedsFarmer && req.MemberID == "":
		return nil, fmt.Errorf("%w: choose a farmer", ErrInvalid)
	case rep.Needs == NeedsCustomer && req.CustomerID == "":
		return nil, fmt.Errorf("%w: choose a customer", ErrInvalid)
	}

	letterhead, err := s.repo.Letterhead(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	userID := middleware.GetUserID(ctx)
	in := &input{
		saccoID: saccoID, from: from, to: to, req: req,
		collectorID: req.CollectorID,
		doc: &document.Document{
			Letterhead:  letterhead,
			Title:       rep.Title,
			Period:      document.FormatPeriod(from, to),
			Landscape:   rep.landscape,
			GeneratedBy: s.repo.StaffName(ctx, userID),
			GeneratedAt: s.now().In(nairobi),
		},
	}
	if rep.AsAt {
		in.doc.Period = "As at " + to.Format("Mon 2 Jan 2006")
	}
	// Someone who sees only their own records gets only their own rows.
	if !middleware.SeesAllRecords(ctx) && !middleware.IsSuperUser(ctx) {
		in.collectorID = userID
	}
	if err := rep.build(ctx, s, in); err != nil {
		return nil, err
	}

	var data []byte
	if req.Format == XLSX {
		data, err = document.XLSX(in.doc)
	} else {
		data, err = document.PDF(in.doc)
	}
	if err != nil {
		return nil, err
	}
	return &File{Name: fileName(rep, in, req.Format), ContentType: req.Format.ContentType(), Data: data}, nil
}

// period checks the requested dates: by default this month so far; at most
// MaxDays; never after today. An "as at" report is as at today.
func (s *Service) period(req Request, asAt bool) (time.Time, time.Time, error) {
	now := s.now().In(nairobi)
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	if asAt {
		return today, today, nil
	}
	from := time.Date(today.Year(), today.Month(), 1, 0, 0, 0, 0, time.UTC)
	to := today
	var err error
	if v := strings.TrimSpace(req.From); v != "" {
		if from, err = time.Parse(dateLayout, v); err != nil {
			return from, to, fmt.Errorf("%w: from must be a date like 2026-10-01", ErrInvalid)
		}
	}
	if v := strings.TrimSpace(req.To); v != "" {
		if to, err = time.Parse(dateLayout, v); err != nil {
			return from, to, fmt.Errorf("%w: to must be a date like 2026-10-31", ErrInvalid)
		}
	}
	if to.After(today) {
		to = today
	}
	switch {
	case from.After(to):
		return from, to, fmt.Errorf("%w: the period starts after it ends", ErrInvalid)
	case to.Sub(from) >= MaxDays*24*time.Hour:
		return from, to, fmt.Errorf("%w: choose a period of at most a year", ErrInvalid)
	}
	return from, to, nil
}

// fileName is e.g. "maru-farmer-payouts-2026-10-01-to-2026-10-31.pdf".
func fileName(rep Report, in *input, f Format) string {
	parts := []string{slug(in.doc.Letterhead.Name), rep.Key}
	if in.doc.Subject != "" {
		parts = append(parts, slug(strings.SplitN(in.doc.Subject, "·", 2)[0]))
	}
	if rep.AsAt {
		parts = append(parts, in.to.Format(dateLayout))
	} else {
		parts = append(parts, in.from.Format(dateLayout), "to", in.to.Format(dateLayout))
	}
	return strings.Join(parts, "-") + "." + string(f)
}

func slug(s string) string {
	var b strings.Builder
	dash := false
	for _, c := range strings.ToLower(strings.TrimSpace(s)) {
		switch {
		case c >= 'a' && c <= 'z', c >= '0' && c <= '9':
			b.WriteRune(c)
			dash = false
		case !dash && b.Len() > 0:
			b.WriteByte('-')
			dash = true
		}
	}
	out := strings.TrimSuffix(b.String(), "-")
	if len(out) > 40 {
		out = strings.TrimSuffix(out[:40], "-")
	}
	return out
}

// nairobi is the time zone dates and times are shown in.
var nairobi = func() *time.Location {
	if loc, err := time.LoadLocation("Africa/Nairobi"); err == nil {
		return loc
	}
	return time.FixedZone("EAT", 3*60*60)
}()
