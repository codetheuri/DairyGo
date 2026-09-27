package superadmin

import (
	"context"
	"errors"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/query"
	"github.com/codetheuri/tusk/pkg/reconcile"
)

// Repository reads across all Saccos. Queries are grouped by sacco_id so the
// overview costs the same number of queries however many Saccos exist.
type Repository struct {
	db *gorm.DB
}

// NewRepository creates a platform console repository.
func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// SaveFailedRequest implements middleware.FailureStore.
func (r *Repository) SaveFailedRequest(ctx context.Context, f middleware.FailedRequest) error {
	log := SystemLog{
		ID: uuid.New().String(), Level: f.Level, Method: f.Method, Path: truncate(f.Path, 255),
		Status: f.Status, UserID: f.UserID, SaccoID: f.SaccoID, DurationMS: f.DurationMS,
		Query: optional(f.Query), Message: optional(f.Message), RequestID: optional(f.RequestID),
		IP: optional(f.IP), UserAgent: optional(f.UserAgent), CreatedAt: time.Now(),
	}
	return r.db.WithContext(ctx).Omit("Username", "SaccoName").Create(&log).Error
}

// PurgeSystemLogs deletes failed-request logs older than the cutoff.
func (r *Repository) PurgeSystemLogs(ctx context.Context, before time.Time) (int64, error) {
	res := r.db.WithContext(ctx).Where("created_at < ?", before).Delete(&SystemLog{})
	return res.RowsAffected, res.Error
}

// Overview builds the platform summary and per-Sacco rows.
func (r *Repository) Overview(ctx context.Context) (*Overview, error) {
	now := time.Now()
	today := now.Format(reconcile.DateLayout)
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.Local).Format(reconcile.DateLayout)
	db := r.db.WithContext(ctx)

	var saccos []SaccoStats
	if err := db.Table("saccos").Select("id, code, name, status, created_at").
		Where("deleted_at IS NULL").Order("name").Scan(&saccos).Error; err != nil {
		return nil, err
	}

	type count struct {
		SaccoID string
		N       int64
	}
	var farmers, staff []count
	if err := db.Table("members").Select("sacco_id, COUNT(*) AS n").
		Where("status = 'ACTIVE' AND deleted_at IS NULL").Group("sacco_id").Scan(&farmers).Error; err != nil {
		return nil, err
	}
	if err := db.Table("users").Select("sacco_id, COUNT(*) AS n").
		Where("sacco_id IS NOT NULL").Group("sacco_id").Scan(&staff).Error; err != nil {
		return nil, err
	}

	var intake []struct {
		SaccoID string
		Litres  float64
		Amount  float64
		Today   float64
		Last    *time.Time
	}
	if err := db.Table("milk_collections").
		Select(`sacco_id,
			SUM(CASE WHEN collection_date >= ? THEN quantity_litres ELSE 0 END) AS litres,
			SUM(CASE WHEN collection_date >= ? THEN total_amount ELSE 0 END) AS amount,
			SUM(CASE WHEN collection_date = ? THEN quantity_litres ELSE 0 END) AS today,
			MAX(collection_date) AS last`, monthStart, monthStart, today).
		Where("status <> 'REJECTED' AND deleted_at IS NULL").
		Group("sacco_id").Scan(&intake).Error; err != nil {
		return nil, err
	}

	var sales []struct {
		SaccoID      string
		MonthRevenue float64
		Owed         float64
	}
	if err := db.Table("milk_sales").
		Select(`sacco_id,
			SUM(CASE WHEN sale_date >= ? THEN total_amount ELSE 0 END) AS month_revenue,
			SUM(total_amount - amount_paid) AS owed`, monthStart).
		Where("deleted_at IS NULL AND voided_at IS NULL").
		Group("sacco_id").Scan(&sales).Error; err != nil {
		return nil, err
	}

	var payments []struct {
		SaccoID string
		Paid    float64
	}
	if err := db.Table("customer_payments").Select("sacco_id, SUM(amount) AS paid").
		Where("voided_at IS NULL").Group("sacco_id").Scan(&payments).Error; err != nil {
		return nil, err
	}

	o := &Overview{}
	index := make(map[string]*SaccoStats, len(saccos))
	for i := range saccos {
		index[saccos[i].ID] = &saccos[i]
		o.SaccosTotal++
		switch saccos[i].Status {
		case "ACTIVE":
			o.SaccosActive++
		case "SUSPENDED":
			o.SaccosSuspended++
		default:
			o.SaccosInactive++
		}
	}
	for _, c := range farmers {
		if s := index[c.SaccoID]; s != nil {
			s.ActiveFarmers = c.N
			o.ActiveFarmers += c.N
		}
	}
	for _, c := range staff {
		if s := index[c.SaccoID]; s != nil {
			s.StaffCount = c.N
			o.StaffUsers += c.N
		}
	}
	for _, row := range intake {
		if s := index[row.SaccoID]; s != nil {
			s.MonthLitres, s.LastCollection = round2(row.Litres), row.Last
			o.MonthCollectedLitres += row.Litres
			o.MonthPayoutKES += row.Amount
			o.TodayCollectedLitres += row.Today
		}
	}
	for _, row := range sales {
		if s := index[row.SaccoID]; s != nil {
			s.MonthRevenueKES = round2(row.MonthRevenue)
			s.ReceivablesKES += row.Owed
			o.MonthSalesRevenueKES += row.MonthRevenue
		}
	}
	for _, row := range payments {
		if s := index[row.SaccoID]; s != nil {
			s.ReceivablesKES -= row.Paid
		}
	}
	for i := range saccos {
		saccos[i].ReceivablesKES = round2(saccos[i].ReceivablesKES)
		o.ReceivablesKES += saccos[i].ReceivablesKES
	}

	o.TodayCollectedLitres = round2(o.TodayCollectedLitres)
	o.MonthCollectedLitres = round2(o.MonthCollectedLitres)
	o.MonthPayoutKES = round2(o.MonthPayoutKES)
	o.MonthSalesRevenueKES = round2(o.MonthSalesRevenueKES)
	o.ReceivablesKES = round2(o.ReceivablesKES)

	dayAgo := now.Add(-24 * time.Hour)
	db.Table("system_logs").Where("created_at >= ?", dayAgo).Count(&o.FailedRequests24h)
	db.Table("system_logs").Where("created_at >= ? AND status >= 500", dayAgo).Count(&o.ServerErrors24h)

	o.Saccos = saccos
	return o, nil
}

