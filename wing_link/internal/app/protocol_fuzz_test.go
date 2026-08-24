package app

import (
	"net/http/httptest"
	"testing"
)

func FuzzRequestProtocolGeneration(f *testing.F) {
	for _, seed := range []string{"", "1", "2", "0", "3", "-1", "999999999999999999999", " 2 ", "2,1", "\x00"} {
		f.Add(seed)
	}
	f.Fuzz(func(t *testing.T, value string) {
		request := httptest.NewRequest("GET", "/v1/status", nil)
		request.Header["Wing-Protocol"] = []string{value}
		generation, ok := requestProtocolGeneration(request)
		if value == "" && (!ok || generation != MinimumProtocolGeneration) {
			t.Fatalf("absent generation = %d, %v", generation, ok)
		}
		if ok && supportsProtocolGeneration(generation) && generation != 1 && generation != 2 {
			t.Fatalf("unexpected supported generation %d", generation)
		}
	})
}
