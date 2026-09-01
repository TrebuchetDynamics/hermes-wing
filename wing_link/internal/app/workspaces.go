package app

import (
	"errors"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"

	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/workspaces"
)

const remoteDirectoryBasePath = "/v2/directories"

type remoteDirectory struct {
	Handle string `json:"handle"`
	Name   string `json:"name"`
}

type remoteDirectoryList struct {
	Directories []remoteDirectory `json:"directories"`
	NextOffset  *int              `json:"next_offset,omitempty"`
}

func (server *wingLinkServer) serveDirectoryRoute(writer http.ResponseWriter, request *http.Request) bool {
	if request.URL.Path != remoteDirectoryBasePath && !strings.HasPrefix(request.URL.Path, remoteDirectoryBasePath+"/") {
		return false
	}
	if request.Method != http.MethodGet {
		writer.WriteHeader(http.StatusMethodNotAllowed)
		return true
	}
	authorization, ok := server.requireDeviceAuthorization(writer, request, ScopeDirectoriesRead, false)
	if !ok {
		return true
	}
	if server.directories == nil {
		writeDirectoryError(writer, http.StatusNotFound, "directory_unavailable")
		return true
	}
	if !emptyRequestBody(request) {
		writeDirectoryError(writer, http.StatusBadRequest, "invalid_request")
		return true
	}
	if request.URL.Path == remoteDirectoryBasePath {
		if request.URL.RawQuery != "" {
			writeDirectoryError(writer, http.StatusBadRequest, "invalid_request")
			return true
		}
		entries, err := server.directories.Roots(authorization.Device.ID)
		if err != nil {
			writeDirectoryBrowserError(writer, err)
			return true
		}
		writeJSON(writer, http.StatusOK, remoteDirectoryList{Directories: remoteDirectories(entries)})
		return true
	}

	handle, valid := remoteDirectoryChildrenHandle(request.URL.Path)
	if !valid {
		writeDirectoryError(writer, http.StatusBadRequest, "invalid_request")
		return true
	}
	offset, limit, valid := directoryPageQuery(request)
	if !valid {
		writeDirectoryError(writer, http.StatusBadRequest, "invalid_request")
		return true
	}
	page, err := server.directories.Children(authorization.Device.ID, handle, offset, limit)
	if err != nil {
		writeDirectoryBrowserError(writer, err)
		return true
	}
	writeJSON(writer, http.StatusOK, remoteDirectoryList{
		Directories: remoteDirectories(page.Entries),
		NextOffset:  page.NextOffset,
	})
	return true
}

func isRemoteDirectoryChildrenPath(path string) bool {
	_, ok := remoteDirectoryChildrenHandle(path)
	return ok
}

func remoteDirectoryChildrenHandle(path string) (string, bool) {
	remainder := strings.TrimPrefix(path, remoteDirectoryBasePath+"/")
	parts := strings.Split(remainder, "/")
	if len(parts) != 2 || parts[0] == "" || parts[1] != "children" {
		return "", false
	}
	return parts[0], true
}

func directoryPageQuery(request *http.Request) (int, int, bool) {
	query, err := url.ParseQuery(request.URL.RawQuery)
	if err != nil {
		return 0, 0, false
	}
	for key, values := range query {
		if (key != "offset" && key != "limit") || len(values) != 1 {
			return 0, 0, false
		}
	}
	offset := 0
	limit := 50
	if value, present := query["offset"]; present {
		offset, err = strconv.Atoi(value[0])
		if err != nil || offset < 0 || offset > 1000 {
			return 0, 0, false
		}
	}
	if value, present := query["limit"]; present {
		limit, err = strconv.Atoi(value[0])
		if err != nil || limit < 1 || limit > 100 {
			return 0, 0, false
		}
	}
	return offset, limit, true
}

func emptyRequestBody(request *http.Request) bool {
	if request.Body == nil || request.Body == http.NoBody {
		return true
	}
	var probe [1]byte
	count, err := request.Body.Read(probe[:])
	return count == 0 && (err == nil || errors.Is(err, io.EOF))
}

func remoteDirectories(entries []workspaces.Entry) []remoteDirectory {
	result := make([]remoteDirectory, len(entries))
	for index, entry := range entries {
		result[index] = remoteDirectory{Handle: entry.Handle, Name: entry.Name}
	}
	return result
}

func writeDirectoryBrowserError(writer http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, workspaces.ErrHandleUnavailable):
		writeDirectoryError(writer, http.StatusNotFound, "directory_unavailable")
	case errors.Is(err, workspaces.ErrGrantRevoked):
		writeDirectoryError(writer, http.StatusGone, "directory_revoked")
	case errors.Is(err, workspaces.ErrDirectoryTooLarge):
		writeDirectoryError(writer, http.StatusConflict, "directory_too_large")
	default:
		writeDirectoryError(writer, http.StatusConflict, "directory_unavailable")
	}
}

func writeDirectoryError(writer http.ResponseWriter, status int, code string) {
	message := "Directory request is unavailable"
	if code == "invalid_request" {
		message = "Directory request is invalid"
	}
	writeJSON(writer, status, map[string]any{
		"error": APIError{Code: code, Message: message},
	})
}
