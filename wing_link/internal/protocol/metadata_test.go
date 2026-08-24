package protocol

import (
	"encoding/json"
	"testing"
)

func TestMetadataAdvertisesOnlyCurrentAndPreviousGeneration(t *testing.T) {
	metadata := CurrentMetadata("dev", "sha256/test")
	if metadata.ProtocolGeneration != 2 || metadata.MinimumProtocolGeneration != 1 {
		t.Fatalf("metadata generations = %d..%d", metadata.MinimumProtocolGeneration, metadata.ProtocolGeneration)
	}
	if len(metadata.SupportedProtocolGenerations) != 2 || metadata.SupportedProtocolGenerations[0] != 1 || metadata.SupportedProtocolGenerations[1] != 2 {
		t.Fatalf("supported generations = %v", metadata.SupportedProtocolGenerations)
	}
	payload, err := json.Marshal(metadata)
	if err != nil {
		t.Fatal(err)
	}
	if len(payload) > 4096 {
		t.Fatalf("metadata payload is unbounded: %d bytes", len(payload))
	}
}

func TestProtocolGenerationSupportIsNMinusOneOnly(t *testing.T) {
	for generation, supported := range map[int]bool{0: false, 1: true, 2: true, 3: false} {
		if got := SupportsProtocolGeneration(generation); got != supported {
			t.Fatalf("SupportsProtocolGeneration(%d) = %v; want %v", generation, got, supported)
		}
	}
}
