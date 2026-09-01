//go:build !linux && !android

package app

import (
	"errors"
	"io"
	"net/url"
)

func EnsureWingLinkService(*url.URL, *url.URL) error {
	return errors.New("wing link user service setup is not implemented on this platform")
}

func WingLinkServiceCommand(string, io.Writer) error {
	return errors.New("wing link user service control is not implemented on this platform")
}
