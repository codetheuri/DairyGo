package collection

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
)

// Records made on the wrong account. A collector whose phone fails may work
// on a colleague's phone that is still signed in, so their intakes, sales,
// spoilage and customer payments are saved as the colleague's. DairyGo
// support (the platform console) moves those records to the collector who
// really made them, with a reason. Only who made them changes: litres,
// prices, the day and the farmer's pay stay as they are, so a paid month may
// be corrected too. Each collector's daily balance is worked out from the
// records, so it follows at once. Transfers are not moved: one belongs to
// two collectors, and a wrong one is voided and entered again.

const auditEntitySpoilage = "milk_spoilage"
const auditEntityPayment = "customer_payment"

// Kinds of record that can be moved to another collector.
const (
	RecordIntake   = "INTAKE"
	RecordSale     = "SALE"
	RecordSpoilage = "SPOILAGE"
	RecordPayment  = "PAYMENT"
)

// maxReassign bounds one move; a collector's day is far smaller.
const maxReassign = 500

// movable is where each kind is stored and which column names its maker.
var movable = map[string]struct {
	table, column, entity string
	softDeleted           bool
}{
	RecordIntake:   {"milk_collections", "collector_id", auditEntityCollection, true},
	RecordSale:     {"milk_sales", "collector_id", auditEntitySale, true},
	RecordSpoilage: {"milk_spoilage", "collector_id", auditEntitySpoilage, true},
	RecordPayment:  {"customer_payments", "recorded_by_id", auditEntityPayment, false},
}

// DayRecord is one record a collector made on a day, as the console lists
// them to choose which to move.
type DayRecord struct {
	Kind       string    `json:"kind" doc:"INTAKE, SALE, SPOILAGE or PAYMENT"`
	ID         string    `json:"id"`
	At         time.Time `json:"at" doc:"When it was saved"`
	Shift      string    `json:"shift,omitempty" doc:"Intake only"`
	Litres     float64   `json:"litres"`
	Amount     float64   `json:"amount" doc:"KES: the farmer's pay, the sale, or the payment"`
	Party      string    `json:"party" doc:"The farmer, the customer, or what spoiled"`
	Voided     bool      `json:"voided"`
	LateReason *string   `json:"late_reason,omitempty"`
}

// RecordRef names one record to move.
type RecordRef struct {
	Kind string `json:"kind" enum:"INTAKE,SALE,SPOILAGE,PAYMENT"`
	ID   string `json:"id"`
}

// ReassignRequest moves records from the account they were saved on to the
// collector who made them.
type ReassignRequest struct {
	FromCollectorID uint        `json:"from_collector_id" doc:"The account the records were saved on"`
	ToCollectorID   uint        `json:"to_collector_id" doc:"The collector who really made them"`
	Records         []RecordRef `json:"records"`
	Reason          string      `json:"reason" doc:"Why, kept in each record's history"`
}

// ReassignResult says how many records moved, by kind.
type ReassignResult struct {
	Moved  int            `json:"moved"`
	ByKind map[string]int `json:"by_kind"`
	From   string         `json:"from"`
	To     string         `json:"to"`
}

// checkReassign validates a move and groups its record IDs by kind.
func checkReassign(req *ReassignRequest) (map[string][]string, string, error) {
	why := strings.TrimSpace(req.Reason)
	switch {
	case len(why) < 3:
		return nil, "", fmt.Errorf("say why the records are being moved (reason)")
	case req.FromCollectorID == 0 || req.ToCollectorID == 0:
		return nil, "", fmt.Errorf("choose the account the records are on and the collector to move them to")
	case req.FromCollectorID == req.ToCollectorID:
		return nil, "", fmt.Errorf("the records are already that collector's; choose someone else")
	case len(req.Records) == 0:
		return nil, "", fmt.Errorf("choose at least one record to move")
	case len(req.Records) > maxReassign:
		return nil, "", fmt.Errorf("move at most %d records at a time", maxReassign)
	}
	byKind := map[string][]string{}
	seen := map[RecordRef]bool{}
	for _, r := range req.Records {
		if _, ok := movable[r.Kind]; !ok {
			return nil, "", fmt.Errorf("%s records cannot be moved", r.Kind)
		}
		if r.ID == "" || seen[r] {
			return nil, "", fmt.Errorf("each record must be named once")
		}
		seen[r] = true
		byKind[r.Kind] = append(byKind[r.Kind], r.ID)
	}
	return byKind, why, nil
}

// CollectorDay lists what a collector's account saved on a day: intakes,
// sales and spoilage for that day and customer payments dated that day,
// in the order they were saved.
func (s *Service) CollectorDay(ctx context.Context, collectorID uint, day time.Time) ([]DayRecord, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, fmt.Errorf("sacco context is required")
	}
	return s.repo.CollectorDay(ctx, saccoID, collectorID, day.Format(dateLayout))
}

// Reassign moves records saved on one collector's account to the collector
// who made them. Platform operators only. Every record must still be on the
// from account, or nothing moves.
func (s *Service) Reassign(ctx context.Context, req *ReassignRequest) (*ReassignResult, error) {
	if !middleware.IsSuperUser(ctx) {
		return nil, fmt.Errorf("%w: only DairyGo support can move records to another collector", ErrForbidden)
	}
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, fmt.Errorf("sacco context is required")
	}
	byKind, why, err := checkReassign(req)
	if err != nil {
		return nil, err
	}
	to, err := s.repo.FindTransferRecipient(ctx, req.ToCollectorID)
	if err != nil {
		return nil, err
	}
	from := s.repo.staffNames(ctx, []uint{req.FromCollectorID})[req.FromCollectorID]
	if from == "" {
		return nil, fmt.Errorf("%w: the account the records are on was not found", ErrNotFound)
	}
	change := fmt.Sprintf("Recorded by %s → %s", from, to.Name)
	actor := middleware.GetUserID(ctx)
	result := &ReassignResult{ByKind: map[string]int{}, From: from, To: to.Name}
	var entries []audit.Entry
	for kind, ids := range byKind {
		m := movable[kind]
		for _, id := range ids {
			entries = append(entries, audit.Entry{
				SaccoID: saccoID, EntityType: m.entity, EntityID: id, Action: audit.ActionUpdate,
				ActorID: actor, Reason: &why,
				OldValues: map[string]any{m.column: req.FromCollectorID, "recorded_by": from},
				NewValues: map[string]any{m.column: req.ToCollectorID, "recorded_by": to.Name, "change": change},
			})
		}
		result.ByKind[kind] = len(ids)
		result.Moved += len(ids)
	}
	if err := s.repo.Reassign(ctx, saccoID, req.FromCollectorID, req.ToCollectorID, byKind, entries); err != nil {
		return nil, err
	}
	return result, nil
}
