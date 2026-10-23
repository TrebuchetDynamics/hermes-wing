# Linux connection and plugin qualification

Scope: `LINUXQA-001-8163f50f`, the connections lane of the
[Linux campaign](../plans/2026-10-21-linux-feature-qualification.md).
This is isolated fixture qualification, **not full Linux support or official
Desktop parity**. No real Agent/SSH host, provider, personal credential store,
installer or service lifecycle is admitted.

## Execution and evidence

Use the prerequisites and private output rules in the
[driver runbook](linux-qualification-driver.md). With Flutter 3.44.2 / Dart
3.12.2, Node 22, resolved packages and a reviewed native dependency prefix:

```sh
python3 scripts/run_linux_feature_qualification.py \
  --lane connections --output-dir "$TMPDIR/linux-qualification"
```

The registered target is
[`linux_connection_feature_qualification_test.dart`](../../integration_test/linux_connection_feature_qualification_test.dart).
Its [fixture](../../integration_test/support/linux_connection_feature_fixture.dart)
keeps the production connection screen, API channel, endpoint editor, directory,
SSH controller and host-review dialog. Transport, directory metadata, document
acquisition and storage fault seams are synthetic. Controls are composed as Add
Hermes; this target alone does not establish router/alias coverage.

Five terminal cases are published together by atomic rename of
`WING_LINUX_TEST_ROOT/feature-cases.json`. Publication requires five unique IDs;
a failed earlier case cannot leave a partial passing inventory. Rows carry
schema-1 feature/route IDs, GTK PID, owner/operation counts and explicit
backend/input/storage classifications. The app remains alive for driver PID
observation. The driver adds source/tool/dependency fingerprints, exact command
exit, log/artifact digests and owned-process/state cleanup.
Keep receipts, logs and screenshots private; do not commit generated evidence.

### Public-control recovery inventory

| Case ID | Features | Controls and discriminating assertion |
| --- | --- | --- |
| `connections.local-picker-recovery` | HD-LOCAL, HD-ENTRY | `platform-local-choose-home`, Local/Remote choices: cancellation preserves discovery, denied metadata never means ready, and a disposed picker cannot inspect/select its late folder in the replacement entry. Zero connects/saves/Agent reads; no installer or scanner. |
| `connections.bootstrap-owner-replacement` | HD-REMOTE, HD-HOSTS | URL/Connect: hold production bootstrap, deliberately replace the channel owner, then release the old callback. Replacement state remains identical, with no save/disconnect/mutation/reconnect. One old-origin read may finish; it cannot retarget the replacement. |
| `connections.saved-origin-credential-custody` | HD-REMOTE, HD-HOSTS | Saved row Edit, URL/key/Test/Cancel: a changed-origin blank-key probe sends no stored credential; an explicit replacement belongs only to that draft. A 403 remains sanitized; Cancel preserves the original row without connecting or saving. |
| `connections.ssh-retired-trust-review` | HD-SSH | SSH fields, Connect, Cancel/Trust: cancellation leaves no pin; replacing the controller during review makes old acceptance inert. Neither replacement SSH acquisition nor Agent connection occurs. Trust storage/forwarding are substituted, not keyring/SSH evidence. |
| `connections.absent-native-contracts-no-replay` | HD-ENTRY, HD-REMOTE, HD-LOCAL, HD-SSH | Connect, deliberate retry and save-error feedback: denial does not retry while idle, explicit retry runs once, and persistence denial remains visible without replay. Missing session/provider writes and native-chat controls stay unavailable. `unsupported` is a passing negative assertion, not positive chat/install/lifecycle support. |

Input is framework text/pointer injection on GTK/Xvfb, not physical input. The
three-second idle observations are bounded checks, not a reconnect soak.
Synthetic `.invalid` origins never open sockets. The case document contains no
credential, transcript, selected path or key bytes.

## Separate runner inventory

The connections registry dispatches **only** the new target. Other runners retain
separate receipts; they are not silently merged into its campaign. Historical or
preparation-only receipts never qualify a new source tree. Every new runtime
claim below requires its own matching source fingerprints, exits and teardown.

