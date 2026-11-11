package audit

import (
	"errors"
	"testing"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// Hooks see every entry, in the same transaction, and an error from a hook
// rolls the change back.
func TestOnRecordHooks(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file::memory:"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&Log{}); err != nil {
		t.Fatal(err)
	}
	var seen []string
	fail := false
	OnRecord(func(tx *gorm.DB, entries []Entry) error {
		for _, e := range entries {
			seen = append(seen, e.EntityType+":"+e.EntityID)
		}
		if fail {
			return errors.New("refused")
		}
		return nil
	})
	defer func() { hooks = nil }()

	if err := Record(db, Entry{EntityType: "expense", EntityID: "e1", Action: ActionCreate}); err != nil {
		t.Fatal(err)
	}
	if err := RecordAll(db, []Entry{{EntityType: "milk_sale", EntityID: "s1"}, {EntityType: "milk_sale", EntityID: "s2"}}); err != nil {
		t.Fatal(err)
	}
	if len(seen) != 3 || seen[0] != "expense:e1" || seen[2] != "milk_sale:s2" {
		t.Fatalf("hooks saw %v", seen)
	}

	fail = true
	err = db.Transaction(func(tx *gorm.DB) error {
		return Record(tx, Entry{EntityType: "expense", EntityID: "e2", Action: ActionCreate})
	})
	if err == nil {
		t.Fatal("a hook's error must reach the caller")
	}
	var n int64
	db.Model(&Log{}).Where("entity_id = ?", "e2").Count(&n)
	if n != 0 {
		t.Fatal("the entry must roll back with the change")
	}
}
