package member

import "testing"

func str(s string) *string { return &s }

func TestCleanNextOfKin(t *testing.T) {
	tests := []struct {
		name                     string
		kinName, relation, phone *string
		want                     nextOfKin
		wantErr                  bool
	}{
		{name: "complete", kinName: str(" Mary Wanjiku "), relation: str("Spouse"), phone: str("0712 345 678"),
			want: nextOfKin{Name: "Mary Wanjiku", Relationship: "Spouse", Phone: "0712 345 678"}},
		{name: "international phone", kinName: str("Mary"), relation: str("Son"), phone: str("+254712345678"),
			want: nextOfKin{Name: "Mary", Relationship: "Son", Phone: "+254712345678"}},
		{name: "nothing given (optional)"},
		{name: "all blank (optional)", kinName: str(" "), relation: str(""), phone: str("  ")},
		{name: "name only", kinName: str("Mary"), want: nextOfKin{Name: "Mary"}},
		{name: "blank name", kinName: str("  "), relation: str("Spouse"), phone: str("0712345678"), wantErr: true},
		{name: "phone without a name", phone: str("0712345678"), wantErr: true},
		{name: "short phone", kinName: str("Mary"), relation: str("Spouse"), phone: str("07123"), wantErr: true},
		{name: "letters instead of a phone", kinName: str("Mary"), relation: str("Spouse"), phone: str("call her mum"), wantErr: true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := cleanNextOfKin(tt.kinName, tt.relation, tt.phone)
			if (err != nil) != tt.wantErr {
				t.Fatalf("error = %v, wantErr %v", err, tt.wantErr)
			}
			if got != tt.want {
				t.Errorf("got %+v, want %+v", got, tt.want)
			}
		})
	}
}

func TestFirstSet(t *testing.T) {
	stored, sent := str("old"), str("new")
	if got := firstSet(sent, stored); got != sent {
		t.Errorf("a sent value must win")
	}
	if got := firstSet(nil, stored); got != stored {
		t.Errorf("the stored value must be kept when nothing is sent")
	}
}
