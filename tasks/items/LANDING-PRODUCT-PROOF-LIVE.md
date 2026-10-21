+++
schema = 1
id = "LANDING-PRODUCT-PROOF-LIVE"
title = "Live checks for LANDING-PRODUCT-PROOF"
short = "Live checks for LANDING-PRODUCT-PROOF"
status = "open"
goal = "LANDING-ONBOARDING"
section = "Needs decision"
rank = 22000
depends_on = ["LANDING-PRODUCT-PROOF"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for LANDING-PRODUCT-PROOF left pending."
acceptance = ["Each check passes on the real target: - Named-platform/native and physical-device connection, full-app SSH login, real secure storage, live authenticated first reply/provider inference and combined approval/Stop/reconnect workflows remain separate qualification tasks. Browser fixtures/builds do not establish them. - Manual screen-reader qualification remains unperformed, including current selectable approval-detail semantics; speech/microphone, notifications and detached-run/background recovery are not qualified by this work. - Exact GitHub rendering/sanitization, real social-platform card cropping/cache behavior, public artifact freshness and consented human first-reply/onboarding review require their respective authorized environments. Local metadata and Markdown approximations are not those results. Broader landing/share parent acceptance must not be closed from this local docs/proof commit alone."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](../../docs/plans/2026-10-12-wing-landing-onboarding.md#existing-agent-onboarding-outcome), [retained offline task history](../../todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
