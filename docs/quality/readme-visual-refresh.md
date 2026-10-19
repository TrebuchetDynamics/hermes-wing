# README visual refresh receipt

Scope: `README-001-62`, the accepted [README refresh](../plans/2026-10-12-wing-landing-onboarding.md#readme-visual-refresh).
This is documentation/browser-preview evidence, not app, native-device or live Agent qualification.

## Story and scope

Existing/prospective Hermes users should understand Wing, inspect honest product
proof and choose Preview, Connect or Build before their first deliberate reply.
The composition is compact approved identity → value/action/alpha notice → labeled
proof → capabilities/Agent ownership → entry paths → first chat → limits/build/help.

The [README](../../README.md) keeps native Markdown, the approved 80px PNG logo,
the exact headline **Your agent. Within reach.**, and existing responsive showcase
images. A searchable proof heading, conditional-approval explanation and fuller
alt text carry meaning without images. A full-illustration link lets narrow-screen
readers inspect the desktop context; path links lead to the three starting choices.
Prerequisites and success signals are emphasized without creating another manual.

No derivative, generated art, recapture, producer, application, site or test change
was needed. The existing 160–180-line guard remains; the README is 180 lines.
No warnings were removed to meet it. Shared branding, icons and showcase bytes are
unchanged, so their existing producer and capture/security assertions remain intact.

## Source and invariant checks

Baseline: `9f70e019030bdaa59c35877ef2838f6dc8429c91`.
Candidate README SHA-256:
`065eebeccfff753539a472c3bfc6e103f8364039fbb4861cc631ab5769c84a9f`.

- All 35 incoming heading/explicit-ID fragments remain; no compatibility alias
  is lost. All original fenced shell commands are byte-identical, including the
  loopback hostname/port flags. The setup commands were preserved, not executed
  as a client-install or first-reply qualification exercise.
- SHA-256 comparison preserves 66 inventoried files across branding, README
  imagery, site and platform icon directories. No shared consumer changed.
- Authority, direct connection, provider costs/data processing, separate Agent
  credentials, HTTPS/CORS/fingerprint trust, VPN/loopback warnings, browser
  SSH/OAuth limits, manual Termux, secure-storage variation, token revocation,
  redacted/private reporting and the no-independent-audit notice remain visible.
- Alpha, source-build/signed-distribution/update limits and named-platform
  voice/notifications/recovery gaps remain. Simulation/non-synchronization labels
  remain adjacent to proof. The no-tools prompt still precedes optional granted
  demo-Project access; retry is deliberate and reconnect must not replay mutations.
- UI names/order match `lib/l10n/app_en.arb:104–146`,
  `lib/l10n/app_en.arb:2183` and
  `lib/features/enrollment/widgets/hermes_welcome.dart:88–178`.
  [Getting started](../getting-started.md#direct-agent-connection), its
  [platform matrix](../getting-started.md#platform-evidence-and-limits),
  [routes](../product/routes.md), [security policy](../../SECURITY.md) and
  [threat model](../security/threat-model.md) retain the detailed behavior/status.
  No Agent API or Desktop parity claim was added.

## Composed previews

Used the already installed **marked 18.0.11**, minimal GitHub-like CSS and
**Chromium 152.0.7977.75** on Linux, with system fonts and reduced motion.
No renderer/dependency was installed. The server bound only loopback on the task's
allocated port; browser requests outside that local origin were blocked.

| Viewport | Article content | Surroundings | Result |
| --- | --- | --- | --- |
| 900px | 836px | Light and dark | Images load; no page overflow |
| 360px | 328px | Light and dark | Mobile picture source loads; no page overflow |

Both baseline and candidate were composed from their actual Markdown. Candidate
opening, proof/caption, first-chat, build and final help/license sections were
inspected in the wide/narrow light/dark renders. The logo stays legible on both
surfaces. The wide board is an overview, not a readable manual for every tiny
phone control; the mobile source enlarges the decision. Essential meaning stays
in Markdown. Captions and prompt remain readable. Long unchanged commands scroll
inside their code block at 360px rather than widening the page.

Assertions check decoded images/current picture sources, document width, code-block
containment, local link files/fragments, focused keyboard activation of path links,
and retained purpose/proof/commands/disclosures with images hidden. Image-off
renders still offer the first-chat/preview/status actions and setup/help/license.
External destinations were preserved, not fetched or availability-tested.

Task-local artifacts are retained under `$TMPDIR/readme-preview/`:
`baseline.json`, `baseline-readme.md`, `candidate.html`, `baseline.html`,
`check_preview.py`, `assertions.json` and
`{baseline,candidate}-{900,360}-{light,dark}-*.png`.
The assertion receipt binds previews to the README hash above. These are temporary
review artifacts, not repository assets or published screenshots.

**Approximation only:** this is not hosted GitHub, its sanitizer or its exact
stylesheet. In particular, the CommonMark renderer displays `[!NOTE]` as ordinary
blockquote text rather than GitHub's alert decoration. No exact hosted rendering,
manual screen-reader/native-device behavior, authenticated first reply, provider
execution, cross-device synchronization or product parity was qualified here.

## Offline checks

- `flutter test --no-pub test/tooling/readme_assets_contract_test.dart test/tooling/wing_branding_assets_test.dart test/tooling/pages_workflow_contract_test.dart` — six tests pass (Flutter 3.44.2).
- Installed beautify skill `scripts/audit_readme.py README.md` — exit 0;
  three local image references checked, zero non-local image sources skipped.
- `timeout 120 python3 "$TMPDIR/readme-preview/check_preview.py"` — pass,
  including baseline/command/asset comparisons and all composed-preview assertions.
- `git diff --check` and changed-document local link/fragment verification — pass.
- Fresh-context read-only review — no material findings.

These are the complete documentation-scoped checks. No Dart/producer changed, so
Dart formatting/analyze and producer syntax/build/recapture gates are inapplicable.
No docs-role manifest or sharded check runner exists in this checkout. Native/live
qualification and hosted GitHub inspection remain separate from this local commit.
