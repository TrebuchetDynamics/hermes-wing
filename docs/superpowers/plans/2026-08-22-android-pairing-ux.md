# Android Same-Device Pairing UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let an Android user pair Hermes Wing from a link displayed on that same phone in at most two taps, without Termux, ADB, manually copying an API token, or losing the multi-profile Wing Link bundle.

**Architecture:** Keep the existing five-minute, single-use Wing Link broker and review-before-exchange security boundary. Add a no-store local HTTP handoff page that the phone can open as an ordinary clickable URL and that, on an explicit button tap, launches the existing `wing://connect` Android intent. Then make the Flutter enrollment chooser explain same-device, second-screen QR, share, and single-profile manual paths clearly, and show the profile-bundle count before and after confirmation.

**Tech Stack:** Flutter 3.44.2, Dart, Riverpod, Android intents/Kotlin, Go 1.26 Wing Link broker, Flutter widget tests, Go unit tests, Android physical-device validation.

## Global Constraints

- Hermes Agent remains authoritative for profiles and credentials; Wing Link remains the pairing and host-management plane.
- Bearer credentials and Wing Link control tokens must never enter URLs, QR payloads, logs, clipboard, shared text, command arguments, or ordinary preferences.
- A pairing handoff may carry only a short-lived, single-use enrollment code; it must remain bounded, expire after five minutes, use `Cache-Control: no-store`, and never enter analytics or persistent logs.
- Non-loopback HTTP requires explicit review and is allowed only on trusted LAN/VPN/Tailscale; public plaintext HTTP remains unsupported.
- The default successful path imports the full verified profile bundle. Manual URL/token connection must be labeled as a one-profile fallback.
- Do not add a cloud rendezvous service, new QR package, background clipboard monitoring, or automatic clipboard reads.
- Preserve current origin-mismatch checks, same-host broker/control validation, token redaction, secure storage, exchange idempotency, and post-exchange Wing Link acknowledgement.
- Preserve unrelated dirty-worktree changes; stage and commit only the files named by each task.

---

## Research Summary

### Current flow and observed failures

- Android already accepts `ACTION_VIEW` for `wing://connect` and `ACTION_SEND` for `text/plain` in `android/app/src/main/AndroidManifest.xml` and `PairingHandoffIntentParser.kt`.
- The enrollment screen offers camera QR scanning and a generic manual gateway form, but no explicit same-device action. A camera cannot scan a QR displayed on the same phone.
- Many chat/browser surfaces do not make an unverified custom `wing://` URI tappable. This forced Termux/ADB instructions during the observed session.
- The manual form adds one endpoint. It does not exchange the Wing Link bundle, so a host with nine Hermes profiles appeared as one endpoint.
- The screen copy still says `wing-cli`, while the product command is `wing-link`.
- Expired pairing produces a generic failure and forces the operator to infer how to recover.
- Current policy text conflicts with current implementation: `CONTEXT.md` calls pairing codes secrets that cannot enter URLs/QR/shared text, while the implemented protocol intentionally carries a single-use code in a QR/deep link. The plan resolves this by distinguishing ephemeral handoff codes from bearer credentials.
- The checked-in `wing_link/wing-link` binary did not match source behavior (`--remote` exists in source but was rejected by the binary), so release/version validation belongs in closeout.

### Platform findings

- Android verified App Links require an owned HTTPS origin, `android:autoVerify`, and a Digital Asset Links association containing the production signing fingerprints. They are the strongest long-term one-tap handler binding, but a private IP/Tailscale HTTP broker cannot itself be verified. A static controlled HTTPS handoff domain could be added later without proxying pairing traffic through a cloud relay: https://developer.android.com/training/app-links/verify-android-applinks and https://developer.android.com/about/versions/12/behavior-changes-all#web-intent-resolution
- Android supports receiving user-initiated shared text via `ACTION_SEND`; Wing already declares this path, so the lowest-risk fallback is to make it discoverable and parse bounded surrounding text safely: https://developer.android.com/training/sharing/receive and https://developer.android.com/training/sharing/send
- Android custom-scheme/intent navigation is appropriate only after a user gesture. A locally served page with an **Open Hermes Wing** button provides that gesture without a cloud service: https://developer.chrome.com/docs/android/intents
- Every external ingress is untrusted. App Links, custom links, shares, paste, camera QR, and any future image QR must use the same allowlisted parser and explicit confirmation boundary: https://developer.android.com/privacy-and-security/risks/unsafe-use-of-deeplinks
- Clipboard access must be explicit and minimized. Do not inspect the clipboard on screen entry; use one user-initiated paste action and immediately discard the raw value after parsing: https://developer.android.com/develop/ui/views/touch-and-input/copy-paste and https://developer.android.com/privacy-and-security/risks/secure-clipboard-handling
- Android Photo Picker plus on-device ML Kit barcode decoding is the appropriate future screenshot/image-QR fallback because it needs no broad media permission or upload. It is a separate size/dependency decision, not part of the P0 slice: https://developer.android.com/training/data-storage/shared/photopicker and https://developers.google.com/ml-kit/vision/barcode-scanning/android
- Device authorization patterns favor a short-lived, single-use handoff plus an explicit user confirmation rather than exposing a long-lived credential. The existing broker already follows that shape: https://www.rfc-editor.org/rfc/rfc8628

