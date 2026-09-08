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
	for attempt := 0; attempt < 20; attempt++ {
		if wingLinkHealthReady(origin, 2*time.Second) {
			return nil
		}
		time.Sleep(250 * time.Millisecond)
	}
	return errors.New("wing link service did not become healthy")
}

func wingLinkHealthReady(origin *url.URL, timeout time.Duration) bool {
	client := &http.Client{
		Timeout: timeout,
		CheckRedirect: func(*http.Request, []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}
	endpoint := origin.ResolveReference(&url.URL{Path: "/healthz"})
	request, err := http.NewRequestWithContext(context.Background(), http.MethodGet, endpoint.String(), nil)
	if err != nil {
		return false
	}
	response, err := client.Do(request)
	if err != nil {
		return false
	}
	_ = response.Body.Close()
	return response.StatusCode == http.StatusOK
}
