# Approved Directory Browsing and Hermes Project Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a paired Hermes Wing client browse locally approved host folders through device-bound opaque handles, while keeping folder selection and Hermes Project creation unavailable until Hermes Agent exposes a released machine-readable Project mutation contract.

**Architecture:** Wing Link owns local directory grants and ephemeral opaque navigation handles; it returns folder names and handles only, never paths, files, metadata, or contents. Hermes Agent remains the Project authority. This plan deliberately separates executable directory browsing from Project creation: the checked-in Agent reference currently exposes Project mutation through Desktop JSON-RPC and human-readable CLI output, but not through the authenticated Agent HTTP capability surface Wing uses, so Wing must not invent or parse a compatibility contract.

**Tech Stack:** Go 1.26, Wing Link protocol generation 2, owner-only JSON state, in-memory bounded handle registry, Flutter 3.44.2, Dart 3.12, Riverpod, Material adaptive sheets, Flutter localization.

## Global Constraints

- Preserve all unrelated dirty and untracked files. The current worktree contains in-flight directory code and broad unrelated changes; read every target before editing.
- Do not commit, stage, reset, clean, or push unless the user separately requests delivery.
- Hermes Agent owns Projects. Wing Link stores no profile-to-path or Project shadow state.
- Remote callers never submit or receive absolute paths, relative paths, path segments, executables, commands, config keys, or URLs.
- Root grants are created and revoked only by the local `wing-link directories` CLI.
- Remote responses contain bounded child-folder names and opaque handles only—never file names, file metadata, file contents, symlink targets, or host paths.
- Every handle lookup rechecks grant existence and directory type, securely opens the approved root component-by-component without accepting symlink substitution, then traverses only through Go's rooted `os.Root` API so concurrent replacement cannot escape the approved root.
- Handles are random, device-bound, in-memory, bounded, and expiring. Restart or expiry requires refreshing the picker.
- Add only the exact `directories:read` Wing Link scope in this plan; never auto-expand an existing named or legacy device's grants. Re-pairing or a future local grant-management command is required.
- Project scopes and routes stay absent until a separately reviewed Project contract exists. Project creation stays unavailable until a released Hermes Agent contract provides bounded machine-readable input/output and explicit profile identity. Never parse current human-readable `hermes project` output.
- Starting Chat in a Project remains separately gated on an explicit direct-Agent Project/session contract.
- English copy is changed only in `lib/l10n/app_en.arb`; regenerate localization files with `flutter gen-l10n`.

---

## Current-state and contract gate

The existing high-level design is `docs/plans/wing-link-remote-management.md`; do not duplicate its provider, release, or platform phases here. Current in-flight code already provides local root grant/list/revoke behavior in:

- `wing_link/internal/app/directories.go`
- `wing_link/internal/app/directories_test.go`
- `wing_link/internal/workspaces/grants.go`
- `wing_link/internal/workspaces/grants_test.go`

The current Hermes Agent reference provides:

- typed Desktop JSON-RPC `projects.list`, `projects.create`, `projects.update`, folder mutation, archive, and delete in `hermes-agent/tui_gateway/server.py:14705-14796`;
- human-readable `hermes project` commands in `hermes-agent/hermes_cli/projects_cmd.py`;
- no `/api/projects` route in the authenticated Agent HTTP surface Wing currently consumes;
- no JSON mode on `hermes project`.

Therefore this plan has one executable deliverable: safe remote browsing of locally approved directories. The follow-up Project plan is created only after one of these upstream contracts is released and verified:

1. an advertised authenticated Agent operation with explicit `profile`, typed Project input/output, and no global `project use`; or
2. a fixed Hermes CLI Project operation with bounded JSON input/output and stable identity, followed by an explicit update to `docs/adr/runtime-and-delivery.md` and security review authorizing that new compatibility exception.

Absence of that contract is a supported state, not a reason to expose paths or parse prose.

---

### Task 1: Finish the local grant store and add the exact directory-read scope

**Files:**

- Modify: `wing_link/internal/state/device.go`
- Modify: `wing_link/internal/state/device_test.go`
- Modify: `wing_link/internal/state/state.go`
- Modify: `wing_link/internal/app/state.go`
- Modify: `wing_link/internal/app/pair.go`
- Modify: `wing_link/internal/app/pair_test.go`
- Modify: `wing_link/internal/workspaces/grants.go`
- Modify: `wing_link/internal/workspaces/grants_test.go`
- Modify: `wing_link/internal/app/directories.go`
- Modify: `wing_link/internal/app/directories_test.go`

**Interfaces:**

- Produces: `ScopeDirectoriesRead = "directories:read"`
- Preserves: `workspaces.Open`, `Store.Grant`, `Store.List`, and `Store.Revoke`
- Produces: `Store.Resolve(id string) (DirectoryGrant, error)` for host-internal handle validation only