### Recommended priority

1. **P0:** Host-side ordinary HTTP handoff page with one **Open Hermes Wing** button.
2. **P0:** Android chooser language that distinguishes same-phone, second-screen QR, share/paste, and one-profile manual connection.
3. **P0:** Multi-profile count in review and success states.
4. **P1:** Explicit paste fallback and robust extraction from shared prose.
5. **P1:** Expired-link countdown and recovery actions.
6. **P2 decision gate:** Add a verified HTTPS App Link only when an owned domain, release signing fingerprints, and static `assetlinks.json` maintenance are approved.
7. **P2 decision gate:** Add Photo Picker + on-device image QR decoding only after measuring dependency/APK impact and confirming screenshot import remains necessary after the P0 same-device page ships.
8. **Out of scope:** Cloud rendezvous and automatic clipboard monitoring.

---

## File Structure

### New files

- `wing_link/internal/app/pair_open.go` — renders the no-store local handoff page and builds the Android intent URI.
- `wing_link/internal/app/pair_open_test.go` — verifies headers, escaping, intent target, expiry copy, and absence of bearer material.

### Modified files

- `wing_link/internal/app/pair.go` — registers `/open`, exposes the ordinary handoff URL, and adds bounded profile count to inspection.
- `wing_link/internal/app/cli.go` — documents the same-device URL behavior.
- `wing_link/internal/app/pair_test.go` — verifies broker inspection count and CLI output no longer prints the raw code separately.
- `lib/features/enrollment/models/hermes_enrollment_payload.dart` — extracts exactly one bounded `wing://connect` URI from explicit paste/share text before existing strict parsing.
- `lib/features/enrollment/screens/hermes_enrollment_screen.dart` — adds same-device guidance, explicit paste, clearer action hierarchy, profile-count review, and non-instant success.
- `lib/features/enrollment/providers/hermes_enrollment_provider.dart` — retains bounded connection count through confirmation and distinguishes expired input.
- `lib/core/hermes/client/hermes_api_client.dart` — parses `connection_count` from inspection.
- `android/app/src/main/kotlin/com/trebuchetdynamics/hermes/wing/pairing/PairingHandoffIntentParser.kt` — keeps ACTION_SEND bounded and rejects oversized shared text before Flutter.
- `lib/l10n/app_en.arb` plus generated localization files — new same-device, paste, one-profile, profile-count, expiry, and success copy.
- `test/features/enrollment/hermes_enrollment_payload_test.dart` — extraction and ambiguity tests.
- `test/features/enrollment/hermes_enrollment_flow_test.dart` — chooser, paste, count, success, expiry, and no-secret-render tests.
- `android/app/src/test/kotlin/com/trebuchetdynamics/hermes/wing/pairing/PairingHandoffIntentParserTest.kt` — shared-text bounds and malformed input tests.
- `CONTEXT.md`, `docs/adr/security-and-privacy.md`, `docs/security/threat-model.md` — align ephemeral handoff-code policy with the implemented protocol.
- `README.md`, `docs/runbooks/android-hermes-setup.md`, `docs/runbooks/android/release-handoff.md` — replace Termux/ADB-first instructions with ordinary same-device link instructions.

---

### Task 1: Align the pairing security contract

**Files:**
- Modify: `CONTEXT.md:93-98`
- Modify: `docs/adr/security-and-privacy.md:5-19`
- Modify: `docs/security/threat-model.md`
- Test: `test/tooling/package_scripts_contract_test.dart`

**Interfaces:**
- Consumes: existing five-minute single-use broker and review-before-exchange contract.
- Produces: one unambiguous policy used by every later task: ephemeral pairing codes are allowed only in bounded handoff surfaces; bearer credentials remain forbidden everywhere outside secure exchange/storage.

- [ ] **Step 1: Write the failing source-contract test**

Add a test that reads all three policy documents and requires these concepts:

