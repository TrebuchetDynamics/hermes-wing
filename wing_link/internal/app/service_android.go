//go:build android

package app

import (
	"errors"
	"io"
	"net/url"
)

func EnsureWingLinkService(controlOrigin, _ *url.URL) error {
	return ensureExternalWingLinkService(controlOrigin)
}

func WingLinkServiceCommand(string, io.Writer) error {
	return errors.New("wing link user service control is not implemented on android")
}