- [x] **Step 1: Extend scope tests before production constants**

Add a test in `wing_link/internal/state/device_test.go` proving the exact directory-read scope is accepted, premature Project and broad scopes are rejected, and a device missing `directories:read` is not authorized for it:

```go
func TestDirectoryReadScopeRemainsExact(t *testing.T) {
	store := New(filepath.Join(t.TempDir(), "state.json"))
	id, token, err := store.StageBearerDeviceCredential(
		"phone",
		[]string{ScopeDirectoriesRead},
	)
	if err != nil || id == "" || token == "" {
		t.Fatalf("stage: id=%q token=%q err=%v", id, token, err)
	}
	if _, ok := store.AuthorizeDevice(token, ScopeDirectoriesRead); ok {
		t.Fatal("pending credential authorized before acknowledgment")
	}
	for _, scope := range []string{"filesystem:*", "projects:*", "projects:read", "projects:write", "admin"} {
		if _, _, err := store.StageBearerDeviceCredential("bad", []string{scope}); err == nil {
			t.Fatalf("unsafe or premature scope %q was accepted", scope)
		}
	}
}
```

Use the existing pending-credential acknowledgment helper in the test if authorization after acknowledgment is asserted; do not bypass the pending state.

- [x] **Step 2: Run the focused state test and verify RED**

Run:

```bash
cd wing_link
go test ./internal/state -run 'DirectoryReadScopeRemainsExact' -count=1
```

Expected: compile failure because `ScopeDirectoriesRead` does not exist.

- [x] **Step 3: Add the exact scopes without widening old credentials**

Add the constant to `wing_link/internal/state/device.go`, include it in the allowed vocabulary used for newly staged devices, re-export it from `wing_link/internal/app/state.go`, and add it to `wingLinkControlScopes` in `wing_link/internal/app/pair.go`:

```go
const ScopeDirectoriesRead = "directories:read"
```

Before extending the allowed vocabulary, freeze the current pre-directory list as `legacyControlScopes`. Change `StageControlToken` in `wing_link/internal/state/state.go` plus both legacy authorization/list projections in `wing_link/internal/state/device.go` to use copies of `legacyControlScopes`. New pairings receive `directories:read` through `wingLinkControlScopes`; existing named rows retain their persisted scopes, and legacy tokens remain unable to browse directories.

Add assertions to the state test that an acknowledged legacy fixture is unauthorized for `ScopeDirectoriesRead` while a newly acknowledged device explicitly staged with that scope is authorized.

- [x] **Step 4: Add `Store.Resolve` tests**

Extend `wing_link/internal/workspaces/grants_test.go`:

```go
func TestDirectoryGrantResolveRechecksCanonicalDirectory(t *testing.T) {
	root := filepath.Join(t.TempDir(), "repository")
	if err := os.Mkdir(root, 0o700); err != nil {
		t.Fatal(err)
	}
	store, err := Open(filepath.Join(t.TempDir(), "grants.json"))
	if err != nil {
		t.Fatal(err)
	}
	grant, err := store.Grant(root)
	if err != nil {
		t.Fatal(err)
	}
	resolved, err := store.Resolve(grant.ID)
	if err != nil || resolved.ID != grant.ID || resolved.Path != root {
		t.Fatalf("resolved=%#v err=%v", resolved, err)
	}
	if err := os.Remove(root); err != nil {
		t.Fatal(err)
	}
	if _, err := store.Resolve(grant.ID); err == nil {
		t.Fatal("removed directory grant still resolved")
	}
}
```

Also test revoked IDs and a persisted path replaced by a symlink after grant creation.

- [x] **Step 5: Run the workspace tests and verify RED**

Run:

```bash
cd wing_link
go test ./internal/workspaces -run 'DirectoryGrantResolve' -count=1
```

Expected: compile failure because `Store.Resolve` does not exist.

- [x] **Step 6: Implement `Store.Resolve` with fresh canonical validation**

Implement under the store lock. It must find the grant by ID, rerun `canonicalDirectory(grant.Path)`, require that the result still equals the persisted canonical path, and return `ErrGrantNotFound` for malformed, revoked, moved, replaced, or escaped roots:

```go
func (s *Store) Resolve(id string) (DirectoryGrant, error) {
	if !validGrantID(id) {
		return DirectoryGrant{}, ErrGrantNotFound
	}
	var resolved DirectoryGrant
	err := s.withLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		for _, grant := range state.Grants {
			if grant.ID != id {
				continue
			}
			canonical, err := canonicalDirectory(grant.Path)
			if err != nil || canonical != grant.Path {
				return ErrGrantNotFound
			}
			resolved = grant
			return nil
		}
		return ErrGrantNotFound
	})
	return resolved, err
}
```

- [x] **Step 7: Run focused and package tests**

Run:

