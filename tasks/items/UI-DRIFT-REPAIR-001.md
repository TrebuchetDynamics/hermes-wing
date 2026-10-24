+++
schema = 1
id = "UI-DRIFT-REPAIR-001"
title = "Repair the red hermes_chat widget and 200%-text web journeys at current main"
short = "Repair red chat journeys at main"
status = "open"
goal = "CHAT-FIDELITY"
section = "Next"
rank = 9000
depends_on = []
touches = ["lib/features/hermes_chat/", "test/features/hermes_chat/", "playwright/tests/regression/", "docs/quality/"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Repair only the two reproduced failure clusters recorded below. Cluster A is the connection chooser, information-help and SSH-remember widget journeys; cluster B is the chat-workspace-overlay 200% text journeys. Root-cause each before editing, classify test drift against a real product defect, and fix the actual cause. Do not rewrite unrelated expectations, loosen assertions, filter files or delete journeys to reach green, and do not touch Files, live or device scope."
acceptance = ["Each named journey below passes on the current tree with its purpose preserved, or is replaced by an equally strong assertion that matches verified current product behaviour; no journey is skipped, filtered or weakened, and no acceptance is reduced to 'test deleted'.", "The cause of each cluster is recorded: either a product defect fixed at the source, or a spec/expectation that drifted from an intentional, currently correct behaviour with the commit that changed it named. A 200%-text failure is not dismissed as flakiness without three consecutive isolated runs of the same journey.", "Evidence lists the exact commands, pass/fail counts and any remaining red cells. Cluster A and cluster B are reported separately, and a green focused run is not reported as whole-suite green."]
checks = ["dart format --output=none --set-exit-if-changed lib test", "flutter analyze --no-pub", "flutter test --no-pub --concurrency=1 test/features/hermes_chat/widgets/ssh_quick_connect_test.dart test/features/hermes_chat/widgets/connection_information_help_dialog_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart", "flutter test --no-pub --concurrency=1 test/features/hermes_chat/", "flutter build web --release -t lib/main_e2e.dart && npm run web:e2e", "git diff --check"]
exclusions = ["No test deletion, skip, filter, timeout inflation or assertion weakening used as the fix", "No unrelated product, Files, Agent, runtime, credential or live/device changes", "No lockfile, SDK, CI gate or receipt changes", "No claim that main is green while either cluster still fails"]
+++

- Sources: [Full check](AGENTS.md#validation) and the journey owners [connection paths](docs/product/routes.md) and [chat fidelity](docs/product/prd.md).
- Reproduced 2026-10-24 at `69e2a8dd` plus the recorded Files/spec commits, on this host with the locked toolchain. Both clusters fail identically with the working changes stashed, so neither is introduced by the Files metadata work or the sessions-panel region fix.
- Cluster A — four widget failures in `test/features/hermes_chat/`: `hermes_chat_screen_auth_recovery_test.dart` "Add Hermes groups VPN within three primary connection choices"; `connection_information_help_dialog_test.dart` "production chooser offers safe selectable connection help" (finds no `connection-information-help` key); `ssh_quick_connect_test.dart` "first verified connection remembers only with explicit consent: false" and ": true". Command: `flutter test --no-pub --concurrency=1 test/features/hermes_chat/` reports 4 failing.
- Cluster B — four Playwright failures, all `chat-workspace-overlay.spec.mjs:259` "Settings retains replacement connection via rendered saved-host selection …overlay history" at 390px/200% text and 1280px/200% text, with and without an active run. `npm run web:e2e` reports `38 passed`, `4 failed` both at this tree and with these changes stashed; the failing step is `getByRole('button', { name: 'Connections', exact: true }).first().click()`.
- Note on provenance: the recorded main-check evidence claims a pass at `69e2a8dd`, but the whole Dart suite and the web suite both show these red journeys on that same revision here. Re-verify what the main-check gate actually executed before treating either cluster as newly introduced or as flaky.
- Next action: reproduce each journey alone, capture the failure output, then repair the real cause. Keep the two clusters in separate commits so a regression cannot hide behind the other.
