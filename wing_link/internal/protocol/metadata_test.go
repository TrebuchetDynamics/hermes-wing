package protocol

import (
	"encoding/json"
	"slices"
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

func TestMetadataAddsOnlyKnownDirectoryCapabilities(t *testing.T) {
	metadata := CurrentMetadata(
		"dev",
		"sha256/test",
		"directories.roots.read",
		"directories.children.read",
		"directories.roots.read",
		"projects.write",
	)
	for _, capability := range []string{
		"directories.roots.read",
		"directories.children.read",
	} {
		if !slices.Contains(metadata.Capabilities, capability) {
			t.Fatalf("capabilities omitted %q: %v", capability, metadata.Capabilities)
		}
	}
	if slices.Contains(metadata.Capabilities, "projects.write") {
		t.Fatalf("unknown capability was advertised: %v", metadata.Capabilities)
	}
	if !slices.IsSorted(metadata.Capabilities) {
		t.Fatalf("capabilities are not stable: %v", metadata.Capabilities)
	}
}

func TestProtocolGenerationSupportIsNMinusOneOnly(t *testing.T) {
	for generation, supported := range map[int]bool{0: false, 1: true, 2: true, 3: false} {
		if got := SupportsProtocolGeneration(generation); got != supported {
			t.Fatalf("SupportsProtocolGeneration(%d) = %v; want %v", generation, got, supported)
		}
	}
}
