package export

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/letterhead"
	"github.com/codetheuri/tusk/pkg/document"
)

const dateLayout = "2006-01-02"

// staffName is a user's full name, or the username without one.
const staffName = letterhead.StaffNameSQL

// Repository reads report data. Every query is limited to one Sacco and
// does the adding up in the database, so a month of records is a handful of
// queries, not one per farmer or day.
type Repository struct {
	db *gorm.DB
}

// NewRepository creates the export repository.
func NewRepository(db *gorm.DB) *Repository { return &Repository{db: db} }

// Letterhead is the Sacco's name, contacts and logo.
func (r *Repository) Letterhead(ctx context.Context, saccoID string) (document.Letterhead, error) {
	return letterhead.New(r.db).Letterhead(ctx, saccoID)
}

// StaffName is a user's name as shown on reports.
func (r *Repository) StaffName(ctx context.Context, userID uint) string {
	return letterhead.New(r.db).StaffName(ctx, userID)
}

// Farmer is a farmer's details for statements and the register.
type Farmer struct {
	ID                    string
	MembershipNumber      string
	FirstName             string
	LastName              string
	Phone                 string
	Gender                *string
	Location              *string
	Status                string
	MpesaNumber           *string
	MpesaName             *string
	BankName              *string
	BankAccountNumber     *string
	BankBranch            *string
	NextOfKinName         *string
	NextOfKinRelationship *string
	NextOfKinPhone        *string
	CreatedAt             time.Time
}

// FullName is "First Last".
func (f Farmer) FullName() string { return f.FirstName + " " + f.LastName }

var errNotFound = errors.New("not found")

// Farmer loads one farmer of the Sacco.
func (r *Repository) Farmer(ctx context.Context, saccoID, id string) (*Farmer, error) {
	var f Farmer
	err := r.db.WithContext(ctx).Table("members").
		Where("sacco_id = ? AND id = ? AND deleted_at IS NULL", saccoID, id).Take(&f).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("%w: farmer", errNotFound)
	}
	return &f, err
}

// Farmers lists the Sacco's farmers by membership number, optionally of one
// status.
func (r *Repository) Farmers(ctx context.Context, saccoID, status string) ([]Farmer, error) {
	q := r.db.WithContext(ctx).Table("members").Where("sacco_id = ? AND deleted_at IS NULL", saccoID)
	if status != "" {
		q = q.Where("status = ?", status)
	}
	var out []Farmer
	return out, q.Order("membership_number").Find(&out).Error
}

// Payout is what one farmer is owed for a period.
type Payout struct {
	Farmer
	Deliveries int64
	Litres     float64
	Amount     float64
}

// Payouts adds up each farmer's accepted milk in the period.
func (r *Repository) Payouts(ctx context.Context, saccoID string, from, to time.Time) ([]Payout, error) {
	var out []Payout
	err := r.db.WithContext(ctx).Table("members m").
		Select(`m.*, COUNT(c.id) AS deliveries, SUM(c.quantity_litres) AS litres, SUM(c.total_amount) AS amount`).
		Joins(`JOIN milk_collections c ON c.member_id = m.id AND c.sacco_id = m.sacco_id
			AND c.deleted_at IS NULL AND c.status <> 'REJECTED' AND c.collection_date BETWEEN ? AND ?`,
			from.Format(dateLayout), to.Format(dateLayout)).
		Where("m.sacco_id = ? AND m.deleted_at IS NULL", saccoID).
		Group("m.id").Order("m.membership_number").
		Scan(&out).Error
	return out, err
}

// Delivery is one milk collection.
type Delivery struct {
	CollectionDate   time.Time
	CreatedAt        time.Time
	Shift            string
	MembershipNumber string
	FarmerName       string
	QuantityLitres   float64
	PricePerLitre    float64
	TotalAmount      float64
	Status           string
	CollectorName    string
}

// DeliveryFilter narrows the collections listed.
type DeliveryFilter struct {
	MemberID    string
	CollectorID uint
	Shift       string
	// Accepted leaves out rejected collections (for what farmers are paid).
	Accepted bool
}

// Deliveries lists collections in the period, oldest first.
func (r *Repository) Deliveries(ctx context.Context, saccoID string, from, to time.Time, f DeliveryFilter) ([]Delivery, error) {
	q := r.db.WithContext(ctx).Table("milk_collections c").
		Select(`c.collection_date, c.created_at, c.shift, m.membership_number,
			m.first_name || ' ' || m.last_name AS farmer_name,
			c.quantity_litres, c.price_per_litre, c.total_amount, c.status, `+staffName+` AS collector_name`).
		Joins("JOIN members m ON m.id = c.member_id").
		Joins("LEFT JOIN users u ON u.id = c.collector_id").
		Joins("LEFT JOIN user_profiles p ON p.user_id = u.id").
		Where("c.sacco_id = ? AND c.deleted_at IS NULL AND c.collection_date BETWEEN ? AND ?",
			saccoID, from.Format(dateLayout), to.Format(dateLayout))
	if f.MemberID != "" {
		q = q.Where("c.member_id = ?", f.MemberID)
	}
	if f.CollectorID > 0 {
		q = q.Where("c.collector_id = ?", f.CollectorID)
	}
	if f.Shift != "" {
		q = q.Where("c.shift = ?", f.Shift)
	}
	if f.Accepted {
		q = q.Where("c.status <> 'REJECTED'")
	}
	var out []Delivery
	return out, q.Order("c.collection_date, c.shift DESC, m.membership_number, c.created_at").Scan(&out).Error
}

