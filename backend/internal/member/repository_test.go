package member

import (
	"context"
	"testing"
	"time"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/query"
)

func TestListPutsActiveFarmersFirst(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file::memory:"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&Member{}); err != nil {
		t.Fatal(err)
	}
	base := time.Date(2026, 9, 1, 8, 0, 0, 0, time.UTC)
	add := func(number string, status Status, day int) {
		m := Member{ID: number, SaccoID: "s1", MembershipNumber: number, FirstName: "F", LastName: number,
			Phone: "0712000000", Status: status, CreatedAt: base.AddDate(0, 0, day)}
		if err := db.Create(&m).Error; err != nil {
			t.Fatal(err)
		}
	}
	add("001", StatusSuspended, 9)
	add("002", StatusInactive, 8)
	add("003", StatusActive, 1)
	add("004", StatusInactive, 2)
	add("005", StatusActive, 5)
	add("006", StatusSuspended, 1)
	add("007", StatusActive, 3)
	// Another Sacco's farmer is never listed.
	if err := db.Create(&Member{ID: "x", SaccoID: "s2", MembershipNumber: "001", FirstName: "O", LastName: "Ther", Phone: "0712", Status: StatusActive, CreatedAt: base}).Error; err != nil {
		t.Fatal(err)
	}

	ctx := context.WithValue(context.Background(), middleware.ContextKeySaccoID, "s1")
	ctx = context.WithValue(ctx, "sacco_id", "s1")
	repo := NewRepository(db)
	numbers := func(q query.Query) []string {
		t.Helper()
		members, _, err := repo.List(ctx, q)
		if err != nil {
			t.Fatal(err)
		}
		var out []string
		for _, m := range members {
			out = append(out, m.MembershipNumber)
		}
		return out
	}
	eq := func(name string, got, want []string) {
		t.Helper()
		if len(got) != len(want) {
			t.Fatalf("%s: got %v, want %v", name, got, want)
		}
		for i := range want {
			if got[i] != want[i] {
				t.Fatalf("%s: got %v, want %v", name, got, want)
			}
		}
	}

	// Active (newest first), then inactive, then suspended.
	eq("default", numbers(query.Query{Filters: map[string]string{}}), []string{"005", "007", "003", "002", "004", "001", "006"})
	// Pages follow the same order.
	eq("page 2", numbers(query.Query{Page: 2, PerPage: 3, Filters: map[string]string{}}), []string{"002", "004", "001"})
	// A requested sort still wins.
	eq("by number", numbers(query.Query{Sorts: []query.Sort{{Field: "membership_number", Order: query.SortAsc}}, Filters: map[string]string{}}),
		[]string{"001", "002", "003", "004", "005", "006", "007"})
	// Farmers who can supply milk: no suspended ones, still active first.
	eq("can supply", numbers(query.Query{Filters: map[string]string{filterCanSupply: "true"}}), []string{"005", "007", "003", "002", "004"})
}
