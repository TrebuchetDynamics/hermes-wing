/// Choices for responding to a Hermes run approval request
/// (`POST /v1/runs/{run_id}/approval`). See
/// docs/adr/0006-run-sse-approvals-and-stop-lifecycle.md. `name` is sent
/// verbatim as the `decision` field.
enum HermesApprovalDecision { once, session, always, deny }