```dart
test('pairing policy distinguishes handoff codes from bearer credentials', () {
  final context = File('CONTEXT.md').readAsStringSync();
  final adr = File('docs/adr/security-and-privacy.md').readAsStringSync();
  final threat = File('docs/security/threat-model.md').readAsStringSync();

  for (final document in [context, adr, threat]) {
    expect(document, contains('single-use pairing code'));
    expect(document, contains('five minutes'));
    expect(document, contains('never contains a bearer credential'));
    expect(document, contains('no-store'));
  }
});
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
flutter test test/tooling/package_scripts_contract_test.dart --plain-name 'pairing policy distinguishes handoff codes from bearer credentials'
```

Expected: FAIL because the documents currently contradict the implemented QR/deep-link protocol.

- [ ] **Step 3: Replace the conflicting policy language**

Use this normative distinction in each document:

```markdown
A pairing handoff may carry a random single-use pairing code in a QR code,
`wing://connect` intent, explicit Android share, or the ephemeral local handoff
page. The code expires after five minutes, never contains a bearer credential,
and must not be persisted, analyzed, included in diagnostics, or written to
ordinary logs. Hermes API keys, Wing Link control tokens, provider credentials,
and exchanged bearer credentials remain forbidden in URLs, QR payloads,
clipboards, shared text, command arguments, and ordinary preferences.
```

Document that explicit paste is a user-initiated fallback, not background clipboard monitoring, and that the app drops the raw text immediately after parsing.

- [ ] **Step 4: Run the policy test and inspect the diff**

Run:

```bash
flutter test test/tooling/package_scripts_contract_test.dart --plain-name 'pairing policy distinguishes handoff codes from bearer credentials'
git diff --check
```

Expected: PASS; no bearer-credential rule is weakened.

- [ ] **Step 5: Commit only the policy slice**

```bash
git add CONTEXT.md docs/adr/security-and-privacy.md docs/security/threat-model.md test/tooling/package_scripts_contract_test.dart
git commit -m "docs: clarify pairing handoff security boundary"
```

---

### Task 2: Add an ordinary same-device handoff page to Wing Link

**Files:**
- Create: `wing_link/internal/app/pair_open.go`
- Create: `wing_link/internal/app/pair_open_test.go`
- Modify: `wing_link/internal/app/pair.go:150-273`

**Interfaces:**
- Consumes: `pairingBroker.PairingURI`, broker origin, and `expiresAt` from `createPairingBroker`.
- Produces: `pairingBroker.OpenURL *url.URL`, `GET /open`, and `androidIntentURI(pairingURI *url.URL) string`.

- [ ] **Step 1: Write failing tests for the page and Android intent URI**

Create `pair_open_test.go` with these assertions:

```go
func TestAndroidIntentURIKeepsTheReviewedWingPayload(t *testing.T) {
	pairing, err := url.Parse("wing://connect?broker=http%3A%2F%2F100.64.0.8%3A43001&code=one-time&origin=http%3A%2F%2F100.64.0.8%3A8642")
	if err != nil { t.Fatal(err) }
	got := androidIntentURI(pairing)
	want := "intent://connect?broker=http%3A%2F%2F100.64.0.8%3A43001&code=one-time&origin=http%3A%2F%2F100.64.0.8%3A8642#Intent;scheme=wing;package=com.trebuchetdynamics.hermes.wing;end"
	if got != want { t.Fatalf("intent URI = %q, want %q", got, want) }
}

func TestPairOpenPageIsNoStoreAndLaunchesWing(t *testing.T) {
	pairing, _ := url.Parse("wing://connect?origin=http%3A%2F%2F100.64.0.8%3A8642&code=one-time")
	request := httptest.NewRequest(http.MethodGet, "/open", nil)
	response := httptest.NewRecorder()
	handlePairOpen(pairing, time.Now().Add(5*time.Minute))(response, request)

	if response.Code != http.StatusOK { t.Fatalf("status = %d", response.Code) }
	if response.Header().Get("Cache-Control") != "no-store" { t.Fatal("missing no-store") }
	if response.Header().Get("Referrer-Policy") != "no-referrer" { t.Fatal("missing no-referrer") }
	body := response.Body.String()
	if !strings.Contains(body, "Open Hermes Wing") { t.Fatal("missing primary action") }
	if !strings.Contains(body, "com.trebuchetdynamics.hermes.wing") { t.Fatal("missing Android package") }
	if strings.Contains(body, "api_server_key") || strings.Contains(body, "Bearer ") { t.Fatal("bearer material rendered") }
}
```

Add tests for `POST /open` returning 405 and for HTML escaping a malicious pairing URI.

- [ ] **Step 2: Run the Go tests and verify they fail**

Run:

```bash
cd wing_link
go test ./internal/app -run 'Test(AndroidIntentURI|PairOpenPage)' -count=1
```

Expected: compile failure because the new interfaces do not exist.

- [ ] **Step 3: Implement the intent builder and no-store page**

Create `pair_open.go` with a static, dependency-free HTML response. Use `html/template`, never string concatenation, for URI insertion:

```go
package app

