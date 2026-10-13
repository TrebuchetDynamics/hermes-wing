# Runtime and delivery

Status: current decision

## Decision

Hermes Agent remains an external authoritative runtime. Wing Link packaging and service code are removed. Wing must never
embed Hermes Agent or create a second domain backend.

### Hard boundary: never modify Hermes Agent

Decision: accepted on 2026-09-07; non-negotiable for all Hermes Wing work.

Hermes Agent itself must never be modified for Wing. This applies to the
`hermes-agent/` reference checkout, installed runtimes, and any copied or forked
Agent source or distribution. No source/test edits, patches, monkey-patches,
injected replacement internals, or Wing-specific Agent builds are permitted.
Missing APIs, bugs, test failures and user-interface parity are not exceptions;
do not ask for an upstream-edit exception as a way to unblock Wing work.

Implement changes in Hermes Wing using only supported, unmodified Agent contracts. If those contracts
cannot safely provide an operation, keep it unavailable and explain the missing
capability. Do not bypass this rule with direct Agent-file/database edits or
shadow domain state. Reference source and tests may be inspected read-only.

This does not prohibit explicitly authorized installation/update of unmodified
upstream releases or normal Agent-owned state changes through supported APIs and
reviewed fixed CLI operations. Existing security, approval and validation gates
still apply; runtime state is not permission to alter Agent implementation.

This decision supersedes the earlier proposed upstream implementation checkpoint
in the provider design. Future upstream capabilities may be evaluated when
available; implementing them in Hermes Agent is not Wing's work.

### Read-only upstream references

The four-repository study does not authorize changes to Hermes Agent, Hermes
Desktop or Hermes Conduit. Keep their reference checkouts, source/tests, hooks
(including `.ua/hooks`) and local tool configuration unmodified; preserve existing
unrelated changes rather than repairing them. Desktop and Conduit provide
interaction/recovery examples, not connected-Agent capability or authorization
authority. Do not copy their privileged file/config/database access, relays or
reconnect security-setting replay into Wing.

Adopt the [study findings](../analysis/understand-anything/README.md) through the
[follow-through plan](../plans/2026-10-03-study-follow-through.md) within existing
Wing seams. Study graphs, scans and analysis-tool tests are source/tool
evidence, not product, device, service or release qualification. Missing contracts
defer only their individual operations; they do not justify upstream patches, a
data-plane proxy, merged credentials or broad compatibility expansion.

### Agent-only delivery

Wing ships only the Flutter client and its native platform dependencies. There is
no host-management service, Go build, service bootstrap, management catalog or
compatibility adapter. Historical service procedures and receipts are archived.
Installed personal services and their data are not stopped, uninstalled or migrated.

Local discovery is metadata-only; native SSH is an ephemeral authenticated forward
to Agent, not lifecycle authority. Android/Termux preparation is an explicit user-run
Agent procedure in a separate sandbox, with best-effort background execution.
Hermes Wing does not request Termux external-command access.

Missing Agent operations stay unavailable; no arbitrary shell, config keys, paths
or shadow state may replace the removed management plane. Application artifacts
must be versioned and signature/digest verified; actual activation, health and
rollback evidence belongs to each named target. Offline fixtures do not qualify
service lifecycle, installation, signing, deployment or native-device behavior.
