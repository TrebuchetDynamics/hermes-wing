+++
schema = 1
id = "DOC-M3-PROVIDER-CONTRACT-LIVE"
title = "Live checks for DOC-M3-PROVIDER-CONTRACT"
short = "Live checks for DOC-M3-PROVIDER-CONTRACT"
status = "open"
goal = "M3-PROVIDER"
section = "Needs decision"
rank = 33000
depends_on = ["DOC-M3-PROVIDER-CONTRACT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-M3-PROVIDER-CONTRACT left pending."
acceptance = ["Each check passes on the real target: - No live support is qualified. Future isolated Linux UI/provider validation, deployed capability advertisement, secret transport/storage, concurrent-writer/replay and activation checks require an eligible unmodified Agent contract plus separately scoped target/authority/effects consent; current inspected contracts do not establish the ADR guarantees. - Android/device and native UI qualification remain NOT_CHECKED; source and fixture test inspection does not qualify those platforms."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](docs/adr/api-and-state.md#required-agent-owned-mutation-contract), [retained offline task history](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository

## Completed bounded per-operation UI correction

- The credential sheet now checks Set, Remove and Validate independently against
  each exact advertised endpoint/grant, both before dispatch and after completion.
  Missing capability documents fail closed instead of bypassing checks. Set
  permission no longer implies Remove or Validate permission.
- Added explicit single-operation and missing-capability regressions; positive
  synthetic sheet fixtures now declare their actual operation grants rather than
  relying on absent capabilities. All 98 provider tests and analysis passed using
  Flutter 3.44.9. No live credential mutation or validation was executed.
- This is only the route/grant presentation correction. It does NOT qualify the
  legacy request shapes as meeting the ADR's opaque credential identity, revision,
  idempotency and effect-consent requirements. The broader contract-admission
  correction at both channel and UI boundaries remains pending; do not mark this
  task or provider credential lifecycle complete from these fixtures.
