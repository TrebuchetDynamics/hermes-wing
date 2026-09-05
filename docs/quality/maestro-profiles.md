# Maestro profile journeys

Run the isolated profile suite on a dedicated Android device:

```bash
WING_QA_DEVICE=<adb-serial> npm run android:maestro-profiles
```

The runner syntax-checks three scenarios, builds the production router/screens
with a deterministic channel, and installs only
`com.trebuchetdynamics.hermes.wing.qa`. Each scenario clears that package;
restart steps retain its fixture data. It never creates or deletes real Hermes
profiles. `WING_QA_OUTPUT_DIR` selects the artifact directory and the runner
isolates Maestro's log cache from other jobs.

| Scenario | Assertions |
| --- | --- |
| `switch_chat.yaml` | Open profiles through More; talk to default, another profile, then default again. Assistant receipts bind every reply to the expected stable profile/session and request text. The original conversation remains visible, other-profile replies stay absent, and default has no deletion action. |
| `create_setup_delete.yaml` | Required name, canceled creation, clone persona inheritance, display-name/persona changes, restart/read-back, chat under the original stable ID, wrong-name deletion disabled, canceled deletion, confirmed deletion, restart without resurrection, unchanged clone source, and continued default-profile chat. |
| `provider_model_chat.yaml` | Reuses `configured_create.yaml`: production setup editor with fresh-profile provider/model validation; description/provider/model passed through its typed callback; model read-back before/after restart, and chat with the configured fixture profile. Description persistence is checked by the fixture unit test; the profile card does not display it. |

Run only provider/model setup and chat:

```bash
WING_QA_DEVICE=<adb-serial> npm run android:maestro-provider-chat
```

`provider_model_chat.yaml` verifies an assistant-only receipt containing the
configured profile, provider, model, and input for the initial reply after
restart, a follow-up, and another turn after switching away and back. The default
profile must not display the configured profile's receipts. The provider receipt
is derived from synthetic setup metadata read from fixture preferences and the
selected profile's model; it does not verify a real provider request.

`configured_create.yaml`, `start.yaml`, `open.yaml`, and `chat.yaml` are helpers. The older
`strict_profile_lifecycle_fixture.yaml` still provides the nine-profile inventory
sweep; it and its two helpers now explicitly target the isolated package. It is
not included in the focused three-scenario runner.

## Lessons from Hermes Desktop

The local read-only Desktop checkout supplied these user outcomes:

- [Profile switch and active chat](../../hermes-desktop/lat.md/sidebar-navigation.md):
  align the selected profile and visible conversation while preserving other
  profiles' conversations. Wing checks this through its Profiles → Chat route.
- [ProfileModal](../../hermes-desktop/src/renderer/src/components/profile/ProfileModal.tsx):
  edits and deletion use stable identity; canceled edits/deletion must preserve
  the resource. Wing retains its own explicit save and typed confirmation UI.
- [Profile creation/deletion](../../hermes-desktop/src/main/profiles.ts):
  clone configuration from an explicit source and protect default from deletion.
  Agent's [profile tests](../../hermes-agent/tests/hermes_cli/test_profiles.py)
  corroborate named-source configuration/persona cloning. Wing does not copy
  Desktop's direct filesystem/CLI implementation.

Desktop's `lat` CLI was unavailable; the checked-in documentation and live source
were inspected directly. Neither upstream checkout was modified.

## Evidence boundaries

The channel stores only synthetic profile metadata/personas in isolated app
preferences so a process restart can exercise read-back and deletion. Synthetic
conversation histories remain in memory and are scoped per profile. This is
fixture state, not a production copy of Agent-owned state.

The configured-profile button belongs to the harness. It opens the production
`ProfileEditorSheet` with `canConfigure` and a deterministic typed callback. It
does not establish that the current Agent advertises provider configuration or
that Wing Link setup/readiness, credentials, local approvals, rollback, or
provider authentication succeeded. No provider credential is entered or stored.
The callback requires the exact expected setup payload before creating its
fixture profile. Unsupported Project creation remains outside this suite.

The fresh-profile fixture reports an immediate synthetic assistant receipt.
Real provider replies, HTTP/SSE transport, reconnect history, multiplexed
credentials, and speech require their separate runtime acceptance checks. The
[real-service attempt](real-profile-cycle-2026-09-05.md) remains incomplete.

## Validation

Focused Flutter checks:

```bash
flutter test test/integration/profile_lifecycle_fixture_test.dart \
  test/features/profiles --concurrency=1 --reporter compact
flutter analyze --no-pub
bash -n scripts/run_android_maestro_profiles.sh
git diff --check
```

On 2026-09-05, the original three scenarios (`switch_chat`,
`create_setup_delete`, and `configured_create`) passed on a physical Samsung SM-S928B running
Android 16 using the isolated APK, across focused runs. Switching and the full
clone/edit/delete journey passed together; configured creation passed on its
final focused run after narrowing field selectors and aligning read-back with
the fields the profile card actually displays. This was not one aggregate
three-flow passing invocation. The legacy nine-profile sweep was syntax-checked,
not rerun.

The final profile/fixture command passed 59 tests. The existing feature-fixture
suite (`flutter test test/integration/maestro_feature_fixture_test.dart
--reporter expanded`) passed five more. Analysis, changed-Dart formatting, all
nine new/modified YAML syntax checks, runner shell syntax, documentation links,
and `git diff --check` passed. Only Android was exercised; no live services,
provider credentials, or upstream files were modified.

The dedicated `android:maestro-provider-chat` command passed on the same physical
Android device on 2026-09-05, including its syntax check, isolated build/install,
and complete `provider_model_chat.yaml` run. The extended profile/fixture suite
passed 59 tests, analysis found no issues, and formatting, shell syntax, and diff
checks passed. This qualifies deterministic setup-to-chat UI behavior only;
no real provider authentication or network completion was exercised.
