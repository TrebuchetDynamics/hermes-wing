# Saved-host Link projection retirement

Task: `t_35372491`; parent work: `CONNECTION-LINK-REMOVAL` / `CONNECTION-PATHS`.
Status: implemented and executor-verified offline; independent same-card review,
canonical integration and publication remain pending. Both Link removal milestones
remain open. This receipt does not qualify a native application or live provider.

## Decision and delivered behavior

Each saved Agent endpoint projects one host row with its existing ID, label,
profile-prefixed URL and individual availability. Legacy Link origin/device metadata
no longer groups endpoints, rewrites displayed URLs or hides Rename / Update
connection. Refresh status reads only the selected endpoint. Explicit removal
removes only the selected saved endpoint after confirmation, not a sibling with
matching legacy metadata. Selecting another saved endpoint cannot borrow the
active endpoint's health or disconnect authority; Chat connects only on explicit
intent with the selected endpoint's own Agent credential.

No storage schema, endpoint model, raw record migration, service, localization,
packaging, upstream Agent or installed user data was changed. Rename retains its
existing metadata preservation. The newly reachable direct edit path now also
passes all five stored legacy fields through unchanged rather than discarding them;
these fields do not authorize any management operation or credential recovery.
Existing active-edit rejection, duplicate URL validation, origin sanitization,
secure storage, cancellation, late-result fencing and no-replay behavior remain.

Decision: delete grouping and its helper functions rather than invent a replacement
host authority. Keep the existing host overview interface for unchanged consumers;
remove only the obsolete management flag. No new dependency, migration or adapter.

## Consumer trace and scoped artifacts

- `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart`: one endpoint
  per `hosts` entry; remove Link grouping, label/authority rewriting and availability
  aggregation; preserve legacy fields in explicit direct connection edits.
- `lib/features/hermes_chat/gateways/gateway_contact.dart`: remove the obsolete flag.
- `lib/features/gateway/widgets/saved_connections_section.dart`: expose existing
  Rename and Update connection controls for every saved endpoint. Existing Refresh
  status is the endpoint test/read action; there is no separate Test control.
- `GatewayScreen._selectedChat` consumes `hosts` without a code change: singleton
  endpoint membership prevents another saved endpoint from inheriting Chat authority.
- Original regression path before edits:
  `test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart:439`.
  Its obsolete grouped-host expectation becomes independent endpoint identity proof.
  Other startup, identity, cancellation, late-completion and retry assertions remain.
- `test/features/gateway/gateway_screen_test.dart`: public rows, exact selection,
  visible edit controls, empty secret field, cancel with no store mutation, explicit
  refresh targeting, own credential on Chat activation, and single-endpoint removal.
- `test/tooling/enrollment_retirement_contract_test.dart`: scoped negative guard
  against retired projection symbols; stored legacy fields and localization are not
  banned.
- Scope correction recorded on the original card: the required union discovered
  `test/features/gateway/gateway_health_ownership_test.dart:514`, another legacy
  grouping consumer omitted from the initial test list. Its obsolete cross-endpoint
  eligibility expectation now asserts no health controls for the other endpoint,
  rejected late failure, explicit return to the original endpoint, retry availability
  and profile-owner invalidation. Retained security checks were not removed.

## Executed acceptance evidence

Original manifest-pinned initial admission ran before the first edit and returned
`worker_start_admitted`, using manifest SHA-256
`3a1127aee40d602b2928fe6f44c600cda46f728fe8944538d38503ca2db2bd64`.
Admitted base: `e1d02e64c782cb846bf9c7b935f95b95d5910f59`.
The original tool history, not a later receipt or replay, proves admission ordering.
The exact committed task ref and SHA are supplied by `finish_task.py` and the native
review handoff; source identity is not inferred from this document's status wording.

Linux Flutter VM deterministic fixtures only:

- `flutter pub get --offline`: passed; `pubspec.yaml` and `pubspec.lock` unchanged.
- Public saved-host regression added first and run before production edits:
  `flutter test --no-pub --concurrency=1 --reporter expanded test/features/gateway/gateway_screen_test.dart --plain-name 'legacy shared metadata keeps direct endpoint controls independent'`:
  failed on the rewritten host label, then passed in the focused suite. An initial
  test-only label mistake was corrected to existing Update connection / Refresh
  status copy; no localization edits.
- Direct-edit preservation regression failed on a dropped legacy origin before the
  edit-path correction and passes afterward.
- `dart format` on changed Dart files: passed.
- `flutter analyze --no-pub`: passed, no issues (6.3 seconds).
- `flutter test --no-pub --concurrency=1 --reporter expanded test/features/hermes_chat/gateways test/features/profiles test/features/gateway test/core/hermes/setup test/tooling/enrollment_retirement_contract_test.dart`:
  passed, 425 tests; measured command duration 54.23 seconds. First union run
  exposed the omitted health grouping assertion (424 passed, one failed); corrected
  focused ownership regression and the complete union then passed.
- `git diff --check`: passed before documentation creation; the commit gate repeats
  it on the complete owned candidate along with analysis, format and focused union.

Acceptance mapping: independent IDs/labels/URLs and controls are covered by the
public GatewayScreen regression and directory host assertions; individual refresh,
remove and Chat ownership by the public controls; credentials and all five legacy
fields by unchanged startup/rename checks plus the direct-edit regression; passive
reads/cancel have zero endpoint-store mutations; late completion/retry/owner loss
remain covered by the required directory/health/security union. Negative source
checks prevent the retired projection from returning without banning retained data.

## Remaining milestone gaps

The broader Link runtime, service, stored credential APIs, packaging and localization
retirement remain outside this slice. Do not count retained field pass-through as
runtime management support. No installed record was accessed, deleted or migrated.
Next milestone work is remaining credential/runtime consumer retirement under its
own bounded scope, then service/delivery closure. Android entry ordering is unchanged.

NOT_CHECKED: compiled browser, Linux GTK, Android/iOS/Windows/macOS, physical secure
storage, device accessibility, live Agent authentication/provider execution, image
build/deployment, broader release gate and remote publication. Independent review
is pending, not an executed pass. Measured usage/cost and review time are unknown.
