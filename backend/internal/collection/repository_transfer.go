package collection

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
	"github.com/codetheuri/tusk/pkg/query"
)

// auditEntityTransfer is the entity_type used for transfer audit entries.
const auditEntityTransfer = "milk_transfer"

// staffNameSQL is a user's full name, or their username when no name is set.
const staffNameSQL = "COALESCE(NULLIF(TRIM(COALESCE(p.first_name, '') || ' ' || COALESCE(p.last_name, '')), ''), u.username)"

// recipientsQuery selects active staff of a Sacco who record milk (hold
// milk.collections.create through a role), so milk goes only to someone
// who can account for it.
func (r *Repository) recipientsQuery(ctx context.Context, saccoID string) *gorm.DB {
	return r.db.WithContext(ctx).Table("users u").
		Select("u.id, u.username, "+staffNameSQL+" AS name").
		Joins("LEFT JOIN user_profiles p ON p.user_id = u.id").
		Where("u.sacco_id = ? AND u.is_active = ?", saccoID, true).
		Where(`EXISTS (SELECT 1 FROM user_roles ur JOIN role_permissions rp ON rp.role_id = ur.role_id
			WHERE ur.user_id = u.id AND rp.permission_name = ?)`, PermMilkCollectionsCreate)
}

// ListTransferRecipients returns the collectors of the caller's Sacco milk
// can be transferred to, except exceptID, by name.
func (r *Repository) ListTransferRecipients(ctx context.Context, exceptID uint) ([]TransferRecipient, error) {
	saccoID, _ := middleware.GetSaccoID(ctx)
	var rows []TransferRecipient
	err := r.recipientsQuery(ctx, saccoID).
		Where("u.id <> ?", exceptID).
		Order("name").
		Scan(&rows).Error
	return rows, err
}

// FindTransferRecipient loads one possible recipient in the caller's Sacco.
func (r *Repository) FindTransferRecipient(ctx context.Context, id uint) (*TransferRecipient, error) {
	saccoID, _ := middleware.GetSaccoID(ctx)
	var rows []TransferRecipient
	if err := r.recipientsQuery(ctx, saccoID).Where("u.id = ?", id).Scan(&rows).Error; err != nil {
		return nil, err
	}
	if len(rows) == 0 {
		return nil, fmt.Errorf("%w: collector not found in this Sacco, or not active", ErrNotFound)
	}
	return &rows[0], nil
}

// staffNames maps user IDs to display names.
func (r *Repository) staffNames(ctx context.Context, ids []uint) map[uint]string {
	names := make(map[uint]string, len(ids))
	if len(ids) == 0 {
		return names
	}
	var rows []struct {
		ID   uint
		Name string
	}
	if err := r.db.WithContext(ctx).Table("users u").
		Select("u.id, "+staffNameSQL+" AS name").
		Joins("LEFT JOIN user_profiles p ON p.user_id = u.id").
		Where("u.id IN ?", ids).
		Scan(&rows).Error; err == nil {
		for _, row := range rows {
			names[row.ID] = row.Name
		}
	}
	return names
}

func (r *Repository) nameTransfers(ctx context.Context, transfers []MilkTransfer) {
	ids := make([]uint, 0, 2*len(transfers))
	for _, t := range transfers {
		ids = append(ids, t.FromCollectorID, t.ToCollectorID)
	}
	names := r.staffNames(ctx, ids)
	for i := range transfers {
		transfers[i].FromCollectorName = names[transfers[i].FromCollectorID]
		transfers[i].ToCollectorName = names[transfers[i].ToCollectorID]
	}
}

// CreateTransfer saves a transfer and its audit entry atomically.
func (r *Repository) CreateTransfer(ctx context.Context, t *MilkTransfer, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(t).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// UpdateTransfer saves a corrected or cancelled transfer and its audit entry
// atomically.
func (r *Repository) UpdateTransfer(ctx context.Context, t *MilkTransfer, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Scopes(query.TenantScope(ctx)).Save(t).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// FindTransferByID loads a transfer of the caller's Sacco, with names.
func (r *Repository) FindTransferByID(ctx context.Context, id string) (*MilkTransfer, error) {
	var t MilkTransfer
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&t).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("%w: milk transfer not found", ErrNotFound)
		}
		return nil, err
	}
	one := []MilkTransfer{t}
	r.nameTransfers(ctx, one)
	return &one[0], nil
}

// TransferHistory returns the audit trail of one transfer, oldest first.
func (r *Repository) TransferHistory(ctx context.Context, t *MilkTransfer) ([]audit.Log, error) {
	return audit.List(ctx, r.db, t.SaccoID, auditEntityTransfer, t.ID)
}