```bash
cd wing_link
gofmt -w internal/state/device.go internal/state/device_test.go internal/state/state.go internal/app/state.go internal/app/pair.go internal/app/pair_test.go internal/workspaces/grants.go internal/workspaces/grants_test.go internal/app/directories.go internal/app/directories_test.go
go test ./internal/state ./internal/workspaces ./internal/app -count=1
```

Expected: PASS. Existing named-device scope tests must remain unchanged except for newly paired fixtures.

---

### Task 2: Add bounded device-bound opaque directory handles

**Files:**

- Create: `wing_link/internal/workspaces/browser.go`
- Create: `wing_link/internal/workspaces/browser_test.go`

**Interfaces:**

- Consumes: `Store.List()` and `Store.Resolve(id)` from Task 1
- Produces: `type Browser struct`
- Produces: `type Entry struct { Handle string; Name string }`
- Produces: `type Page struct { Entries []Entry; NextOffset *int }`
- Produces: `func NewBrowser(store *Store, now func() time.Time, random func(int, string) (string, error)) *Browser`; production passes `wingstate.RandomSecret`, tests pass `deterministicSecret`
- Produces: `func (b *Browser) Roots(deviceID string) ([]Entry, error)`
- Produces: `func (b *Browser) Children(deviceID, handle string, offset, limit int) (Page, error)`
- Keeps handle resolution private; browser calls reopen `os.Root` from the freshly resolved grant and never return a host path
- Produces sentinel errors: `ErrHandleUnavailable`, `ErrGrantRevoked`, `ErrDirectoryUnavailable`, and `ErrDirectoryTooLarge`

**Fixed bounds:**

- handle format: the direct result of `wingstate.RandomSecret(24, "dirh_")`—`dirh_` plus 32 base64url characters from 24 random bytes, 37 characters total
- handle lifetime: 15 minutes
- maximum root rows: 32 (the grant-store maximum)
- maximum live handles: 2,048 globally and 256 per device; a device may evict
  only its own handles
- default page size: 50
- maximum page size: 100
- maximum total directory entries scanned per lookup: 4,096
- maximum sortable child directories per lookup: 1,000
- name limit: 255 UTF-8 bytes

- [x] **Step 1: Write browser behavior tests**

Create `wing_link/internal/workspaces/browser_test.go` with tests proving:

```go
func TestBrowserReturnsFoldersOnlyAndBindsHandlesToDevice(t *testing.T) {
	root := t.TempDir()
	for _, name := range []string{"alpha", "beta", ".hidden"} {
		if err := os.Mkdir(filepath.Join(root, name), 0o700); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.WriteFile(filepath.Join(root, "secret.txt"), []byte("secret"), 0o600); err != nil {
		t.Fatal(err)
	}
	store, _ := Open(filepath.Join(t.TempDir(), "grants.json"))
	if _, err := store.Grant(root); err != nil {
		t.Fatal(err)
	}
	browser := NewBrowser(store, time.Now, deterministicSecret)
	roots, err := browser.Roots("cred_phone")
	if err != nil || len(roots) != 1 || strings.Contains(roots[0].Handle, root) {
		t.Fatalf("roots=%#v err=%v", roots, err)
	}
	page, err := browser.Children("cred_phone", roots[0].Handle, 0, 50)
	if err != nil {
		t.Fatal(err)
	}
	if got := entryNames(page.Entries); !slices.Equal(got, []string{"alpha", "beta"}) {
		t.Fatalf("names=%q", got)
	}
	if _, err := browser.Children("cred_other", roots[0].Handle, 0, 50); !errors.Is(err, ErrHandleUnavailable) {
		t.Fatalf("another device used the handle: %v", err)
	}
}
```

Add these exact cases:

- a child symlink that resolves inside the root is listed under its lexical name;
- retargeting that symlink outside the root after handle issuance makes `Children` return `ErrDirectoryUnavailable` for its handle;
- issuing a nested child handle below an in-root ancestor symlink, then retargeting that ancestor outside the root, makes `Children` return `ErrDirectoryUnavailable` for the nested handle;
- repeatedly retargeting an ancestor symlink between an in-root and outside directory while browsing never returns an outside child name (the concurrency regression test for rooted traversal);
- repeatedly replacing the granted root itself with an outside symlink while calling `Roots` and `Children` never returns an outside child name (the root-open race regression);
- revoking the root after handle issuance makes `Resolve` return `ErrGrantRevoked`;
- malformed, wrong-device, expired, and evicted handles return `ErrHandleUnavailable`;
- unreadable or removed directories return `ErrDirectoryUnavailable`;
- more than 4,096 total entries—even when they are regular files—or more than 1,000 valid contained child directories returns `ErrDirectoryTooLarge` and no partial page;
- offsets are stable over the sorted snapshot produced by one call; `offset == len(entries)` returns an empty terminal page;
- exceeding the per-device quota evicts only that device's earliest-expiring
  record; a new device cannot evict another device from a full global pool;
