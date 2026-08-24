package protocol

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

type Metadata struct {
	ProtocolGeneration           int      `json:"protocol_generation"`
	MinimumProtocolGeneration    int      `json:"minimum_protocol_generation"`
	SupportedProtocolGenerations []int    `json:"supported_protocol_generations"`
	Version                      string   `json:"version"`
	HostFingerprint              string   `json:"host_fingerprint"`
	Capabilities                 []string `json:"capabilities"`
}

func CurrentMetadata(version, hostFingerprint string) Metadata {
	return Metadata{
		ProtocolGeneration:           ProtocolVersion,
		MinimumProtocolGeneration:    MinimumProtocolGeneration,
		SupportedProtocolGenerations: []int{MinimumProtocolGeneration, ProtocolVersion},
		Version:                      BoundRunes(version, 64),
		HostFingerprint:              BoundRunes(hostFingerprint, 96),
		Capabilities:                 append([]string(nil), supportedCapabilities...),
	}
}

func SupportsProtocolGeneration(generation int) bool {
	return generation >= MinimumProtocolGeneration && generation <= ProtocolVersion
}
