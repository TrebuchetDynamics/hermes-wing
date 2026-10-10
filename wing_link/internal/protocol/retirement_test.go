package protocol

import (
	"strings"
	"testing"
)

func TestRetiredOmniRouteIsRejected(t *testing.T) {
	request := InstallRequest{Components: []Component{ComponentHermes, Component("omniroute")}, AcceptCommunityProviderTerms: true}
	if err := request.Validate(); err == nil {
		t.Fatal("retired runtime accepted even with old consent")
	}
	for _, capability := range CurrentMetadata("test", "test", "host.omniroute.discover").Capabilities {
		if strings.Contains(capability, "omniroute") {
			t.Fatal("retired discovery can be advertised")
		}
	}
}
