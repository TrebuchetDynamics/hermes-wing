package app

import (
	"context"
	"errors"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
)

func ensureExternalWingLinkService(controlOrigin *url.URL) error {
	if !strings.EqualFold(strings.TrimSpace(os.Getenv("WING_LINK_SERVICE")), "external") {
		return errors.New("wing link user service setup is not implemented on this platform")
	}
	return verifyWingLinkHealth(loopbackControlOrigin(controlOrigin))
}

func verifyWingLinkHealth(origin *url.URL) error {
	client := &http.Client{Timeout: 2 * time.Second}
	endpoint := origin.ResolveReference(&url.URL{Path: "/healthz"})
	for attempt := 0; attempt < 20; attempt++ {
		request, err := http.NewRequestWithContext(context.Background(), http.MethodGet, endpoint.String(), nil)
		if err != nil {
			return errors.New("invalid Wing Link health endpoint")
		}
		response, err := client.Do(request)
		if err == nil {
			_ = response.Body.Close()
			if response.StatusCode == http.StatusOK {
				return nil
			}
		}
		time.Sleep(250 * time.Millisecond)
	}
	return errors.New("wing link service did not become healthy")
}
