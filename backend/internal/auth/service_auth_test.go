package auth

import (
	"context"
	"testing"

	"github.com/codetheuri/tusk/internal/middleware"
)

func saccoCtx(saccoID string) context.Context {
	return context.WithValue(context.Background(), middleware.ContextKeySaccoID, saccoID)
}

func platformCtx() context.Context {
	return context.WithValue(context.Background(), "is_super_user", true)
}

func ptr[T any](v T) *T { return &v }

func TestResolveRegistrationSacco(t *testing.T) {
	tests := []struct {
		name    string
		ctx     context.Context
		req     RegisterRequest
		want    *string
		wantErr bool
	}{
		{
			name: "sacco admin registers staff into own sacco",
			ctx:  saccoCtx("sacco-a"),
			req:  RegisterRequest{RoleID: ptr(RoleCollector)},
			want: ptr("sacco-a"),
		},
		{
			name: "sacco admin may repeat own sacco id",
			ctx:  saccoCtx("sacco-a"),
			req:  RegisterRequest{RoleID: ptr(RoleSaccoAdmin), SaccoID: ptr("sacco-a")},
			want: ptr("sacco-a"),
		},
		{
			name:    "sacco admin cannot target another sacco",
			ctx:     saccoCtx("sacco-a"),
			req:     RegisterRequest{RoleID: ptr(RoleSaccoAdmin), SaccoID: ptr("sacco-b")},
			wantErr: true,
		},
		{
			name:    "sacco admin must pick a sacco role",
			ctx:     saccoCtx("sacco-a"),
			req:     RegisterRequest{RoleID: ptr(uint(99))},
			wantErr: true,
		},
		{
			name:    "sacco admin must provide a role",
			ctx:     saccoCtx("sacco-a"),
			req:     RegisterRequest{},
			wantErr: true,
		},
		{
			name:    "caller without sacco or platform access is rejected",
			ctx:     context.Background(),
			req:     RegisterRequest{RoleID: ptr(RoleCollector)},
			wantErr: true,
		},
		{
			name: "platform super user can target any sacco",
			ctx:  platformCtx(),
			req:  RegisterRequest{SaccoID: ptr("sacco-b")},
			want: ptr("sacco-b"),
		},
		{
			name: "platform super user can create a platform-level user",
			ctx:  platformCtx(),
			req:  RegisterRequest{},
			want: nil,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := resolveRegistrationSacco(tt.ctx, &tt.req)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("expected error, got sacco %v", got)
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			switch {
			case tt.want == nil && got != nil:
				t.Fatalf("expected no sacco, got %q", *got)
			case tt.want != nil && (got == nil || *got != *tt.want):
				t.Fatalf("expected sacco %q, got %v", *tt.want, got)
			}
		})
	}
}