// SaccoStatus returns a Sacco's status, or ErrNotFound if it does not exist.
func (r *Repository) SaccoStatus(ctx context.Context, saccoID string) (string, error) {
	var status string
	err := r.db.WithContext(ctx).Table("saccos").Select("status").
		Where("id = ? AND deleted_at IS NULL", saccoID).Take(&status).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return "", fmt.Errorf("%w: sacco not found", ErrNotFound)
	}
	return status, err
}

// StaffUsers lists a Sacco's user accounts with their role.
func (r *Repository) StaffUsers(ctx context.Context, saccoID string) ([]StaffUser, error) {
	var users []StaffUser
	err := r.db.WithContext(ctx).Table("users u").
		Select(`u.id, u.username, u.email, u.phone, COALESCE(p.first_name, '') AS first_name,
			COALESCE(p.last_name, '') AS last_name, COALESCE(MIN(ro.name), '') AS role_name,
			u.is_active, u.failed_login_attempts, u.locked_until, u.last_login_at, u.created_at`).
		Joins("LEFT JOIN user_profiles p ON p.user_id = u.id").
		Joins("LEFT JOIN user_roles ur ON ur.user_id = u.id").
		Joins("LEFT JOIN roles ro ON ro.id = ur.role_id").
		Where("u.sacco_id = ?", saccoID).
		Group("u.id, p.first_name, p.last_name").
		Order("u.created_at").
		Scan(&users).Error
	return users, err
}

// FindStaffUser loads a Sacco-bound user; platform accounts are never returned.
func (r *Repository) FindStaffUser(ctx context.Context, userID uint) (id uint, saccoID string, err error) {
	var row struct {
		ID      uint
		SaccoID *string
	}
	err = r.db.WithContext(ctx).Table("users").Select("id, sacco_id").Where("id = ?", userID).Take(&row).Error
	if errors.Is(err, gorm.ErrRecordNotFound) || (err == nil && (row.SaccoID == nil || *row.SaccoID == "")) {
		return 0, "", fmt.Errorf("%w: sacco user not found", ErrNotFound)
	}
	if err != nil {
		return 0, "", err
	}
	return row.ID, *row.SaccoID, nil
}

// UpdateUser applies column updates to a user and ends their sessions when
// revokeSessions is true, together with an audit entry, in one transaction.
func (r *Repository) UpdateUser(ctx context.Context, userID uint, updates map[string]any, revokeSessions bool, record func(tx *gorm.DB) error) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Table("users").Where("id = ?", userID).Updates(updates).Error; err != nil {
			return err
		}
		if revokeSessions {
			if err := tx.Table("refresh_tokens").Where("user_id = ? AND revoked_at IS NULL", userID).
				Update("revoked_at", time.Now()).Error; err != nil {
				return err
			}
		}
		return record(tx)
	})
}