- Unicode names are sorted by Go string order and remain valid UTF-8;
- hidden child directories are omitted, while a hidden root explicitly granted
  by the local operator remains visible.

Every case must assert no returned `Entry`, sentinel error, or formatted error contains the temporary root path or regular file name.

- [x] **Step 2: Run browser tests and verify RED**

Run:

```bash
cd wing_link
go test ./internal/workspaces -run 'Browser' -count=1
```

Expected: compile failure because `Browser` and its methods do not exist.

- [x] **Step 3: Implement the in-memory browser**

Implement a mutex-protected map whose private records contain:

```go
type handleRecord struct {
	deviceID     string
	grantID      string
	relativePath string
	expires      time.Time
}
```

Add a private `openRootNoSymlinks(absolute string) (*os.Root, error)` helper using only the Go standard library. Require a clean absolute path. Start from its filesystem/volume root, then open one relative component at a time. For each component: call the current `os.Root.Lstat`, reject non-directories and symlinks, call `current.OpenRoot(component)`, call `next.Stat(".")`, and require `os.SameFile(lstatInfo, openedInfo)` before continuing. Close the previous rooted handle after each successful step and close every handle on failure. This Lstat/open/identity sequence prevents a concurrent component swap from substituting a different directory even though `OpenRoot` itself follows a root-name symlink. Add direct helper tests for normal roots, symlink components, and a loop that swaps a component while opening; only the originally observed directory identity may be returned.

`Roots` obtains current grants, freshly resolves each root, verifies `openRootNoSymlinks(grant.Path)` succeeds and closes it, stores `relativePath: "."`, issues a handle with `wingstate.RandomSecret(24, "dirh_")`, and returns only `{handle,name}` sorted by name then handle.

For every `Children` call, resolve the private record under the handle mutex, copy it, then release the mutex before filesystem I/O. Freshly call `Store.Resolve(record.grantID)`, securely open the approved root with `openRootNoSymlinks(grant.Path)`, and open the recorded relative directory with `root.OpenRoot(record.relativePath)`. Go 1.26 `os.Root` then follows only symlinks that remain beneath the verified opened root on supported Wing Link host targets; never replace this with `EvalSymlinks` followed by path-based `Open`/`Stat`, which has a check/use race. Close both roots on every path.

Open `"."` through the child `os.Root` and scan with `file.ReadDir(256)` chunks. Stop and return `ErrDirectoryTooLarge` if a 4,097th total entry exists; do not use `os.ReadDir`, which loads an unbounded directory. Accumulate no issued handles during the scan. After EOF, validate each display name, then call `parentRoot.OpenRoot(entry.Name())`; successful opens are directories contained by construction, including in-root symlinks, while outside or non-directory targets are omitted. Close each probe immediately. Build child records with `filepath.Join(parentRecord.relativePath, entry.Name())`, reject more than 1,000 valid child directories, and only then issue handles, sort, and paginate.

Do not follow a child symlink outside the grant. A symlink resolving inside the root may be returned under its visible child name. Accept a child display name only when `utf8.ValidString(name)` and `len([]byte(name)) <= 255`; omit invalid names without including them in an error. Count every raw `ReadDir` entry toward the 4,096 scan bound and only rooted-open child directories toward the 1,000-directory bound. Return `ErrDirectoryTooLarge` before issuing any child handles when either bound is exceeded.

A missing/revoked grant maps to `ErrGrantRevoked`. Secure-root-open, rooted-relative-path, symlink, identity mismatch, type, permission, expiry, device, malformed-handle, and eviction failures map to the exact sentinel errors above without wrapping host paths. `relativePath` values are generated only from names returned by the already-open rooted parent; callers never supply them.

- [x] **Step 4: Run race-enabled workspace tests**

Run:

```bash
cd wing_link
gofmt -w internal/workspaces/browser.go internal/workspaces/browser_test.go
go test -race ./internal/workspaces -count=1
```

Expected: PASS with no races and no path leakage in assertion output.

---

### Task 3: Expose read-only remote directory routes

**Files:**

- Create: `wing_link/internal/app/workspaces.go`
- Create: `wing_link/internal/app/workspaces_test.go`
- Modify: `wing_link/internal/app/serve.go`
- Modify: `wing_link/internal/app/audit.go`
- Modify: `wing_link/internal/protocol/metadata.go`
- Modify: `wing_link/internal/protocol/metadata_test.go`
- Modify: `wing_link/internal/audit/audit.go`
- Modify: `wing_link/internal/audit/audit_test.go`

**Interfaces:**

