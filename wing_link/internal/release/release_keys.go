package release

import "crypto/ed25519"

// Populated only by an approved release-key ceremony.
var trustedReleaseKeys = map[string]ed25519.PublicKey{}

func VerifyProductionComponentManifest(manifest, signature []byte) (ComponentCatalog, error) {
	return VerifyComponentManifest(manifest, signature, trustedReleaseKeys)
}