// TransferListFilter narrows a transfer list.
type TransferListFilter struct {
	// CollectorID matches transfers sent or received by that collector.
	CollectorID uint
	// Direction "in" or "out", relative to CollectorID.
	Direction        string
	FromDate, ToDate string
	IncludeVoided    bool
}

// ListTransfers lists transfers, newest first. Collectors see only transfers
// they sent or received; admins and board members see all.
func (r *Repository) ListTransfers(ctx context.Context, q query.Query, f TransferListFilter) ([]MilkTransfer, query.Meta, error) {
	cfg := query.Config{
		DefaultSort:    "-transfer_date",
		DefaultPerPage: 30,
		MaxPerPage:     100,
		AllowedSorts: map[string]string{
			"transfer_date":   "milk_transfers.transfer_date",
			"quantity_litres": "milk_transfers.quantity_litres",
			"created_at":      "milk_transfers.created_at",
		},
		AllowedFilters: map[string]string{"transfer_date": "milk_transfers.transfer_date"},
	}
	session := r.db.Model(&MilkTransfer{}).Scopes(query.TenantScope(ctx))

	if !middleware.SeesAllRecords(ctx) {
		me := middleware.GetUserID(ctx)
		session = session.Where("(milk_transfers.from_collector_id = ? OR milk_transfers.to_collector_id = ?)", me, me)
	}
	if f.CollectorID > 0 {
		switch strings.ToLower(f.Direction) {
		case "in":
			session = session.Where("milk_transfers.to_collector_id = ?", f.CollectorID)
		case "out":
			session = session.Where("milk_transfers.from_collector_id = ?", f.CollectorID)
		default:
			session = session.Where("(milk_transfers.from_collector_id = ? OR milk_transfers.to_collector_id = ?)", f.CollectorID, f.CollectorID)
		}
	}
	if f.FromDate != "" {
		session = session.Where("milk_transfers.transfer_date >= ?", f.FromDate)
	}
	if f.ToDate != "" {
		session = session.Where("milk_transfers.transfer_date <= ?", f.ToDate)
	}
	if !f.IncludeVoided {
		session = session.Where("milk_transfers.voided_at IS NULL")
	}
	// Newest day first; within a day, latest recorded first.
	if len(q.Sorts) == 0 {
		q.Sorts = []query.Sort{
			{Field: "transfer_date", Order: query.SortDesc},
			{Field: "created_at", Order: query.SortDesc},
		}
	}

	transfers, meta, err := query.Paginate[MilkTransfer](ctx, session, q, cfg)
	if err != nil {
		return nil, meta, err
	}
	r.nameTransfers(ctx, transfers)
	return transfers, meta, nil
}

// transferTotals is one collector's transfers in a period.
type transferTotals struct {
	Received, TransferredOut float64
}

// collectorTransferTotals sums a collector's non-cancelled transfers in
// [fromDate, toDate] in each direction.
func (r *Repository) collectorTransferTotals(ctx context.Context, saccoID string, collectorID uint, fromDate, toDate string) (transferTotals, error) {
	var t transferTotals
	err := r.db.WithContext(ctx).Table("milk_transfers").
		Select(`COALESCE(SUM(CASE WHEN to_collector_id = ? THEN quantity_litres ELSE 0 END), 0) AS received,
			COALESCE(SUM(CASE WHEN from_collector_id = ? THEN quantity_litres ELSE 0 END), 0) AS transferred_out`,
			collectorID, collectorID).
		Where("sacco_id = ? AND deleted_at IS NULL AND voided_at IS NULL AND transfer_date BETWEEN ? AND ?", saccoID, fromDate, toDate).
		Where("(from_collector_id = ? OR to_collector_id = ?)", collectorID, collectorID).
		Scan(&t).Error
	return t, err
}

// dayTransfers lists a collector's non-cancelled transfers on one day,
// oldest first.
func (r *Repository) dayTransfers(ctx context.Context, saccoID string, collectorID uint, date string) ([]MilkTransfer, error) {
	var transfers []MilkTransfer
	err := r.db.WithContext(ctx).
		Where("sacco_id = ? AND voided_at IS NULL AND transfer_date = ?", saccoID, date).
		Where("(from_collector_id = ? OR to_collector_id = ?)", collectorID, collectorID).
		Order("created_at").
		Find(&transfers).Error
	if err != nil {
		return nil, err
	}
	r.nameTransfers(ctx, transfers)
	return transfers, nil
}
