package protocol

import "sort"

const MinimumProtocolGeneration = ProtocolVersion - 1

var supportedCapabilities = []string{
	"device.self.read",
	"device.self.revoke",
	"host.identity.pin",
	"operations.poll",
	"pairing.bundle",
	"profiles.compatibility",
	"transport.non_loopback_tls",
}

var optionalCapabilities = map[string]struct{}{
	"directories.children.read": {},
	"directories.roots.read":    {},
}

type Metadata struct {
	ProtocolGeneration           int      `json:"protocol_generation"`
	MinimumProtocolGeneration    int      `json:"minimum_protocol_generation"`
	SupportedProtocolGenerations []int    `json:"supported_protocol_generations"`
	Version                      string   `json:"version"`
	HostFingerprint              string   `json:"host_fingerprint"`
	Capabilities                 []string `json:"capabilities"`
}

func CurrentMetadata(version, hostFingerprint string, additional ...string) Metadata {
	capabilities := append([]string(nil), supportedCapabilities...)
	seen := make(map[string]struct{}, len(capabilities)+len(additional))
	for _, capability := range capabilities {
		seen[capability] = struct{}{}
	}
	for _, capability := range additional {
		if _, allowed := optionalCapabilities[capability]; !allowed {
			continue
		}
		if _, duplicate := seen[capability]; duplicate {
			continue
		}
		seen[capability] = struct{}{}
		capabilities = append(capabilities, capability)
	}
	sort.Strings(capabilities)
	return Metadata{
		ProtocolGeneration:           ProtocolVersion,
		MinimumProtocolGeneration:    MinimumProtocolGeneration,
		SupportedProtocolGenerations: []int{MinimumProtocolGeneration, ProtocolVersion},
		Version:                      BoundRunes(version, 64),
		HostFingerprint:              BoundRunes(hostFingerprint, 96),
		Capabilities:                 capabilities,
	}
}

func SupportsProtocolGeneration(generation int) bool {
	return generation >= MinimumProtocolGeneration && generation <= ProtocolVersion
}