// LogFilter narrows the audit, system and SMS log listings.
type LogFilter struct {
	SaccoID    string
	EntityType string
	Action     string
	Level      string
	Status     string
	Search     string
	FromDate   string
	ToDate     string
	Page       int
	PerPage    int
}

// AuditLogs lists audit entries across Saccos, newest first.
func (r *Repository) AuditLogs(ctx context.Context, f LogFilter) ([]AuditEntry, query.Meta, error) {
	q := r.db.WithContext(ctx).Table("audit_logs a").
		Joins("LEFT JOIN users u ON u.id = a.actor_id").
		Joins("LEFT JOIN saccos s ON s.id = a.sacco_id")
	if f.SaccoID != "" {
		q = q.Where("a.sacco_id = ?", f.SaccoID)
	}
	if f.EntityType != "" {
		q = q.Where("a.entity_type = ?", f.EntityType)
	}
	if f.Action != "" {
		q = q.Where("a.action = ?", strings.ToUpper(f.Action))
	}
	q = dateRange(q, "a.created_at", f)

	var entries []AuditEntry
	meta, err := page(q, f, "a.created_at DESC",
		"a.*, u.username AS actor_name, s.name AS sacco_name", &entries)
	return entries, meta, err
}

// SystemLogs lists failed requests, newest first.
func (r *Repository) SystemLogs(ctx context.Context, f LogFilter) ([]SystemLog, query.Meta, error) {
	q := r.db.WithContext(ctx).Table("system_logs l").
		Joins("LEFT JOIN users u ON u.id = l.user_id").
		Joins("LEFT JOIN saccos s ON s.id = l.sacco_id")
	if f.SaccoID != "" {
		q = q.Where("l.sacco_id = ?", f.SaccoID)
	}
	if f.Level != "" {
		q = q.Where("l.level = ?", strings.ToUpper(f.Level))
	}
	if f.Status != "" {
		q = q.Where("CAST(l.status AS VARCHAR(3)) LIKE ?", strings.TrimSuffix(f.Status, "xx")+"%")
	}
	if f.Search != "" {
		pattern := "%" + strings.ToLower(f.Search) + "%"
		q = q.Where("(LOWER(l.path) LIKE ? OR LOWER(l.message) LIKE ?)", pattern, pattern)
	}
	q = dateRange(q, "l.created_at", f)

	var logs []SystemLog
	meta, err := page(q, f, "l.created_at DESC",
		"l.*, u.username AS username, s.name AS sacco_name", &logs)
	return logs, meta, err
}

// SMSLogs lists SMS messages across Saccos, newest first.
func (r *Repository) SMSLogs(ctx context.Context, f LogFilter) ([]SMSEntry, query.Meta, error) {
	q := r.db.WithContext(ctx).Table("sms_logs m").Joins("LEFT JOIN saccos s ON s.id = m.sacco_id")
	if f.SaccoID != "" {
		q = q.Where("m.sacco_id = ?", f.SaccoID)
	}
	if f.Status != "" {
		q = q.Where("m.status = ?", strings.ToUpper(f.Status))
	}
	if f.Search != "" {
		q = q.Where("m.recipient_phone LIKE ?", "%"+f.Search+"%")
	}
	q = dateRange(q, "m.created_at", f)

	var entries []SMSEntry
	meta, err := page(q, f, "m.created_at DESC", "m.*, s.name AS sacco_name", &entries)
	return entries, meta, err
}

// dateRange filters a timestamp column by inclusive calendar dates.
func dateRange(q *gorm.DB, column string, f LogFilter) *gorm.DB {
	if f.FromDate != "" {
		q = q.Where(column+" >= ?", f.FromDate)
	}
	if f.ToDate != "" {
		if to, err := time.ParseInLocation(reconcile.DateLayout, f.ToDate, time.Local); err == nil {
			q = q.Where(column+" < ?", to.AddDate(0, 0, 1).Format(reconcile.DateLayout))
		}
	}
	return q
}

// page counts and fetches one page of a filtered query.
func page(q *gorm.DB, f LogFilter, order, selectCols string, dest any) (query.Meta, error) {
	perPage := f.PerPage
	if perPage <= 0 || perPage > 200 {
		perPage = 50
	}
	current := f.Page
	if current <= 0 {
		current = 1
	}

	var total int64
	if err := q.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return query.Meta{}, err
	}
	if err := q.Select(selectCols).Order(order).Limit(perPage).Offset((current - 1) * perPage).Scan(dest).Error; err != nil {
		return query.Meta{}, err
	}

	pages := int(math.Ceil(float64(total) / float64(perPage)))
	return query.Meta{
		Page: current, PerPage: perPage, Total: total, TotalPages: pages,
		HasNext: current < pages, HasPrevious: current > 1,
	}, nil
}

func optional(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n]
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