- Produces: `GET /v2/directories`
- Produces: `GET /v2/directories/{handle}/children?offset=<n>&limit=<n>`
- Requires: `directories:read`
- Produces capabilities: `directories.roots.read`, `directories.children.read`
- Root response: `{ "directories": [{ "handle": "dirh_…", "name": "repository" }] }`
- Child page response: `{ "directories": [...], "next_offset": 50 }`; omit `next_offset` at end
- Error mapping: `ErrHandleUnavailable` → 404 `directory_unavailable`; `ErrGrantRevoked` → 410 `directory_revoked`; `ErrDirectoryUnavailable` → 409 `directory_unavailable`; `ErrDirectoryTooLarge` → 409 `directory_too_large`

- [x] **Step 1: Write route tests with a real temporary grant store**

Create `wing_link/internal/app/workspaces_test.go`. Use `newStateStore`, `openDirectoryGrantStore`, `StageDeviceCredential`, and `AcknowledgeControlToken`, matching `TestDeviceScopesAreEnforcedPerRoute` in `wing_link/internal/app/serve_test.go`:

```go
func TestRemoteDirectoryRoutesReturnHandlesAndNamesOnly(t *testing.T) {
	statePath := filepath.Join(t.TempDir(), "state.json")
	store := newStateStore(statePath)
	credentialID, token, err := store.StageDeviceCredential(
		"Folder browser",
		ed25519.PublicKey(bytes.Repeat([]byte{9}, ed25519.PublicKeySize)),
		[]string{ScopeDirectoriesRead},
	)
	if err != nil {
		t.Fatal(err)
	}
	if err := store.AcknowledgeControlToken(credentialID, token); err != nil {
		t.Fatal(err)
	}
	root := filepath.Join(t.TempDir(), "repository")
	child := filepath.Join(root, "src")
	if err := os.MkdirAll(child, 0o700); err != nil {
		t.Fatal(err)
	}
	fileName := "private.txt"
	if err := os.WriteFile(filepath.Join(root, fileName), []byte("secret"), 0o600); err != nil {
		t.Fatal(err)
	}
	grants, err := openDirectoryGrantStore(statePath)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := grants.Grant(root); err != nil {
		t.Fatal(err)
	}
	handler := newWingLinkServer(&profileBackend{}, store)

	request := httptest.NewRequest(http.MethodGet, "/v2/directories", nil)
	request.Header.Set("Authorization", "Bearer "+token)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusOK {
		t.Fatalf("roots status=%d body=%q", response.Code, response.Body.String())
	}
	var roots struct {
		Directories []struct {
			Handle string `json:"handle"`
			Name   string `json:"name"`
		} `json:"directories"`
	}
	if err := json.Unmarshal(response.Body.Bytes(), &roots); err != nil || len(roots.Directories) != 1 {
		t.Fatalf("roots=%#v err=%v", roots, err)
	}

	request = httptest.NewRequest(
		http.MethodGet,
		"/v2/directories/"+url.PathEscape(roots.Directories[0].Handle)+"/children?offset=0&limit=50",
		nil,
	)
	request.Header.Set("Authorization", "Bearer "+token)
	response = httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusOK || !strings.Contains(response.Body.String(), `"name":"src"`) {
		t.Fatalf("children status=%d body=%q", response.Code, response.Body.String())
	}
	for _, forbidden := range []string{root, child, fileName} {
		if strings.Contains(response.Body.String(), forbidden) {
			t.Fatalf("response exposed %q: %q", forbidden, response.Body.String())
		}
	}
}
```

Add table-driven tests with these exact expectations:

- no token or a token missing `directories:read` returns 401 and does not call `os.ReadDir`;
- malformed, expired, wrong-device, and evicted handles return 404 with `{"error":{"code":"directory_unavailable"}}` and do not echo the handle;
- revoked grants return 410 with `directory_revoked`;
- unreadable/removed directories return 409 with `directory_unavailable`;
- over 4,096 total entries or over 1,000 valid contained child directories returns 409 with `directory_too_large` and no `directories` field;
- `offset=-1`, `limit=0`, `limit=101`, unknown query keys, a nonempty GET body, and trailing path segments return 400 `invalid_request`;
- POST/PATCH/DELETE on either route return 405;
- successful and failed responses carry `Cache-Control: no-store` and `Wing-Protocol`;
- audit rows use only `directory.roots.read` or `directory.children.read` and never record names, handles, or paths.

- [x] **Step 2: Run route tests and verify RED**

Run:

```bash
cd wing_link
go test ./internal/app -run 'RemoteDirectory' -count=1
```

Expected: FAIL with 404 because the routes are not registered.

- [x] **Step 3: Wire one browser into `wingLinkServer`**

Add a `directories *workspaces.Browser` field. Construct it from `openDirectoryGrantStore(state.Path())` inside `newWingLinkServerWithOperations`. If the grant store cannot open, keep the routes unavailable and omit directory capabilities; do not fall back to a caller-supplied path.

Register only the two GET routes before profile compatibility routing. Obtain `authorization.Device.ID` through `requireDeviceAuthorization` and pass it into every browser call.

Strict response type:

```go
type remoteDirectory struct {
	Handle string `json:"handle"`
	Name   string `json:"name"`
}
```

