# Desktop 1:1 port — first implementation wave

Owner decision: prioritize a 1:1 Hermes Desktop product port. Match feature coverage,
navigation, terminology, interactions and recovery; do not infer accepted parity
from source presence. Agent/desktop/conduit references remain read-only.

## Dependency topology and file ownership

Three independent lanes run first; parent verification/review follows all returned
outputs. All inherit the parent gpt-6.1-sol model intentionally for comparable
source reasoning; mixture-routing tools are not exposed in this host.

| Lane | Writable files | Verification | Stop condition |
| --- | --- | --- | --- |
| Documentation | `ROADMAP.md`, `docs/product/hermes-desktop-parity.md`, `docs/product/hermes-desktop-ui-gap.md`, `docs/adr/client.md` | scoped diff whitespace check and source-reference checks | source-backed priorities/gaps recorded, no old acceptance claims promoted |
| Shell builder | `lib/shared/widgets/app_shell.dart`, new `test/shared/widgets/app_shell_desktop_parity_test.dart` | new test observed RED then GREEN; relevant shell tests; formatter and analyzer | Desktop collapse/expand interaction implemented and exercised, or precise blocker |
| Read-only audit | new `docs/analysis/2026-10-03-desktop-port-next-gaps.md` only | exact reference paths and available Wing counterparts checked | ranked next gaps and direct-Agent/Wing Link dependency findings recorded |
| Parent integration | this plan and new `docs/quality/2026-10-03-desktop-port-first-wave.md`; fixes to producer files only after lane release | format gate, flutter analyze, flutter test --concurrency=1, independent review | bounded wave verified or failures explicitly recorded |

Shared interfaces: routing, channel contracts, localization, theme and all backend
code are read-only. No lane may change upstream, dependencies, generated files,
credentials, personal runtime state or unrelated dirty changes. Existing shell
edits must be preserved; stop rather than overwrite unexplained concurrent changes.
No commits, publication or runtime/card acceptance is authorized by this wave.

## Acceptance

- Roadmap expresses Desktop parity delivery order and explicit deviations, rather
  than using missing remote management contracts to redefine the product target.
- First implementation is a source-confirmed local shell interaction requiring no
  new Agent API, privilege or Wing Link dependency.
- New regression fails for the missing behavior before implementation and passes
  afterward; existing regression expectations are not weakened.
- Final integrated checks and source review are captured separately from browser,
  native device, actual Agent generation, card acceptance and release qualification.

## Execution ledger

- Bootstrap: dirty worktree inspected and preserved; upstream references located
  under the repository. Native subagents are available. Dispatches use delivered
  completion messages, not status polling; downstream work waits for their results.
