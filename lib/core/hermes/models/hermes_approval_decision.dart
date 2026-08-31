/// Choices for responding to a Hermes run approval request
/// (`POST /v1/runs/{run_id}/approval`). `name` is sent verbatim as the
/// Agent's `choice` field.
enum HermesApprovalDecision { once, session, always, deny }