Never serialize `workspaces.DirectoryGrant` because it contains `Path`.

- [x] **Step 4: Add capability and audit allowlists**

Metadata must advertise directory capabilities only when the browser exists. If the current `protocol.CurrentMetadata` cannot express runtime availability, change it to accept an additional bounded capability slice and merge/deduplicate known values; do not advertise Project capabilities.

Extend `auditOperationForRequest` with exact directory reads. Add the two operation values to the audit package's allowed operation set. Do not add a generic filesystem audit value.

- [x] **Step 5: Run Go validation**

Run:

```bash
cd wing_link
gofmt -w internal/app/workspaces.go internal/app/workspaces_test.go internal/app/serve.go internal/app/audit.go internal/protocol/metadata.go internal/protocol/metadata_test.go internal/audit/audit.go internal/audit/audit_test.go
go test -race ./... -count=1
go vet ./...
```

Expected: PASS. Search test output and source responses for temporary absolute paths before continuing.

---

### Task 4: Add strict Flutter Wing Link directory models and client methods

**Files:**

- Create: `lib/core/wing_link/models/wing_link_directory.dart`
- Modify: `lib/core/wing_link/wing_link_client.dart`
- Modify: `test/core/wing_link/wing_link_client_test.dart`

**Interfaces:**

- Produces: `WingLinkDirectory { String handle; String name }`
- Produces: `WingLinkDirectoryPage { List<WingLinkDirectory> directories; int? nextOffset }`
- Produces: `Future<List<WingLinkDirectory>> listDirectoryRoots()`
- Produces: `Future<WingLinkDirectoryPage> listChildDirectories({required String handle, int offset = 0, int limit = 50})`

- [x] **Step 1: Write strict parser and request tests**

Add tests proving valid data parses and invalid handles, names, counts, offsets, extra-large lists, and path-like response fields fail closed:

```dart
test('lists opaque directory roots without accepting host paths', () async {
  late Uri requested;
  final client = WingLinkClient(
    origin: Uri.parse('https://hermes.example:8654'),
    token: 'wlc-secret',
    get: (uri, headers) async {
      requested = uri;
      return jsonEncode({
        'directories': [
          {'handle': 'dirh_AAAAAAAAAAAAAAAAAAAAAA', 'name': 'repository'},
        ],
      });
    },
  );

  final roots = await client.listDirectoryRoots();

  expect(requested.path, '/v2/directories');
  expect(roots.single.name, 'repository');
  expect(roots.single.handle, startsWith('dirh_'));
});
```

For child requests, assert `handle` is path-encoded and `offset`/`limit` are the only query parameters. Reject any response row containing unsupported fields rather than silently accepting a future `path` field.

- [x] **Step 2: Run the focused Dart test and verify RED**

Run:

```bash
flutter test test/core/wing_link/wing_link_client_test.dart --plain-name 'lists opaque directory roots without accepting host paths'
```

Expected: compile failure because `listDirectoryRoots` does not exist.

- [x] **Step 3: Implement bounded immutable models**

Use explicit validation:

```dart
static final _handlePattern = RegExp(r'^dirh_[A-Za-z0-9_-]{22,92}$');

factory WingLinkDirectory.fromJson(Map<String, Object?> json) {
  if (json.keys.any((key) => key != 'handle' && key != 'name')) {
    throw const FormatException('Unexpected directory field');
  }
  final handle = json['handle'];
  final name = json['name'];
  if (handle is! String || !_handlePattern.hasMatch(handle) ||
      name is! String || name.isEmpty || utf8.encode(name).length > 255 ||
      name.contains('\u0000') || name.contains('/') || name.contains('\\')) {
    throw const FormatException('Invalid directory');
  }
  return WingLinkDirectory(handle: handle, name: name);
}
```

Import `dart:convert` for `utf8`. Require the complete root/page envelope to contain only `directories` and optional `next_offset`; reject unknown top-level fields. `listDirectoryRoots` accepts at most 32 rows and no `next_offset`. Child pages accept at most 100 rows. Validate `next_offset` as a nonnegative integer no greater than 1,000. Add boundary tests for 32/33 roots, 100/101 child rows, 255/256 UTF-8 bytes, and offsets 1,000/1,001 so Dart and Go enforce the same wire bounds.

- [x] **Step 4: Implement client methods**

`listDirectoryRoots` calls `/v2/directories`. `listChildDirectories` validates the handle and integer bounds before transport, then calls the encoded `/v2/directories/<handle>/children` route with `offset` and `limit` query parameters.

Do not cache handles in ordinary preferences or log request URIs.

- [x] **Step 5: Format and run focused tests**

Run:

```bash
dart format lib/core/wing_link/models/wing_link_directory.dart lib/core/wing_link/wing_link_client.dart test/core/wing_link/wing_link_client_test.dart
flutter test test/core/wing_link/wing_link_client_test.dart
flutter analyze
```

