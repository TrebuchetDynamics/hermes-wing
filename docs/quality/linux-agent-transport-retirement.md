# Linux Agent transport journey retirement

Task: `t_7795c4c1`, bounded consumer slice of
[CONNECTION-LINK-REMOVAL](../../TODO.md#now--next).
Admitted base: `f78b164ac3f2315284f88120c6b1238b48e55248`.
The [accepted retirement decision](../adr/product.md#complete-removal-including-legacy)
requires removing client consumers while preserving retained service safety.

## Change and acceptance

- `integration_test/linux_transport_boundary_test.dart` no longer imports or
  invokes the retained Wing Link transport test. It still initializes the native
  integration binding and invokes the exact Agent transport and SSE suites.
- `test/tooling/enrollment_retirement_contract_test.dart` rejects management
  imports, symbols and groups in that entry; checks the exact retained Agent/SSE
  imports and groups; and preserves the Linux runner's entry selection and order.
- `scripts/run_linux_e2e.sh` is unchanged: fixture, HTTP and transport entries
  remain in their original order, launched separately with `flutter test -d linux`.
  Its `package.json` command and package-script contract are unchanged. A tracked
  caller search found no other executable selector; historical receipts and
  runbooks remain historical evidence, not qualification of this revision.
- Standalone service transport/directory tests, production transports,
  `lib/core/wing_link`, service/packaging, lockfile and user storage are unchanged.
  This slice neither removes the service nor changes Agent contracts.

Decision: delete only the obsolete import/group, reuse the existing source-contract
style and correct the entry comment from sockets/TLS to Agent sockets/SSE. There is
no new transport seam, dependency or fallback. No supporting skill was needed.

## Executed offline evidence

The original manifest admission succeeded before the first edit with
`pass_workspace.py`, pinned manifest SHA-256
`46a4e0e4f162c5761f464d267cc3641f7675170f9f1cc52db782a4b6f71c0ddc`.
The native tool history contains the exact manifest/workspace command and ordering.

The new contract was RED on the original entry (exit 1, forbidden
`core/wing_link/` import), then GREEN after deletion (exit 0). Temporarily restoring
original entry bytes made that same test RED again (exit 1); final bytes were
restored before the final acceptance gate. No service was invoked by this probe.

Checks executed on Linux with Flutter's host test VM:

```bash
dart format --output=none --set-exit-if-changed integration_test/linux_transport_boundary_test.dart test/tooling/enrollment_retirement_contract_test.dart
timeout 5m flutter analyze --no-pub
timeout 5m flutter test --no-pub --concurrency=1 test/tooling/enrollment_retirement_contract_test.dart test/core/hermes/client/platform/hermes_api_transport_io_test.dart test/core/hermes/sse/hermes_sse_event_decoder_test.dart --reporter expanded
git diff --check
```

All passed: formatting unchanged, analysis found no issues (7.3 seconds), and
36 tests passed (test reporter elapsed 1 second). Retained Agent tests exercise
real loopback sockets, oversized-response rejection, typed HTTP status,
endpoint-safe network errors and Unicode JSON. SSE tests retain framing and
event-envelope validation. Existing retirement/service safety assertions passed.
Changed local documentation links were checked for targets and anchors.
The mandatory `finish_task.py` gate reruns these checks and records the exact
owned commit/ref in the native review handoff; this document is not review approval.

Setup failures were not test RED evidence: the isolated workspace initially lacked
cached package metadata, so Flutter refused to run, then reported missing
`package_graph.json`. Reused canonical cached `package_config.json` and
`package_graph.json` after confirming identical pubspec and lockfile; only Wing's
root URI was relative (`../`), resolving into this isolated workspace. No package
resolution, install, lockfile change or service command was needed.

## Qualification and remaining gaps

Implemented: Agent-only integration composition plus anti-restoration coverage.
Qualified: focused Linux host-VM contract, loopback socket and SSE tests only.
Native GTK execution and the entire Linux E2E runner: NOT_CHECKED in this slice.
Live Agent/provider, physical device, service/packaged execution: NOT_CHECKED.
Independent same-card review, canonical integration and remote publication remain
pending the coordinator; the worker produces only a scoped local task-ref commit.

CONNECTION-LINK-REMOVAL and CONNECTION-PATHS remain open. Retained service safety,
service/packaging deletion under CONNECTION-LINK-RETIREMENT, legacy-record
preservation and native qualification remain separate work; nothing here closes
those milestones or authorizes personal service removal.
