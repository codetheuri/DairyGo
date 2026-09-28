package collection

import (
	"reflect"
	"testing"
)

func TestCollectionFiltersFormatsCollectorID(t *testing.T) {
	got := collectionFilters(&ListCollectionsInput{
		CollectorID: 2,
		FromDate:    "2026-09-01",
		ToDate:      "2026-09-30",
	})
	want := map[string]string{
		"collector_id":         "2",
		"collection_date_from": "2026-09-01",
		"collection_date_to":   "2026-09-30",
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %q, want %q", got, want)
	}
}

func TestSpoilageFiltersIncludeCollector(t *testing.T) {
	got := spoilageFilters(&ListSpoilageInput{CollectorID: 12})
	if got["collector_id"] != "12" {
		t.Fatalf("collector_id = %q, want \"12\"", got["collector_id"])
	}
}

func TestFiltersOmitUnsetValues(t *testing.T) {
	if f := collectionFilters(&ListCollectionsInput{}); len(f) != 0 {
		t.Fatalf("expected no filters, got %v", f)
	}
}
