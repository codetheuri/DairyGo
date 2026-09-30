package member

import (
	"reflect"
	"testing"
)

func TestSetOptional(t *testing.T) {
	stored := str("old")
	field := stored
	setOptional(&field, nil)
	if field != stored {
		t.Errorf("nil must leave the value")
	}
	setOptional(&field, str("  new "))
	if field == nil || *field != "new" {
		t.Errorf("want trimmed new value, got %v", field)
	}
	setOptional(&field, str("   "))
	if field != nil {
		t.Errorf("blank must clear, got %q", *field)
	}
}

func TestDiffFields(t *testing.T) {
	m := &Member{FirstName: "Peter", LastName: "Kamau", Phone: "0712000001", MpesaNumber: str("0712000001")}
	before := auditFields(m)
	m.MpesaNumber = str("0799000000")
	m.Location = str("Githunguri")
	old, changed := diffFields(before, auditFields(m))
	wantOld := map[string]string{"mpesa_number": "0712000001", "location": ""}
	wantNew := map[string]string{"mpesa_number": "0799000000", "location": "Githunguri"}
	if !reflect.DeepEqual(old, wantOld) || !reflect.DeepEqual(changed, wantNew) {
		t.Errorf("got old %v new %v", old, changed)
	}
	if o, c := diffFields(before, before); len(o) != 0 || len(c) != 0 {
		t.Errorf("no change must give no diff")
	}
}
