# Managed-key SSH native qualification ledger

Task: **BACKEND-SSH-KEY-NATIVE**. Inspected baseline:
`2623fb0a51e30b6c8c47d30797ec199827cbe478`.

**Native Linux: NOT_CHECKED. Native Android: NOT_CHECKED.** This ledger records
fresh offline preparation checks, not full-app acceptance or completion of the
REMOTE-BACKENDS goal. No native app, owner-approved host or live Agent was
accessed. No provider inference, host authorization or personal-runtime mutation
was performed. No product or harness behavior changed.

Start with the [SSH private-key procedure](../test-plan.md#ssh-private-key-qualification)
and [generated-key implementation receipt](connection-key-generation-help.md).
The [Android serve receipt](android-ssh-serve-offline.md) covers a distinct
transport selection; advertised-API key reads do not qualify serve chat.

## Executed offline evidence

On the Linux worker, using the existing shared QA Python environment:

```sh
PYTHONDONTWRITEBYTECODE=1 \
  "$AUTOWORK_CACHE/managed-ssh-python-3.12.14/bin/python" \
  -m unittest test/tooling/managed_ssh_key_native_test.py -v
PYTHONDONTWRITEBYTECODE=1 bash scripts/run_managed_ssh_key_native.sh --lane linux
PYTHONDONTWRITEBYTECODE=1 bash scripts/run_managed_ssh_key_native.sh \
  --lane android --mapping adb-reverse --device APPROVED_DISPOSABLE_SERIAL
```

- **7 preparation tests pass**. These exercise fixture bearer authorization,
  read-only routes, wrong client key and changed host fingerprint rejection,
  prohibited shell/forward rejection, interruption/cleanup, explicit platform
  mapping, source freezing, bounded receipt validation and process-group reaping.
  These are Python fixture/preparation checks, not Wing app authentication.
- **Both dry-run commands exit 0** and report `native_workflow: NOT_CHECKED`,
  `native_picker: NOT_CHECKED` and substituted storage. The Android serial above
  is a placeholder, not a discovered or exercised device. No ADB command ran.
- No retained native receipt was available in this worktree. Historical Flutter
  results in the linked receipts were not rerun or promoted to current native
  evidence. Product, test and dependency inputs are unchanged, so the task's
  changed-input Flutter union and analyzer were not rerun for this docs-only pass.

Source binding for these preparation results (SHA-256, not native artifacts):

| Input | SHA-256 |
| --- | --- |
| `scripts/run_managed_ssh_key_native.sh` | `ea074411377d3821578adf9d893a9430a498cc5796e7b97a871803293fdc2f6d` |
| `scripts/support/managed_ssh_key_native.py` | `b60b58eb0ccb41b3fac98a97c1f7005a4c454852efc1b4b9b9e46b4782507ef7` |
| `integration_test/managed_ssh_key_native_test.dart` | `cc9111d22d4bbb9b07c5d5b79ea5b390c4132f196bf2498c382b5f75d662e7bd` |
| `integration_test/support/managed_ssh_key_native_fixture.dart` | `bcf8753d837fb454b4f12200b93b44d9758e81deaf7d46c17fce7cff8e5d174f` |
| `test/tooling/managed_ssh_key_native_test.py` | `3051477141fa8b2d617df2e9f2183a603ef3130ecebfc05fe3c8778212a39d37` |

## Existing harness boundaries

Reuse [the launcher](../../scripts/run_managed_ssh_key_native.sh), not a new
terminal-login harness. Source inspection establishes only the following scope:

- `scripts/support/managed_ssh_key_native.py:149` creates disposable SSH and
  synthetic read-only Agent listeners. It does **not** take approved-host
  credentials or qualify reachability to an external Agent.
- `integration_test/managed_ssh_key_native_test.dart:32` substitutes preferences,
  endpoint/recovery storage and document acquisition. The production form,
  controller, native forward and Agent HTTP client remain in the journey.
- `integration_test/managed_ssh_key_native_test.dart:200` performs two
  **same-process** connection cycles. It checks profile/history and model
  inventory reads, interruption, explicit Retry and disconnect without mutations;
  it does not select a model through a mutation or perform a process restart.
- `scripts/support/managed_ssh_key_native.py:386` requires the native receipt to
  keep chooser, physical secure storage and encrypted-key results `NOT_CHECKED`.
  A future fixture `PASS` cannot override those exclusions. Changed host-key
  rejection in the Python probe is not a changed-key full-app result.
- `scripts/support/managed_ssh_key_native.py:473` currently copies source and the
  SDK into scratch and applies disposable build overlays. That preparation is
  not compatible with this worker's worktree-only scratch-copy and shared-SDK
  rules; `--run` was not invoked. Reconcile the execution path before a later
  native fixture run, rather than silently bypassing the isolation rules.

## Independent native acceptance cells

Every cell below is **NOT_CHECKED**, independently on each named platform.
Preparation tests, terminal SSH login, Android target overrides and a Linux
fixture run cannot fill Android cells or approved-host cells.

| Required observation | Native Linux | Native Android |
| --- | --- | --- |
| Production managed form in isolated app state; device-to-approved-host reachability | NOT_CHECKED | NOT_CHECKED |
| Out-of-band reviewed host fingerprint and deliberate trust acceptance | NOT_CHECKED | NOT_CHECKED |
| Managed private-key SSH authentication | NOT_CHECKED | NOT_CHECKED |
| Separate Agent authentication, including denied Agent credential | NOT_CHECKED | NOT_CHECKED |
| Exact profile, model inventory/selection and canonical history loading | NOT_CHECKED | NOT_CHECKED |
| Disconnect; explicit reconnect to exact owner without mutation replay | NOT_CHECKED | NOT_CHECKED |
| Denied/replaced client key; changed host-key rejection | NOT_CHECKED | NOT_CHECKED |
| Cancel key selection, host trust and pending bootstrap; reject late results | NOT_CHECKED | NOT_CHECKED |
| Generate key with real secure-storage denial; no usable unpersisted fallback | NOT_CHECKED | NOT_CHECKED |
| Copy through native clipboard: public key only | NOT_CHECKED | NOT_CHECKED |
| Deliberate **Use saved Wing key**, same identity without regeneration | NOT_CHECKED | NOT_CHECKED |
| Real process exit/relaunch with isolated state retained; unchanged key identity | NOT_CHECKED | NOT_CHECKED |
| Real OS chooser: cancellation, revoked/unreadable input, bounded/encrypted-key cases | NOT_CHECKED | NOT_CHECKED |

## Pending live handoff

No approved host/authentication or explicit disposable Android target was supplied
with this invocation. These are **pending live inputs**, not offline failures:

1. Identify the approved target, independently reviewed host fingerprint, permitted
   authentication method and separate Agent credential through the approved secret
   channel. Use existing permitted read-only profile/model/history data. Do not
   discover/import personal credentials, edit `authorized_keys`, restart Agent or
   authorize provider spending to make a test pass. Any controlled key/trust
   changes need an explicitly disposable target and scoped permission.
2. Select isolated Linux application state and an explicitly approved disposable
   Android app/device. Record platform/build and route. An owned ADB-reverse
   fixture route proves that route only, not direct device-to-host reachability.
3. Run the reusable disposable harness within the execution environment's isolation
   rules; retain source/artifact bindings and its sanitized receipt separately
   from the approved-host production-form journey. Never describe a fixture
   listener as the approved live Agent.
4. Exercise the production generated-key controls through actual native secure
   storage and clipboard. For restart, retain only the owned app state, exit the
   actual process, relaunch and deliberately select the saved key. Compare public
   identity before/after without retaining private material. A second store object,
   reconnect or fresh fixture identity does not prove restart persistence.
5. Record each platform cell separately, including refusal/cancellation outcomes
   and zero mutation replay. Keep chooser/storage, read-only model inventory,
   actual model selection and any separately authorized generation results distinct.
   Retain existing generation limits; this task adds no inference permission.

Evidence must exclude private keys, tokens, passphrases, private endpoints, host
paths and transcripts. Keep only redacted identities, bounded counters and
source/artifact bindings. Do not reset paired apps, touch personal keyrings or
weaken host trust to obtain a pass.

Update this ledger after a named native execution, or whenever the five pinned
harness/test inputs or generated-key storage/clipboard path change. The offline
record is ready for coordinator review; **full-app qualification remains open**.