import (
	"html/template"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const androidWingPackage = "com.trebuchetdynamics.hermes.wing"

func androidIntentURI(pairing *url.URL) string {
	query := pairing.RawQuery
	return "intent://connect?" + query + "#Intent;scheme=wing;package=" + androidWingPackage + ";end"
}

var pairOpenTemplate = template.Must(template.New("pair-open").Parse(`<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="referrer" content="no-referrer"><title>Open Hermes Wing</title></head>
<body><main><h1>Connect to Hermes</h1>
<p>Open Hermes Wing on this Android device to review this five-minute pairing request.</p>
<p><a href="{{.IntentURI}}">Open Hermes Wing</a></p>
<p>If Wing does not open, return to Wing and choose Scan QR from another screen.</p>
</main></body></html>`))

func handlePairOpen(pairing *url.URL, expiresAt time.Time) http.HandlerFunc {
	return func(writer http.ResponseWriter, request *http.Request) {
		writer.Header().Set("Cache-Control", "no-store")
		writer.Header().Set("Pragma", "no-cache")
		writer.Header().Set("Referrer-Policy", "no-referrer")
		writer.Header().Set("Content-Security-Policy", "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'")
		writer.Header().Set("Content-Type", "text/html; charset=utf-8")
		if request.Method != http.MethodGet { writer.WriteHeader(http.StatusMethodNotAllowed); return }
		if !time.Now().Before(expiresAt) { writer.WriteHeader(http.StatusGone); return }
		_ = pairOpenTemplate.Execute(writer, map[string]string{"IntentURI": androidIntentURI(pairing)})
	}
}
```

Remove the unused `strings` import if the final implementation does not use it. Do not add JavaScript or external assets.

- [ ] **Step 4: Register `/open` and expose `OpenURL`**

Extend `pairingBroker`:

```go
type pairingBroker struct {
	PairingURI *url.URL
	OpenURL    *url.URL
	Done       <-chan struct{}
	server     *http.Server
	listener   net.Listener
}
```

In `createPairingBroker`, build `pairingURI` once, register `mux.HandleFunc("/open", handlePairOpen(pairingURI, expiresAt))`, and set:

```go
OpenURL: brokerOrigin.ResolveReference(&url.URL{Path: "/open"}),
```

The existing JSON inspect/exchange endpoints remain POST-only and unchanged.

- [ ] **Step 5: Run focused and broad Go tests**

Run:

```bash
cd wing_link
go test ./internal/app -run 'Test(AndroidIntentURI|PairOpenPage|Pair)' -count=1
go test ./... -count=1
```

Expected: PASS.

- [ ] **Step 6: Commit the broker slice**

```bash
git add wing_link/internal/app/pair.go wing_link/internal/app/pair_open.go wing_link/internal/app/pair_open_test.go
git commit -m "feat: add same-device Android pairing handoff"
```

---

### Task 3: Make the CLI output lead with the Android-safe URL

**Files:**
- Modify: `wing_link/internal/app/pair.go:80-125`
- Modify: `wing_link/internal/app/cli.go:80-115`
- Modify: `wing_link/internal/app/pair_test.go`
- Modify: `README.md:164-227`
- Modify: `docs/runbooks/android-hermes-setup.md:45-64`
- Modify: `docs/runbooks/android/release-handoff.md`

**Interfaces:**
- Consumes: `pairingBroker.OpenURL` from Task 2.
- Produces: default human output with an ordinary `http(s)://.../open` URL first, QR second, and no separately printed raw code.

- [ ] **Step 1: Write a failing CLI-output test**

Add a test around the existing pair command writer:

```go
if !strings.Contains(output, "On the Android phone, open:") {
	t.Fatal("missing same-device instruction")
}
if !strings.Contains(output, broker.OpenURL.String()) {
	t.Fatal("missing ordinary handoff URL")
}
if strings.Contains(output, "pair: code:") {
	t.Fatal("raw code must not be printed separately")
}
if strings.Index(output, broker.OpenURL.String()) > strings.Index(output, "Scan the QR") {
	t.Fatal("same-device path must be presented before QR")
}
```

- [ ] **Step 2: Run the focused test and verify it fails**

```bash
cd wing_link
go test ./internal/app -run 'TestPair.*Output' -count=1
```

Expected: FAIL because current output leads with QR/raw custom URI and prints the code separately.

- [ ] **Step 3: Replace the human instructions**

Use this hierarchy:

```text
pair: Pair with Hermes Wing (expires in 5 minutes)
pair:
pair: On the Android phone, open:
pair:   <tailscale-ip>:<port>/open
pair:
pair: Or scan this QR from a different screen:
<QR>
pair:
pair: Review the host, access, and profile count in Hermes Wing, then confirm.
```

Do not print the raw code separately. Keep the raw `wing://connect` URI available only inside the QR and `/open` page. Keep JSON/machine output behavior unchanged if one exists.

- [ ] **Step 4: Update help and runbooks**

Document:

1. Same Android device: tap the ordinary `/open` URL.
2. Different screen: scan the QR.
3. Existing text message: use Android Share → Hermes Wing.
4. Manual URL/token: one-profile recovery only, never the recommended multi-profile flow.

Replace stale `wing-cli` naming with `wing-link`. Ensure `--remote` examples match the source parser and require the encrypted-VPN confirmation variable where applicable.

- [ ] **Step 5: Test source and installed artifact behavior**

```bash
cd wing_link
go test ./... -count=1
go build -o /tmp/wing-link-plan-check ./cmd/wing-link
/tmp/wing-link-plan-check help
/tmp/wing-link-plan-check version
```

Expected: source tests pass; the built binary help recognizes the documented pair flags. Do not overwrite `~/.local/bin/wing-link` in this task.

- [ ] **Step 6: Commit the CLI/docs slice**

```bash
git add wing_link/internal/app/pair.go wing_link/internal/app/cli.go wing_link/internal/app/pair_test.go README.md docs/runbooks/android-hermes-setup.md docs/runbooks/android/release-handoff.md
git commit -m "feat: lead pairing with same-device Android link"
```

---

### Task 4: Add explicit paste/share recovery to the Android chooser

**Files:**
- Modify: `lib/features/enrollment/models/hermes_enrollment_payload.dart`
- Modify: `lib/features/enrollment/screens/hermes_enrollment_screen.dart`
- Modify: `android/app/src/main/kotlin/com/trebuchetdynamics/hermes/wing/pairing/PairingHandoffIntentParser.kt`
- Modify: `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/app_localizations.dart`
- Regenerate: `lib/l10n/app_localizations_en.dart`
- Test: `test/features/enrollment/hermes_enrollment_payload_test.dart`
- Test: `test/features/enrollment/hermes_enrollment_flow_test.dart`
- Test: `android/app/src/test/kotlin/com/trebuchetdynamics/hermes/wing/pairing/PairingHandoffIntentParserTest.kt`

**Interfaces:**
- Consumes: existing strict `HermesEnrollmentPayload.parse` and Android ACTION_SEND channel.
- Produces: `HermesEnrollmentPayload.parseExplicitHandoff(String value, {bool cleartextOriginConfirmed = false})` and an explicit user-triggered paste action.

- [ ] **Step 1: Write failing extraction tests**

Add cases that accept exactly one bounded URI in user-shared prose and reject ambiguity/oversize:

```dart
test('extracts one pairing URI from explicit shared text', () {
  final payload = HermesEnrollmentPayload.parseExplicitHandoff(
    'Pair this phone:\nwing://connect?origin=https%3A%2F%2Fhermes.example&code=once',
  );
  expect(payload.origin, Uri.parse('https://hermes.example'));
  expect(payload.code, 'once');
});

test('rejects shared text containing two pairing URIs', () {
  expect(
    () => HermesEnrollmentPayload.parseExplicitHandoff(
      'wing://connect?origin=https%3A%2F%2Fa.example&code=a '
      'wing://connect?origin=https%3A%2F%2Fb.example&code=b',
    ),
    throwsFormatException,
  );
});

test('rejects oversized shared text before URI parsing', () {
  expect(
    () => HermesEnrollmentPayload.parseExplicitHandoff('x' * 4097),
    throwsFormatException,
  );
});
```

- [ ] **Step 2: Run tests and verify they fail**

```bash
flutter test test/features/enrollment/hermes_enrollment_payload_test.dart
```

Expected: compile failure because `parseExplicitHandoff` does not exist.

- [ ] **Step 3: Implement bounded extraction**

Add a 4096-character input limit. Locate standalone `wing://connect?` candidates by whitespace-delimited tokenization, trim only `<`, `>`, `(`, `)`, `[`, `]`, and quotes from token edges, require exactly one candidate, then pass that exact candidate through the existing strict parser. Do not relax origin, same-host, fragment, userinfo, `token`, or code-length validation.

Route every Flutter ingress through `parseExplicitHandoff`: native ACTION_VIEW and camera QR already arrive as exact URIs, while ACTION_SEND and paste may contain surrounding prose. Keep ACTION_VIEW strict at the native parser boundary, so this shared Dart entry point does not broaden what Android may launch directly.

- [ ] **Step 4: Bound ACTION_SEND before crossing the method channel**

In Kotlin, reject `text.length > 4096` and blank text. Do not log the shared text. Preserve `text/plain` filtering and current ACTION_VIEW strictness.

Add native tests:

```kotlin
@Test fun oversizedSharedTextIsRejected() {
    assertNull(PairingHandoffIntentParser.parse(
        action = PairingHandoffIntentParser.ACTION_SEND,
        type = "text/plain",
        data = null,
        text = "x".repeat(4097),
    ))
}
```

- [ ] **Step 5: Add the Android chooser hierarchy and explicit paste**

Replace the centered prompt/Wrap with vertically ordered, full-width actions:

1. Primary `FilledButton.icon`: **Paste pairing link**.
2. Secondary `FilledButton.tonalIcon`: **Scan QR from another screen**.
3. Helper text: **If the link is on this phone, tap it or share it to Hermes Wing.**
4. Tertiary `OutlinedButton.icon`: **Connect one profile manually**.
5. Supporting text under manual: **This does not import Wing Link or other Hermes profiles.**

Implement paste as a single explicit call:

```dart
Future<void> _pastePairingLink() async {
  setState(() => _payloadError = null);
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  if (!mounted) return;
  final raw = data?.text;
  if (raw == null || raw.trim().isEmpty) {
    setState(() => _payloadError = AppLocalizations.of(context).enrollClipboardEmpty);
    return;
  }
  _handleExplicitHandoff(raw);
}
```

`_handleExplicitHandoff` must parse with `parseExplicitHandoff`, drop `raw` when the method returns, never save it in widget state, and never render the URI/code. Do not inspect the clipboard during `initState`, `build`, or route entry. Do not clear or overwrite the user’s clipboard.

Use minimum 48dp touch height, 12dp vertical gaps, and wrapping copy that remains usable at 200% text scale.

- [ ] **Step 6: Add widget tests**

Test that:

- Android idle state shows paste, scan-from-another-screen, and one-profile manual actions in that order.
- Explicit paste calls inspection once.
- Empty or invalid clipboard content shows an inline recovery message.
- No `Text` widget ever contains the pairing code.
- Manual form still returns to the chooser on Android back.
- ACTION_SEND and cold/warm ACTION_VIEW still route to enrollment.

Use `TestDefaultBinaryMessengerBinding` to mock `Clipboard.getData`; restore the handler in teardown.

- [ ] **Step 7: Regenerate localization and run focused checks**

```bash
flutter gen-l10n
dart format lib/features/enrollment test/features/enrollment
flutter test test/features/enrollment test/app/wing_app_connect_intent_test.dart --concurrency=1
(cd android && ./gradlew app:testDebugUnitTest --tests '*PairingHandoffIntentParserTest')
```

Expected: PASS; no test output includes a real pairing code.

- [ ] **Step 8: Commit the Android input slice**

```bash
git add lib/features/enrollment android/app/src/main/kotlin/com/trebuchetdynamics/hermes/wing/pairing/PairingHandoffIntentParser.kt android/app/src/test/kotlin/com/trebuchetdynamics/hermes/wing/pairing/PairingHandoffIntentParserTest.kt lib/l10n test/features/enrollment test/app/wing_app_connect_intent_test.dart
git commit -m "feat: add same-device pairing input options"
```

---

### Task 5: Make multi-profile import visible before and after confirmation

**Files:**
- Modify: `wing_link/internal/app/pair.go:187-202`
- Modify: `wing_link/internal/app/pair_test.go`
- Modify: `lib/core/hermes/client/hermes_api_client.dart`
- Modify: `lib/features/enrollment/providers/hermes_enrollment_provider.dart`
- Modify: `lib/features/enrollment/screens/hermes_enrollment_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/app_localizations.dart`
- Regenerate: `lib/l10n/app_localizations_en.dart`
- Test: `test/features/enrollment/hermes_enrollment_flow_test.dart`
- Test: `test/core/hermes/hermes_api_test.dart`

**Interfaces:**
- Produces: inspection JSON field `connection_count` as an integer from 1 through 100.
- Produces: `HermesEnrollmentPreview.connectionCount`, `HermesEnrollmentController.connectedProfileCount`, and `HermesEnrollmentController.clearConfirmed()`.

- [ ] **Step 1: Write failing Go inspection tests**

For compatibility mode with nine prepared connections:

```go
if got := int(preview["connection_count"].(float64)); got != 9 {
	t.Fatalf("connection_count = %d, want 9", got)
}
```

For scoped/single mode, require `connection_count == 1`. Never return profile tokens or credential IDs from inspection.

- [ ] **Step 2: Add `connection_count` to inspection**

In `pair.go`:

```go
connectionCount := len(options.Connections)
if connectionCount == 0 { connectionCount = 1 }
```

Include only the count in inspection. Do not expose profile IDs before confirmation in this slice.

- [ ] **Step 3: Write failing Dart parse/controller tests**

Require:

- missing `connection_count` defaults to 1 for compatibility with older brokers;
- values below 1, above 100, or non-integers fail closed;
- a nine-connection exchange leaves `connectedProfileCount == 9` after secrets are cleared;
- cancellation resets the count;
- no token reaches widget text.

- [ ] **Step 4: Implement bounded count propagation**

Extend the preview model and parser:

```dart
final int connectionCount;
```

Default missing server data to 1. Reject malformed explicit values. In `confirm`, set `_connectedProfileCount = configs.length` only after secure store commit and Wing Link acknowledgement succeed. Keep `_code`, tokens, and issued objects out of controller state.

- [ ] **Step 5: Replace generic review/success copy**

Review state:

```text
Connect 9 Hermes profiles from BlueBlack?
Hermes Agent       <tailscale-ip>:<agent-port>
Wing Link          <tailscale-ip>:<wing-link-port>
Access             Full Hermes access
Profiles           9
Expires            4:32
```

Primary button: **Connect 9 profiles**.

Success state:

```text
9 profiles connected
Wing Link is ready for profile and gateway management.
[View profiles]   [Open chat]
```

Remove the current immediate redirect on `confirmed`. Route **View profiles** to `AppRoutes.profiles` and **Open chat** to `AppRoutes.hermes`. Keep Android back predictable.

Manual connection copy must read **Connect one profile manually** and must not imply that it imports Wing Link management.

- [ ] **Step 6: Add widget tests for the complete outcome**

Test exactly:

- review displays count 9 and button `Connect 9 profiles`;
- exchange is not called before confirmation;
- confirmed state stays visible until a user action;
- `View profiles` routes to `/profiles`;
- one-profile grammar is singular;
- failed ninth-profile verification commits no partial bundle;
- token and raw code are absent from all rendered text and semantics.

- [ ] **Step 7: Run both protocol sides**

```bash
(cd wing_link && go test ./... -count=1)
flutter test test/core/hermes/hermes_api_test.dart test/features/enrollment/hermes_enrollment_flow_test.dart --concurrency=1
flutter analyze lib/core/hermes/client/hermes_api_client.dart lib/features/enrollment test/features/enrollment
```

Expected: PASS.

- [ ] **Step 8: Commit the profile-transparency slice**

```bash
git add wing_link/internal/app/pair.go wing_link/internal/app/pair_test.go lib/core/hermes/client/hermes_api_client.dart lib/features/enrollment lib/l10n test/core/hermes/hermes_api_test.dart test/features/enrollment/hermes_enrollment_flow_test.dart
git commit -m "feat: show multi-profile pairing outcome"
```

---

### Task 6: Add expiry recovery and complete Android qualification

**Files:**
- Modify: `lib/features/enrollment/providers/hermes_enrollment_provider.dart`
- Modify: `lib/features/enrollment/screens/hermes_enrollment_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/app_localizations.dart`
- Regenerate: `lib/l10n/app_localizations_en.dart`
- Modify: `test/features/enrollment/hermes_enrollment_flow_test.dart`
- Modify: `docs/quality/evidence-matrix.md`
- Create: `.maestro/android-pairing-same-device.yaml`

**Interfaces:**
- Produces: actionable `expired`, `unreachable`, `invalid`, and `exchangeFailed` presentation states without exposing server response bodies or secrets.

- [ ] **Step 1: Write failing expiry/recovery widget tests**

Inject a clock into `HermesEnrollmentController`:

```dart
typedef EnrollmentClock = DateTime Function();
```

Test that a preview expiring at `12:05:00` displays `4:59` at `12:00:01`, disables confirmation at expiry, and presents:

```text
This pairing link expired
Run wing-link pair again, then open the new link or scan its QR.
[Paste another link] [Scan another QR]
```

Do not display raw exception strings from the broker.

- [ ] **Step 2: Implement countdown without lifecycle leaks**

Use one `Timer.periodic(const Duration(seconds: 1), ...)` only while status is ready/confirming and expiry exists. Cancel it on status change and `dispose`. Derive remaining time from the injected clock; do not decrement mutable seconds, which drifts during app suspension.

In `confirm`, re-check expiry before exchange. If expired, clear `_code`, set a typed expired status, and never call exchange.

- [ ] **Step 3: Add the Maestro same-device flow**

The flow must cover:

1. Start Wing with no pending enrollment.
2. Assert same-device, QR, and one-profile manual choices.
3. Deliver an ACTION_SEND pairing fixture to the app.
4. Review host, cleartext warning, and profile count.
5. Confirm and assert `9 profiles connected`.
6. Open Profiles and assert all fixture profiles are available.
7. Repeat with an expired fixture and assert recovery actions.

Use fixture codes only. Never write live tokens, private URLs, or transcripts into `.maestro`.

- [ ] **Step 4: Run the complete deterministic gate**

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --concurrency=1
(cd wing_link && go test ./... -count=1)
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
npm audit
git diff --check
```

Expected: all relevant checks pass; disclose unrelated pre-existing environment failures rather than masking them.

- [ ] **Step 5: Build and qualify on the Galaxy S24 Ultra**

```bash
flutter build apk --release --split-per-abi
adb -s RFCX81EJPNN install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Physical test matrix:

- Cold app + ordinary `http://<broker>/open` URL → one tap **Open Hermes Wing** → review.
- Warm app + same URL → review without duplicate navigation.
- Android Share → Hermes Wing with the handoff embedded in surrounding text.
- Camera QR from a second screen.
- Expired and reused links.
- Tailscale HTTP warning and explicit confirmation.
- Nine-profile import, secure acknowledgement, and profile list.
- TalkBack labels/focus order.
- 200% font scale, portrait, and landscape.
- Android back from review, manual fallback, success, and Profiles.
- `adb logcat` scan confirming no code, URI, Hermes token, or Wing Link token is logged.

Acceptance criteria:

- Same-device path requires no Termux, ADB, raw custom URI manipulation, or API token.
- Ordinary URL to review requires at most two user taps.
- Manual path is visibly one-profile-only.
- Profile bundle count before confirmation equals profiles committed after confirmation.
- No partial bundle survives a verification/acknowledgement failure.
- All touch targets are at least 48dp and layout remains operable at 200% text scale.

- [ ] **Step 6: Update evidence and commit qualification artifacts**

Record only non-secret fixture receipts and device/build identifiers in `docs/quality/evidence-matrix.md`. Do not commit live QR images, pairing URLs, endpoint addresses, tokens, or `build/` output.

```bash
git add lib/features/enrollment lib/l10n test/features/enrollment .maestro/android-pairing-same-device.yaml docs/quality/evidence-matrix.md
git commit -m "test: qualify Android same-device pairing"
```

---

## Follow-up Decision Gates

These are intentionally separate plans because each introduces a new ownership/dependency boundary.

### Verified HTTPS App Link

Proceed only if Trebuchet Dynamics approves an owned HTTPS handoff domain and can publish `/.well-known/assetlinks.json` for every production signing certificate. The handoff document must be static, must not proxy or store pairing traffic, and should carry the ephemeral payload in a fragment so ordinary HTTP access logs do not receive it. Add `android:autoVerify="true"`, retain `wing://connect` compatibility, and test Android 12+ verified-link behavior plus signing-key rotation. If no controlled domain is available, keep the private broker `/open` page as the primary path.

### Choose QR Image

Proceed only if physical testing shows a material screenshot-import need after `/open`, Share, and Paste ship. Use Android Photo Picker with no broad media permission, decode entirely on-device through ML Kit Barcode Scanning, pass the result through `parseExplicitHandoff`, and delete image references immediately after decode. Record the incremental ARM64 APK size before approval because the project is actively removing unused native/model weight.

---

## Self-Review

- **Spec coverage:** Same-device launch, QR fallback, explicit share/paste, manual-path clarity, multi-profile outcome, expiry recovery, security policy, docs, deterministic tests, and physical Android evidence each have a task.
- **No cloud dependency:** P0 uses the private broker directly. A static verified App Link remains an optional, separately approved handler-binding layer and must not relay pairing traffic.
- **No secret regression:** The plan never puts bearer credentials into the handoff. Raw pairing input is user-initiated, bounded, immediately discarded, and never rendered/logged.
- **Type consistency:** `connection_count` maps to `HermesEnrollmentPreview.connectionCount` and then to `HermesEnrollmentController.connectedProfileCount`; `pairingBroker.OpenURL` is produced before CLI use.
- **YAGNI:** No gallery QR decoder, new scanner package, cloud rendezvous, or automatic clipboard watcher.
- **Known limitation:** The local `/open` page depends on the Android browser permitting a user-initiated `intent://` launch. The physical-device matrix explicitly verifies this before release claims.
