# Profiles directory browser retirement

Card: `t_661d91a6`. Parent: CONNECTION-LINK-REMOVAL under CONNECTION-PATHS.
Admitted base: `7dea74897427ead86eae39f18dd111b91b01401d`.
Status: locally implemented and checked; independent native review and coordinator
integration/publication remain pending. This is not whole-Link removal or new
Agent directory/Project support.

## Decision and scope

Delete the dormant `profile_directory_browser_sheet.dart` and its exclusive
widget test rather than adding an adapter. Before deletion, the production trace
of `showProfileDirectoryBrowser`, `DirectoryRootsLoader`,
`ChildDirectoriesLoader` and the widget import found only the widget in `lib`.
The test-only callers were the live feature journey, Maestro entrypoint and
Linux regression suite registration. The coordinator authorized closure of these
three callers and the two Maestro YAML consumers on the original card, retaining
original admission pins and the nine-file ceiling.

The retained live directory journey now asserts against `WingLinkClient` directly:
approved roots, a one-entry bounded child listing, regular-file exclusion, and
HTTP 410 for both revoked root and child handles. The existing synthetic-root
validation, fixed grant/revoke commands and teardown remain. HTTP 410 follows
`wing_link/internal/app/workspaces.go` and its revocation test; expired or foreign
handles are a distinct HTTP 404 contract. This journey was analyzed, NOT RUN.

Maestro no longer exposes the directory launcher, pagination counter or revoke
control. Only directory-browser sections were removed from
`local_setup_accessibility.yaml` and `soul_directories.yaml`; filenames, Local
setup large-text steps and Persona save/conflict checks remain. Their retired
keyboard, landscape, pagination and revocation journeys are no longer coverage
and are not evidence for replacement functionality.

The negative source guard in
`test/tooling/enrollment_retirement_contract_test.dart` scans all production Dart
and the three affected integration targets for retired entry/import/loader names,
and rejects obsolete directory fixture steps in both YAML flows. Retained Dart
client bounds/path-rejection tests and Go service containment/auth/revocation tests
are unchanged. No dependencies, localization, stores, grants, credentials,
Agent APIs, upstream source or service implementation changed.

## Admission and executed acceptance

The unchanged mandatory guard ran before any edit in this continuation and
returned exit 0 / `worker_start_admitted`; the workspace was clean and HEAD was
the admitted base. Exact invocation:

```text
python3 /home/xel/git/gormes/hermes-toolset/skills/autowork/scripts/pass_workspace.py --manifest /home/xel/.hermes/profiles/wing/autowork/pass-41526703b7ee8a90-ea6005ec0394400c99cc07a4ef9a86d1.json --manifest-sha256 096aed8516da32c6fd2088f28d91a3629ce1e1aa899fdf1822ea4d1275c95c21 --workspace /home/xel/.hermes/profiles/wing/cache/scratch/autowork-passes/41526703b7ee8a90-ea6005ec0394400c99cc07a4ef9a86d1
```

Tool history, not this receipt alone, establishes ordering. Native review must
bind the finish helper's exact task ref/SHA to that admitted base and cumulative
owned diff; do not rerun the initial clean-workspace guard after editing.

Executed on Linux with deterministic Flutter tests:

- `flutter pub get --offline`: PASS; `git diff --exit-code -- pubspec.yaml pubspec.lock`: PASS.
- RED: `flutter test --no-pub test/tooling/enrollment_retirement_contract_test.dart --plain-name 'product and fixtures cannot restore the retired directory browser'`: exit 1, expected failure on `showProfileDirectoryBrowser` in the retained widget.
- GREEN: `flutter test --no-pub test/tooling/enrollment_retirement_contract_test.dart`: PASS, six tests.
- `dart format --output=none --set-exit-if-changed test/tooling/enrollment_retirement_contract_test.dart integration_test/linux_live_feature_journeys_test.dart integration_test/hermes_features_maestro_main.dart integration_test/linux_feature_regression_test.dart`: PASS, no changes.
- `timeout 10m flutter analyze --no-pub`: PASS, no issues; includes retained integration targets (7.4 seconds for the initial check).
- `timeout 10m flutter test --no-pub --concurrency=1 test/features/profiles test/features/soul test/features/gateway test/shared/widgets/app_shell_profile_footer_test.dart test/tooling/enrollment_retirement_contract_test.dart test/core/wing_link/wing_link_client_test.dart test/tooling/linux_live_directory_isolation_test.dart`: PASS, 320 tests (68 seconds on the initial run). Covers active ownership fencing, credentials, denial/revision recovery, keyboard/large text and no replay, plus retained directory-client bounds and synthetic-root isolation.
- `git diff --check`: PASS after removing two trailing blank lines identified by the initial check.
- YAML structure and referenced local flow existence: PASS using already-resolved Dart `yaml` 3.1.3, via `dart --packages=.dart_tool/package_config.json .dart_tool/directory_retirement_yaml_check.dart`. Python/Node YAML modules were unavailable; no package installed. The scratch probe initially rejected the existing scalar `hideKeyboard` command, then accepted Maestro scalar commands and passed both flows. This is parsing, not Maestro/device execution.

The scratch YAML probe loads both files with `loadYamlDocuments`, requires two
documents (header map and command list), accepts scalar commands or single-key
command maps, and checks each `runFlow.file` relative to the flow directory.
The native finish gate repeats relevant checks with every owned path explicit;
its receipt and exact commit are recorded in the card handoff. No review approval
is implied by executed checks.

## Qualification and remaining work

Implemented: dormant product widget and traced fixture consumers retired, with a
negative regression. Qualified: bounded Linux deterministic tests and static
analysis only. Delivered: NOT_CHECKED; no canonical integration or remote push.
Native GTK, browser, Android, live-auth/service/provider, Maestro execution and
replacement directory browsing are NOT_CHECKED. No live journey was run and no
personal service or saved records were contacted or changed.

CONNECTION-LINK-REMOVAL stays in_progress. Saved management credential/contact
APIs and service/packaging dependencies remain; CONNECTION-LINK-RETIREMENT stays
blocked until remaining callers are removed. The next slice should trace saved
management credential/contact APIs without deleting raw user records. No next
card or milestone closure is created by this worker.

Related hard boundary: [complete removal including legacy](../adr/product.md#complete-removal-including-legacy).
