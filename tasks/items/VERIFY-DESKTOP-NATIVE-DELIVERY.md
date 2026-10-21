+++
schema = 1
id = "VERIFY-DESKTOP-NATIVE-DELIVERY"
title = "Qualify named-target Linux install, update, client-only removal and retained-state recovery"
short = "Qualify named-target Linux install, update, client-only removal and retained-state recovery"
status = "open"
goal = "DESKTOP-DELIVERY"
section = "Needs decision"
rank = 15000
depends_on = ["DOC-DESKTOP-UNINSTALL-EVIDENCE"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "separately approved disposable Linux target and synthetic state only; qualify complete bundle/launcher ownership, activation/rollback, client-only removal, retained endpoint identity and actual keyring reinstall readability. Preserve Agent services, credentials, raw legacy records and unrelated files. No live operation now."
acceptance = ["named-target source/artifact-bound receipts prove each operation and failure/recovery outcome; missing client-only producer, signing or access remain explicit gaps. Offline source and mocked storage checks cannot close this task."]
exclusions = []
+++

- Payoff: prove desktop delivery without confusing offline evidence with safe native removal.
- Sources: [delivery map](docs/quality/linux-desktop-delivery-evidence.md), [uninstall map](docs/quality/linux-desktop-uninstall-evidence.md#exact-remaining-proof), [accepted port roadmap](ROADMAP.md#flutter-port-execution-roadmap).
- Ownership: coordinator wing; pending exact disposable target/removal authority and a safe current client-only procedure. No personal service or data changes authorized.
- Planner decision: skip destructive installed-target qualification until the owner supplies or approves a disposable Linux target and bounded install, update, client-only removal and retained-state scope. The safe owned-file procedure, artifact/launcher identity, rollback design and keyring observations remain engineering work, not questions for the owner to implement. Do not run the current personal uninstaller or alter Agent services to obtain evidence.
- Touches: none before conversion; ** stands for the whole repository
