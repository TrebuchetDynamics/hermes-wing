/// Choices for responding to a Hermes run approval request
/// (`POST /v1/runs/{run_id}/approval`). See
/// docs/adr/api-and-state.md. `name` is sent
/// verbatim as the `decision` field.
enum HermesApprovalDecision { once, session, always, deny }
