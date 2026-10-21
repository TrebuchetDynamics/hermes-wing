+++
schema = 1
id = "VERIFY-SLASH-AUTHORITATIVE-TRANSPORT"
title = "Qualify supported authoritative slash execution and unavailable-action recovery"
short = "Qualify supported authoritative slash execution and unavailable-action recovery"
status = "open"
goal = "SLASH-CATALOG"
section = "Needs decision"
rank = 5000
depends_on = ["DOC-SLASH-DENIAL-EVIDENCE"]
touches = ["lib/core/hermes/", "lib/features/hermes_chat/", "lib/features/enrollment/", "lib/router/", "lib/shared/", "test/core/hermes/", "test/features/hermes_chat/", "test/features/enrollment/", "test/router/", "integration_test/", "playwright/tests/", "docs/quality/"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "implement only exact advertised unmodified Agent command contracts and their coherent composer/recovery consumers; preserve direct Agent ownership and no replay."
acceptance = ["catalog/completion/dispatch identity and grants match the selected Agent; unavailable-action disclosure and zero specialized I/O have production-path oracles; ordinary chat fallback is explicit. Record separate native/live proof before parity."]
checks = ["For changed inputs, `flutter test --no-pub --concurrency=1 test/core/hermes/ test/features/hermes_chat/`; `flutter analyze --no-pub`; `git diff --check`. Reuse unchanged source-bound receipts. Trace exact advertised operation/grant ownership and add production-path catalog/dispatch/denial oracles; rebuild the deterministic E2E target before browser checks. Preserve the absent-authoritative-transport hold and explicit ordinary-chat fallback; no invented command route, live execution or refusal-only parity claim."]
exclusions = []
+++

- Section: Needs decision.
- Payoff: match official Desktop command outcomes without treating ordinary chat fallback as command execution.
- Sources: [accepted port roadmap](../../ROADMAP.md#flutter-port-execution-roadmap), [catalog contract](../../docs/quality/slash-catalog-contract.md), [denial and recovery evidence](../../docs/quality/slash-denial-evidence.md).
- Ownership: unclaimed; blocked by absent advertised authoritative command transport. No shell bridge, invented routes, upstream edits or repeated contract audit may substitute.
- Readiness: CONTRACT-UNREADY: the latest attempt confirms no authoritative catalog/completion/dispatch contract on Wing's consumed transport. No changed inputs justify another unchanged audit or refusal-only implementation.
- Planner decision: skip command execution qualification until the exact advertised unmodified Agent operation, grants and owner identity contract exists. Preserve original acceptance, dependencies and unavailable behavior; no ordinary-chat success substitution, shell bridge, invented routes or upstream changes.
- Next action: retain the clean b5c4a4bff404c72b08e816f3f429db13252049e3 attempt/report; reconsider only on new qualifying contract evidence, then keep native/live execution separately gated.
