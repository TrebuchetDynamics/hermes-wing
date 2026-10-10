# Official Hermes Desktop reference

## Authority

The owner corrected the product reference to [Nous Research Hermes Desktop](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop).
Use `hermes-agent/apps/desktop/` in the read-only Agent checkout.
Do not use the separate retired Desktop checkout for product decisions, feature matrices, UI comparisons or implementation guidance.

The verified local Agent revision is `158fd638da1629c8e62caf9ade1515d162def8ab`.
Its `apps/desktop` tree is `2038178ee53e13cde6fe297daa2484a868e7d3a3`.
The live `main` probe returned `d94b70f675205c2c046138997819428772cd2678`.
These revisions differ. The inspection below describes the local checkout, not current live `main` or a released application.
No reference checkout was updated, modified, installed or launched.

## Initial source findings

Source inspection covered the official Desktop README, engineering guides and design contract at the local revision.

- `apps/desktop/README.md` identifies the official Electron app, its chat, previews, file browser, voice, settings and onboarding.
- `apps/desktop/src/AGENTS.md` identifies a headless `hermes serve` backend and JSON-RPC via `apps/shared`. Local pooled processes are scoped to connection/profile. SSH, URL/token and Cloud are remote connection topologies. This is not proof that Wing's existing REST/SSE channel provides equivalent operations.
- `apps/desktop/DESIGN.md` defines Chat as the home surface, durable Chat/Skills/Messaging/Artifacts destinations, route overlays, persistent working panes and Project-owned workspace directories.
- Official Desktop source, nearest tests and runtime evidence must determine exact welcome, auth, transport, navigation and lifecycle behavior. The initial guide inspection is not a full feature matrix or runtime qualification.

## Withdrawn evidence

Earlier Desktop source comparisons used the wrong application. Their reference citations and conclusions are withdrawn as evidence of official Desktop parity.
Historical Wing tests and receipts remain records of their exercised Wing behavior, not evidence that the official product has the same behavior.
Do not transfer old source paths, hashes, screenshot claims, feature groups or parity totals onto the official application by renaming them.
The old feature matrix is explicitly withdrawn pending a fresh official-source mapping.

The generated SSH key and copyable Help remain owner-requested Wing functionality. Their passing Wing tests do not establish official Desktop parity.
Existing Agent authority, profile isolation, secret handling and strict host-key review remain enforced.

## Follow-up

`CONNECTION-OFFICIAL-DESKTOP-PORT` in [TODO](../../TODO.md) owns official-source connection tracing and the smallest production welcome/connection correction with regression tests.
`PARITY-OFFICIAL-MATRIX` owns rebuilding the matrix from the official app after that connection slice.
Preserve active ownership, existing task IDs and historical test results. Do not patch Agent or invent transport compatibility.