| Surface / recovery cells | Runner | Evidence boundary |
| --- | --- | --- |
| Welcome, Local/SSH/Remote/VPN, back/cancel, denied reads and deliberate retry | `bash scripts/run_linux_direct_first_run.sh` | Existing synthetic read/store journey; not newly rerun by this lane or real authentication/installation proof. |
| Metadata-only Local setup/enrollment and legacy recovery | `bash scripts/run_linux_local_setup_enrollment.sh` | Existing chooser/metadata substitutions; not actual folder acquisition or Agent preparation. Not newly rerun here. |
| Remote auth help, rejection, persistence retry and late-save ownership | `bash scripts/run_linux_remote_auth_explanation.sh`, `bash scripts/run_linux_remote_connection_retry.sh` | Existing production-channel journeys with synthetic faults; not newly rerun here. |
| Saved edit/Test/Cancel, stale results, feedback and exact two-host ownership | `bash scripts/run_linux_saved_endpoint_edit.sh`, `bash scripts/run_linux_saved_endpoint_feedback.sh`, `bash scripts/run_linux_two_host_recovery.sh` | Existing synthetic inventories; not newly rerun or promoted to real credential custody. |
| Actual clipboard, GTK picker and transcript save/readback/cancel/changed-owner | `bash scripts/run_linux_native_input_e2e.sh` | Two GTK processes: four input/lifecycle cases and six transcript-export cases. OS-injected X11 input with a private Xvfb/window manager; not physical keyboard, Wayland or SSH-key chooser qualification. |
| Preferences across restart | `bash scripts/run_linux_persistence_e2e.sh` | Two actual app processes over private HOME/XDG: groups, theme-gallery selection and voice preferences. Not microphone/acoustic support. |
| Secure storage across restart | `bash scripts/run_linux_secure_storage_regression.sh` | Two actual plugin processes on private D-Bus/keyring/XDG, preserving inert legacy slots. No personal keyring is contacted. |
| Saved credential edit, peer preservation, denied save/retry and restart | `bash scripts/run_linux_saved_endpoint_storage.sh` | Four width/text-scale cells in each of two processes, actual plugins, private bus/keyring with no activation directories, and acknowledged CreateItem deny/allow. Evidence and snapshots now stay under TMPDIR. |
| SSH parsing, fingerprint review, wrong key, late picker/bootstrap cancellation, interruption and explicit exact-session restore | `bash scripts/run_managed_ssh_key_native.sh --lane linux --run` | Actual disposable SSH/HTTP listeners and production forwarding/channel. Document acquisition, preferences, endpoint/recovery and host-pin storage are substituted. Requires asyncssh via `WING_SSH_KEY_PYTHON`; without `--run`, preparation only. |

Use clean resolved package metadata and the reviewed prefix for each runner.
Native chooser runs also need installed read-only MIME/icon data (on this host,
`XDG_DATA_DIRS=/usr/share`), alongside private HOME/config/cache/runtime. This is
public OS resource lookup, not personal state. GTK settings use an in-memory
backend and installed read-only schemas. Do not replace these resources with
an empty data lookup and call a crashed picker tested. Synthetic campaigns do
not acquire native files and keep their data lookup private.

Legacy snapshot helpers retain pinned historical **harness** objects, not old app
source. Missing helpers/dependencies are prerequisites to resolve, not permission
to inherit personal state or run an old app. Heavy runners use separate snapshots
or serialize writes to the same build tree. Keep listeners in the task's allotted
port range and retain exact native PID/process-group teardown evidence.
Never use live/installer/retired-security launchers to fill fixture cells.

## Observed results and repairs

Linux GTK/Xvfb execution produced a passing registered campaign: four `pass`
rows, one passing `unsupported` negative row, child exit 0, observed GTK ownership
and complete owned-group/state cleanup. Separate current-source receipts also
record actual clipboard/file-dialog/export, preferences restart, private-keyring
restart, real saved-storage denial/retry/restart and deliberate managed-SSH
execution. These do not aggregate to full Linux or Desktop qualification.

Prerequisite/recovery repairs needed to execute the current sources are bounded.
Their source owners are the [input validator](../../scripts/support/linux_qualification_support.py),
[Chat screen](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart),
[entry gate](../../lib/router/widgets/connection_entry_gate.dart) and the
[SSH fixture runner](../../scripts/support/managed_ssh_key_native.py).

- Package inspection accepts Pub's absent default `lib/` for attributed native-only
  plugins and the SDK-owned `sky_engine` version default. Missing arbitrary Dart
  import roots, links, escaping paths and graph/lock/version mismatches still fail.
  No package source, SDK, lockfile or driver lane registry was changed.
- Add Hermes excludes active-Chat header actions, avoiding the observed compact
  200%-text overflow without suppressing layout assertions.