Expected: PASS.

---

### Task 5: Add accessible approved-folder browsing from Profiles

**Files:**

- Create: `lib/features/profiles/widgets/profile_directory_browser_sheet.dart`
- Modify: `lib/features/profiles/screens/profiles_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/app_localizations.dart`
- Regenerate: `lib/l10n/app_localizations_en.dart`
- Modify: `test/features/profiles/profiles_screen_test.dart`
- Create: `test/features/profiles/profile_directory_browser_sheet_test.dart`

**Interfaces:**

- Consumes: `WingLinkClient.listDirectoryRoots` and `listChildDirectories`
- Produces: `Future<void> showProfileDirectoryBrowser(BuildContext context, {required Future<List<WingLinkDirectory>> Function() loadRoots, required Future<WingLinkDirectoryPage> Function(String handle, int offset) loadChildren})`
- Keeps only opaque handles and display names in memory while the sheet is open
- Does not select, return, or persist a directory
- Does not call Project mutation in this plan

- [x] **Step 1: Write browser widget tests**

Create `test/features/profiles/profile_directory_browser_sheet_test.dart` with exact callback-driven tests—no fake repository class:

```dart
testWidgets('browses approved child folders by opaque handle', (tester) async {
  final childRequests = <(String, int)>[];
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) => Scaffold(
      body: FilledButton(
        onPressed: () => showProfileDirectoryBrowser(
          context,
          loadRoots: () async => const [
            WingLinkDirectory(
              handle: 'dirh_rootAAAAAAAAAAAAAAAAAA',
              name: 'repos',
            ),
          ],
          loadChildren: (handle, offset) async {
            childRequests.add((handle, offset));
            return const WingLinkDirectoryPage(
              directories: [
                WingLinkDirectory(
                  handle: 'dirh_childAAAAAAAAAAAAAAAAA',
                  name: 'wing',
                ),
              ],
            );
          },
        ),
        child: const Text('Browse'),
      ),
    )),
  ));

  await tester.tap(find.text('Browse'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('repos'));
  await tester.pumpAndSettle();

  expect(childRequests, [('dirh_rootAAAAAAAAAAAAAAAAAA', 0)]);
  expect(find.text('wing'), findsOneWidget);
  expect(find.byKey(const ValueKey('directory-browser-select')), findsNothing);
});
```

Add exact tests for:

- loading roots shows `directory-browser-loading` and disables navigation;
- no roots shows the selectable local instruction `wing-link directories grant PATH` and a Close action;
- entering two levels and pressing Back restores the prior display-name list without resolving a path;
- `nextOffset != null` shows `directory-browser-load-more`, and tapping it appends one page using that offset;
- the first `WingLinkException` or transport failure while loading children clears the breadcrumb and reloads roots once, because current transports intentionally do not expose non-2xx response bodies;
- a second failure shows the error state and Retry instead of looping;
- Retry starts again from roots and Close always remains available;
- 200% text scale has no overflow, keyboard traversal reaches Back/Retry/Close, and semantics announce loading/error state;
- no rendered text, semantics label, callback argument, or thrown test error contains `/tmp/host-root` or `private.txt`.

- [x] **Step 2: Run the browser test and verify RED**

Run:

```bash
flutter test test/features/profiles/profile_directory_browser_sheet_test.dart
```

Expected: compile failure because `showProfileDirectoryBrowser` does not exist.

- [x] **Step 3: Implement one responsive bottom sheet**

Use `showModalBottomSheet<void>` with `isScrollControlled: true`, a maximum content width of 640, and a height cap of 80% of the viewport. Do not add a second dialog presentation. Keep a stack of records containing only the parent handle, display name, loaded children, and next offset. Never write the stack to preferences.

Rows navigate deeper; the only terminal action is Close. On the first revoked/unavailable failure, clear the stack and reload roots. Track a boolean recovery attempt so the same failure cannot loop.

- [x] **Step 4: Wire a truthful Browse folders action**

Add optional `onBrowseDirectories` to `_ProfileCard`. For a Wing Link-managed profile, pressing it must:

1. call `getMetadata()`;
2. require `directories.roots.read` and `directories.children.read`;
3. call `getCurrentDevice()` and require `directories:read`;
4. open `showProfileDirectoryBrowser` with callbacks to the current `WingLinkClient`.

If capability or scope is absent, show the localized unavailable explanation. Do not show “Folder selected”, “Assign Project”, or “Create Project”, and do not infer support from Wing Link version.

- [x] **Step 5: Add localized copy and regenerate**

Add only browser title, loading/empty/revoked/error states, `wing-link directories grant PATH`, Browse folders, Back, Retry, Load more, Close, and Project-contract-unavailable explanation to `lib/l10n/app_en.arb`.

Run:

