package state

import (
	"bytes"
	"testing"
)

func FuzzDecodePersistedState(f *testing.F) {
	f.Add([]byte(`{"schema":2}`))
	f.Add([]byte(`{"schema":1,"control_token_hashes":[]}`))
	f.Add([]byte(`{"schema":2,"unknown":true}`))
	f.Add([]byte(`{"schema":2}{}`))
	f.Add(bytes.Repeat([]byte{'x'}, 1024))
	f.Fuzz(func(t *testing.T, payload []byte) {
		if len(payload) > 64<<10 {
			t.Skip()
		}
		_, _ = decodePersistedState(bytes.NewReader(payload))
	})
}