- First-run gating retains an admitted channel's recovery presentation through
  error/connecting. Disconnect invalidation is synchronous, even without a rendered
  disconnected frame; channel replacement retires admission. Current interrupted
  SSH ownership can expose its existing explicit Retry. The gate never connects,
  saves, grants operations or replays mutations.
- The Chat shortcut boundary stays mounted **while editing a connection**, through
  bootstrap and exact-session restoration, so inserting shortcuts cannot
  dispose/cancel an unadopted SSH form. Ordinary Chat reconnects retain their
  existing shortcut/focus transition; this is not a blanket change to modal focus.
- Persistence uses current theme-gallery/Voice controls. SSH cancellation uniquely
  targets Cancel, not access help; the first reviewed pin remains in the substituted
  trust store instead of asking for repeated review of an unchanged fingerprint.
- Saved-storage/SSH evidence allocation uses private TMPDIR outputs; refused SSH
  output allocation occurs before native scratch creation.

SSH qualifies the actual advertised **default profile** and exact `qa-history`
fixture session, including changed forwarding origin and deliberate recovery.
It does not invent profile inventory or invoke hidden selection callbacks.
Its validated result explicitly says `ADVERTISED_DEFAULT_NOT_SWITCHER`.
Ephemeral profile-picker qualification remains a coverage limitation, separate
from exact default-profile/session restoration. Read-only model inventory is not
model assignment or inference.

## Recovery from the rejected candidates

Earlier attempts are not integrated acceptance. The
[recovery record](../tasks/review-findings-recovery.md#linux-connections) owns their
rejection history. This retry starts from `65964148` and consumes the already-landed
MAIN-REPAIR-003 storage/owned-port fixture repairs and current native-only/SDK package
validation. It does not restore the older shared assembly, modify SDK/package
metadata or change the fixed driver registration.

The earlier candidate's always-mounted shortcut/focus wrapper reproduced the
Linux connection-reset failure in
[`hermes_chat_approval_dismissal_test.dart`](../../test/features/hermes_chat/screens/hermes_chat_approval_dismissal_test.dart).
The correction narrows wrapper retention to connection editing. The existing test
is unchanged: actual Tab/Enter must reach and admit replacement approval B while
malformed sheet A is retained; dismissing stale A must not release B's in-flight
state or send another response. Channel-rebind/profile-switch cases also retain
keyboard/modal and operation-count assertions. The combined approval, entry-gate
and saved-editor modules pass 29 cases; the three repaired serve/recovery modules
pass 44. These focused checks do not substitute for the coordinator's normal
merged-tree full-suite gate, which remains a separate requirement.

Fresh retry evidence includes the registered five-case lane and all five distinct
native runner checks above, not a standalone GTK substitute or SSH preparation.
Private per-command receipts bind source, SDK and the actual admitted dependency
prefix hashes, exact exits and cleanup; saved-storage and SSH retain their own
nested receipts. Direct input/preferences/keyring checks have outer-session GTK
PID observations; saved-storage/SSH use their nested runners' process/teardown
evidence, not independent outer native-PID observations. A passing fixture verdict
never closes the live gates below or marks PARITY met. The task remains subject to independent/coordinator acceptance.

## Remaining gates

Read-only REST connection, native read-only connection and separately authenticated,
deliberate native-chat enablement are distinct outcomes. None permits an API token
as a native session token, automatic mutation replay, Agent installation or a
management fallback. No upstream Agent code or feature matrix is changed.

Keep the original gates open: `PARITY-NATIVE-LINUX-LIVE`,
`BACKEND-SSH-KEY-NATIVE-LIVE`, `DOC-NATIVE-FAILURE-BOUNDARY-LIVE`,
`DOC-NATIVE-DESIGN-REVIEW-LIVE`, `PARITYGAP-002-76-LIVE`,
`VERIFY-SHELL-NATIVE-INPUT` and `VERIFY-DESKTOP-NATIVE-DELIVERY`.
Actual SSH-key chooser acquisition, encrypted keys, real-host authentication and
latency, Wayland/IME/screen readers, physical input/audio, intended-device UX,
packaged upgrade and retained personal-keyring custody remain **NOT_CHECKED**.
Fixture execution does not close any of those gates.

Re-run the affected evidence owners after changes to connection/channel ownership,
entry gating, picker/plugin custody, fixture contracts or SDK/dependency inputs.
Do not carry a receipt across source/input drift.