```bash
flutter gen-l10n
dart format lib/features/profiles/widgets/profile_directory_browser_sheet.dart lib/features/profiles/screens/profiles_screen.dart test/features/profiles/profile_directory_browser_sheet_test.dart test/features/profiles/profiles_screen_test.dart
```

- [x] **Step 6: Run profile and client validation**

Run:

```bash
flutter test test/core/wing_link/wing_link_client_test.dart
flutter test test/features/profiles/profile_directory_browser_sheet_test.dart
flutter test test/features/profiles/profiles_screen_test.dart
flutter analyze
```

Expected: PASS, including 200% text-scale coverage.

---

### Task 6: Update product truth and lock the Project mutation gate

**Files:**

- Modify: `docs/product/routes.md`
- Modify: `ROADMAP.md`
- Modify: `docs/plans/wing-link-remote-management.md`
- Modify: `docs/security/threat-model.md`
- Modify: `test/tooling/wing_link_docs_contract_test.dart`

**Interfaces:**

- `/profiles` truthfully reports approved-folder browsing as implemented only after Tasks 1–5 pass
- Project creation remains planned/blocked on the exact Agent contract
- No support claim for Project-aware Chat

- [x] **Step 1: Update route and roadmap wording**

Record exactly:

- locally granted roots can be browsed remotely through opaque handles;
- child folders only are returned;
- browsing state and handles are ephemeral and are not persisted;
- Project creation remains unavailable because the pinned Agent does not advertise a suitable machine-readable operation;
- Project-aware Chat remains separately gated.

Do not describe the picker as a file browser.

- [x] **Step 2: Update the existing remote-management plan status**

Change its stale “implementation has not started” status to distinguish completed hardening, in-flight/local grant work, completed remote directory selection after this plan, and blocked Project mutation. Preserve the broader approved design rather than replacing it.

- [x] **Step 3: Add the contract-removal trigger**

Document that a future Wing Link Project compatibility adapter is removed when the minimum supported Hermes Agent release advertises equivalent explicit-profile Project operations. Do not name an unverified version.

- [x] **Step 4: Lock the truthful documentation contract**

Extend `test/tooling/wing_link_docs_contract_test.dart` inside `Wing Link is a bounded remote management plane`:

```dart
final routes = File('docs/product/routes.md').readAsStringSync();
expect(routes, contains('opaque handles'));
expect(routes, contains('Project creation remains unavailable'));
expect(routes, isNot(contains('remote file browser')));
expect(roadmap, contains('child folders only'));
expect(roadmap, contains('Project-aware Chat remains gated'));
```

Use those exact phrases in the documentation updates so the test protects product truth rather than implementation syntax.

- [x] **Step 5: Run documentation validation**

Run:

```bash
flutter test test/tooling/wing_link_docs_contract_test.dart
git diff --check
rg -n "file browser|arbitrary path|project use|profile use" docs/product/routes.md ROADMAP.md docs/plans/wing-link-remote-management.md docs/security/threat-model.md
```

Expected: the focused test passes, there are no whitespace errors, and every search match is either a prohibition or an accurately gated statement.

---

## Separate follow-up plan: authoritative Hermes Project creation

Do not append Project mutation code to this plan. After the pinned Hermes Agent checkout contains and tests one accepted contract, create a dated `hermes-project-creation` plan under `docs/superpowers/plans/`.

That plan must start from the released contract and include, at minimum:

1. exact capability, authorization, profile identity, input, output, revision/idempotency, and error schemas;
2. if the contract is CLI compatibility rather than an advertised Agent operation, an approved update to `docs/adr/runtime-and-delivery.md` and `docs/adr/security-and-privacy.md` before production code;
3. Wing Link resolution of the selected device-bound handle to a freshly validated canonical path inside the fixed operation only;
4. no caller-selected path, executable, command, config key, URL, `profile use`, or `project use`;
5. authoritative Project list/create response reconciliation;
6. duplicate-name, concurrent-write, revoked-handle, symlink-race, timeout, and replay tests;
7. separate gating for Project-aware Chat.

The current upstream Desktop RPC and human-readable CLI are evidence of Agent functionality, not sufficient remote compatibility contracts.

---

## Final validation for this plan

Run the smallest focused checks above while iterating, then:

```bash
(cd wing_link && gofmt -w internal/app internal/state internal/workspaces internal/protocol internal/audit)
(cd wing_link && go test -race ./... && go vet ./...)
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --concurrency=1
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
npm audit
git diff --check
```

Before reporting completion:

- inspect the scoped diff for credentials, host paths, file names, request bodies, and unrelated edits;
- confirm remote responses and audit records cannot include paths or handles beyond the opaque token itself;
- confirm revoked roots and expired handles fail closed;
- confirm existing paired devices did not silently gain scopes;
- state which platforms were actually exercised;
- state plainly that Project creation and Project-aware Chat remain unsupported until the separate Agent contract lands.