// Sale is one milk sale.
type Sale struct {
	SaleDate       time.Time
	CustomerName   string
	CustomerType   string
	QuantityLitres float64
	UnitPrice      float64
	TotalAmount    float64
	AmountPaid     float64
	PaymentStatus  string
	CollectorName  string
}

// Sales lists the period's sales (voided ones left out), oldest first.
func (r *Repository) Sales(ctx context.Context, saccoID string, from, to time.Time, collectorID uint) ([]Sale, error) {
	q := r.db.WithContext(ctx).Table("milk_sales s").
		Select(`s.sale_date, COALESCE(cu.name, s.buyer_name) AS customer_name, COALESCE(cu.customer_type, '') AS customer_type,
			s.quantity_litres, s.unit_price, s.total_amount, s.amount_paid, s.payment_status, `+staffName+` AS collector_name`).
		Joins("LEFT JOIN customers cu ON cu.id = s.customer_id").
		Joins("LEFT JOIN users u ON u.id = s.collector_id").
		Joins("LEFT JOIN user_profiles p ON p.user_id = u.id").
		Where("s.sacco_id = ? AND s.deleted_at IS NULL AND s.voided_at IS NULL AND s.sale_date BETWEEN ? AND ?",
			saccoID, from.Format(dateLayout), to.Format(dateLayout))
	if collectorID > 0 {
		q = q.Where("s.collector_id = ?", collectorID)
	}
	var out []Sale
	return out, q.Order("s.sale_date, s.created_at").Scan(&out).Error
}

// Day is a Sacco's milk and money for one day.
type Day struct {
	Date          time.Time
	CollectedL    float64
	PurchaseCost  float64
	SoldL         float64
	Revenue       float64
	PaidAtSale    float64
	SpoiledL      float64
	Farmers       int64
	HasActivities bool
}

// Days adds up each day of the period: three grouped queries, merged here.
func (r *Repository) Days(ctx context.Context, saccoID string, from, to time.Time) ([]Day, error) {
	f, t := from.Format(dateLayout), to.Format(dateLayout)
	type row struct {
		D       time.Time
		A, B, C float64
		N       int64
	}
	var intake, sold, spoiled []row
	db := r.db.WithContext(ctx)
	if err := db.Table("milk_collections").
		Select("collection_date AS d, SUM(quantity_litres) AS a, SUM(total_amount) AS b, COUNT(DISTINCT member_id) AS n").
		Where("sacco_id = ? AND deleted_at IS NULL AND status <> 'REJECTED' AND collection_date BETWEEN ? AND ?", saccoID, f, t).
		Group("collection_date").Scan(&intake).Error; err != nil {
		return nil, err
	}
	if err := db.Table("milk_sales").
		Select("sale_date AS d, SUM(quantity_litres) AS a, SUM(total_amount) AS b, SUM(amount_paid) AS c").
		Where("sacco_id = ? AND deleted_at IS NULL AND voided_at IS NULL AND sale_date BETWEEN ? AND ?", saccoID, f, t).
		Group("sale_date").Scan(&sold).Error; err != nil {
		return nil, err
	}
	if err := db.Table("milk_spoilage").
		Select("spoilage_date AS d, SUM(quantity_litres) AS a").
		Where("sacco_id = ? AND deleted_at IS NULL AND spoilage_date BETWEEN ? AND ?", saccoID, f, t).
		Group("spoilage_date").Scan(&spoiled).Error; err != nil {
		return nil, err
	}

	byDate := map[string]*Day{}
	day := func(d time.Time) *Day {
		k := d.Format(dateLayout)
		if byDate[k] == nil {
			byDate[k] = &Day{Date: d}
		}
		byDate[k].HasActivities = true
		return byDate[k]
	}
	for _, x := range intake {
		d := day(x.D)
		d.CollectedL, d.PurchaseCost, d.Farmers = x.A, x.B, x.N
	}
	for _, x := range sold {
		d := day(x.D)
		d.SoldL, d.Revenue, d.PaidAtSale = x.A, x.B, x.C
	}
	for _, x := range spoiled {
		day(x.D).SpoiledL = x.A
	}
	// Every day of the period, quiet ones included, in order.
	var out []Day
	for d := from; !d.After(to); d = d.AddDate(0, 0, 1) {
		if v, ok := byDate[d.Format(dateLayout)]; ok {
			v.Date = d
			out = append(out, *v)
		} else {
			out = append(out, Day{Date: d})
		}
	}
	return out, nil
}

func deref(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}
