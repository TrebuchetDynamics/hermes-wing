# Native Persona conflict recovery

Task: `VERIFY-PERSONA-NATIVE-CONFLICT`; goal: `PERSONA`.

The isolated Linux GTK journey passes for standalone Persona and the actual
Profiles editor modal, at 390 and 1280 logical pixels and 200% text scale.
This qualifies synthetic-transport native recovery, not deployed Agent compatibility.
Independent host-native source review approved commit
`6309a494f14a5a427a1574c68f1ca96458308aad`, tree
`79422d06f86f68cfd2682baa9d33633cb5474d06`. The reviewer independently matched
all 789 archived inputs to that commit and verified native/regression receipts.
Coordinator delivery is separate from source review.

## Executed behavior

The [journey](../../integration_test/linux_persona_conflict_test.dart) reuses the
[existing router/client/channel fixture](../../test/features/soul/persona_route_completion_test.dart).
Only HTTP responses, endpoint storage and preferences are synthetic. Production
router, editor, capability gates, channel and API client remain in the path.
No Agent, provider, network service or personal application is used or modified.

Each of the four journeys proves:

- Tab reaches the field and rendered Edit, Save and Cancel controls; Enter
  activates buttons without invoking callbacks or assigning FocusNodes.
- Ordinary rejected Save retains the same-owner draft and bounded failure text.
- A 412 reads authoritative newer content and presents bounded conflict text
  before deliberate re-edit/Save; no automatic write follows reconciliation.
- The three explicit saves use revisions `r1`, `r1`, `r2` in order. The fourth,
  deferred save belongs to the old origin at `r3`.
- Replacing the connection while that fourth save is pending fences its late
  conflict: replacement draft survives, with no extra read, message or mutation.
  An invalid old Profiles modal is explicitly cancelled and reopened through Edit;
  it is not silently granted replacement-owner authority.

The [runner](../../integration_test/run_linux_persona_conflict.py) reuses the
existing isolated GTK build/process runner. It validates all four receipt rows,
checks native process-group identity, exact frozen input/dependency hashes,
owned-process teardown and isolated-state removal. Mocked preferences produce no
persistent preferences file. Missing/malformed proof is rejected by its self-check
and the [runner regression](../../test/integration/linux_persona_conflict_runner_test.dart).

## Source, tools and commands

Base: `05fca5dd2c7395fed9e3e06446659cf2dab0d438`. Native executed source archive:
SHA-256 `a2db1dbdb970a3cbe6e3e7f1a261ffe2643c77d7c63496b99e22159595fe7b2f`;
789 captured files, no overlays. Journey SHA-256:
`66676b44ab89b548708039c9bb3bc7a22b88abe2388afc644e46f5fe1e59a4ad`.
The private `verify-persona-native/native-639z5fn_` attempt retains the complete
source/dependency manifests, archive, native log and verification receipt.

Linux x86-64, GTK 3.24.41, Xvfb private display (`-nolisten tcp`), Flutter 3.44.2
framework `c9a6c48423`, Dart 3.12.2. Flutter SDK, cached packages and native build
dependencies are copied privately; HOME/XDG are isolated and session D-Bus is not
inherited. The lockfile remains
`f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`.

```bash
flutter pub get --offline --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 \
  test/features/soul/persona_route_completion_test.dart \
  test/features/profiles/profile_persona_fidelity_test.dart \
  test/features/profiles/profile_persona_ownership_test.dart \
  test/features/profiles/profile_persona_client_ownership_test.dart \
  test/core/hermes/client/hermes_profile_soul_fidelity_test.dart \
  test/integration/linux_persona_conflict_runner_test.dart \
  test/integration/linux_shell_compact_return_runner_test.dart --reporter expanded
python3 -B integration_test/run_linux_persona_conflict.py
```

The seven-target regression union passed 121 tests. Native execution passed four
journeys and teardown, exit 0, runner duration 88.877 seconds. Changed Dart
formatting and staged whitespace checks passed. Final changed-input analysis
reported no issues; independent source review is recorded above.

## Retained failures and qualification boundary

The initial native attempt failed all four cases because the harness settled an
indeterminate pending-save spinner before completing its deferred response, allowing
the real client timeout to win. Dispatch now pumps one frame; it settles only after
response completion. A tight widget probe reproduced the timeout and confirmed
that an old modal must be explicitly dismissed before admitting the new owner.
A subsequent native attempt reached conflict recovery but failed explicit retry:
text injection after the field's disabled/re-enabled cycle did not establish a new
editing connection. Tab traversal into the field before injection passed the same
four native cases. Neither failure establishes a production repair; product source
is unchanged. Failed logs and source archives remain retained, not relabelled passed.

Input uses framework key events and `WidgetTester.enterText`; viewport sizing uses
`IntegrationTestWidgetsFlutterBinding.setSurfaceSize`. This is not physical keyboard,
OS window resizing, IME, screen-reader or acoustic qualification. Rejected-draft
preservation across 412 is not implemented: authoritative newer text replaces it.
Live Agent revision/concurrency enforcement, Android, physical devices, real secure
storage, full-repository/release gates and distribution are NOT_CHECKED. PERSONA
and the complete daily-use port remain open beyond this bounded native outcome.
