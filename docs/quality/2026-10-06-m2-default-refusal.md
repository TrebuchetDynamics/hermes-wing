# M2 QA default refusal and library privacy

Card: `t_41606eec`. Backlog: `QA-M2-DEFAULT-REFUSAL`.
M2 remains unverified; qualifies=false. This is offline source-level enforcement,
not an admitted installed authority or platform qualification.

## Delivered boundary

`integration_test/hermes_m2_observer_main.dart` now calls `m2Bootstrap()` and
returns without initializing Flutter binding, launching a widget, overriding
providers, or constructing storage, journals, observers, channels or delegates.
The public bootstrap has no inputs. It returns sanitized `not_admitted` and
`continuation_unavailable`, with `qualifies=false`. No public request interface,
authority issuer, environment selector or fake/runtime selector remains.

`integration_test/support/m2_observer.dart` exposes only that bootstrap/result
and exports the metadata library. The private default boundary is never admitted;
even its launch method refuses without a fallback. The raw secure sink was
removed, not preserved behind an unsafe test constructor. No QA plugin factory,
raw writer, journal or observer is delivered in the runtime dependency closure.
The normal product entrypoint, production providers and product stores are untouched.

`integration_test/support/m2_metadata.dart` retains aliases, enums and strict
validator/envelope behavior. These are metadata, not authority.

Both existing tooling consumers were inspected before migration. They now invoke
registration-only functions in `test/tooling/support/m2_fake_harness.dart`.
Its three parts keep fake sinks, journals, observers, custody, writers, retention
and fake authority library-private. The library has no secure-storage import,
real channel factory, runtime launcher or issuer selection. No factory returns
its private objects. Arbitrary sink injection survives only inside these private
fake diagnostic tests, never as a runtime API.

The former widget test exercised the unsafe injectable runtime app and was
replaced by actual-entrypoint refusal. The former secure constructor assertions
were replaced by inaccessible-API probes. Validator, coalescing, invalidation,
owner/fence, delegate identity and error coverage remain executable. Existing
retention/revocation/competitor checks remain, with explicit new first-write and
foreign-writer assertions.

## Executed acceptance mapping

Run from the repository root:

    python scripts/check_m2_default_refusal.py
    flutter analyze
    dart format --output=none --set-exit-if-changed integration_test/hermes_m2_observer_main.dart integration_test/support/m2_observer.dart integration_test/support/m2_metadata.dart test/tooling/m2_bootstrap_test.dart test/tooling/m2_observer_test.dart test/tooling/m2_receipt_admission_test.dart test/tooling/support/m2_fake_harness.dart test/tooling/support/m2_diagnostic_writer.dart test/tooling/support/m2_observer_cases.dart test/tooling/support/m2_receipt_admission_cases.dart test/tooling/support/m2_bootstrap_probe.dart.template

The checker executes the final named suite:

    flutter test --concurrency=1 test/tooling/m2_bootstrap_test.dart test/tooling/m2_observer_test.dart test/tooling/m2_receipt_admission_test.dart

Exact inner argv/cwd/exits, consumer diagnostics, final suite output, source hashes,
resolved imports and bounded discovery are in
[probe evidence](../../.task-evidence/t_41606eec/probes.json).
Final formatter/analyzer/whitespace receipts and authored fingerprints are in
[validation evidence](../../.task-evidence/t_41606eec/validation.json).

1. REG-DEFAULT/INJECTION: the actual main and public bootstrap execute without
   timers. An isolated support mirror attaches a test-only part to the unchanged
   private bootstrap function used by main. A denied sentinel counts attempted
   runtime launch; assertions run immediately, after awaited refusal and after
   explicitly draining captured microtasks. No wall-clock waits are used.
   Construction/start/I/O categories are separate zero totals: the source closure
   additionally proves their factories/operations do not exist in this delivery
   graph. These are not measurements of a plugin or hypothetical installed graph.
   There is no remaining public authority/request input whose type or equality
   could grant admission. Counterfeit/foreign/revoked/fake values and arbitrary
   sinks/journals/provider overrides cannot be supplied to runtime bootstrap.
   Negative consumers prove the removed input APIs are inaccessible. Existing
   held-read/retention, premature release, competitor and late-revocation tests
   execute only within the private fake-only composition.
2. REG-API: 60 isolated negative consumers and four metadata/bootstrap positive
   controls run through relative imports, resolved file URIs, a real export
   barrel, and a temporary resolved package alias to the same source mirror.
   Each negative requires the exact intended diagnostic code and member name;
   unrelated missing-import errors fail the checker. The QA files are outside
   Wing's `lib/`, so `package:wing/../integration_test/...` is not a valid import;
   the package control uses an explicit resolved alias, not a nonexistent URI.
   Public raw sinks/read/write, journal/sink access, app/observer injection,
   bootstrap authority/journal/sink/override/fake inputs, main authority input,
   private fake journal/sink and private runtime boundary are refused.
   Literal import/export/part directives and all conditional alternatives are
   traced; incoming QA edges must stay within the explicit source allowlist.
3. REG-POSITIVE/mutations: exact prior bytes are retained after one inspection;
   explicit release precedes exactly one first valid fake write and one separate
   readback. Gate removal fails the launch invariant; reopening the constructor
   makes a forbidden consumer compile and fails its expected-error invariant;
   foreign-writer acceptance fails the explicit fake-I/O invariant (not a timeout).
   Mutations occur only in disposable source mirrors. Before/after fingerprints
   match; final original-source tooling tests pass. The migrated fake oracle is
   newly executed, not inferred from predecessor approval.
4. Ledger/commit/review: helper-managed task/evidence/render updates retain M2's
   unverified status. The helper initially auto-promoted the last completed task's
   goal; its public load/dump/render APIs restore the accurate unverified ceiling.
   Ledger validation reports `M2: unverified goal has no open task` (exit 1),
   retained in the ledger receipt. No follow-up task or milestone proof is invented.
   Only this card's authored files are included in the authorized
   local overlay branch; the shared HEAD/index and unrelated dirty files are not
   staged or committed. The native same-card review handoff is the final goal step;
   review approval is not claimed.

## Scope and predecessor limits

The [caller-closure report](2026-10-06-m2-runtime-caller-closure.md) is the historical
pre-migration source map, not current constructor evidence. Its source fingerprints
and the [ordering receipt](2026-10-06-m2-custody-ordering-oracle.md) are not carried
forward as unchanged-source passes: the two consumers and support boundary changed.
Their original receipts/branches remain intact. The metadata and private fake
behavior are revalidated here. No upstream Agent/Desktop/Conduit source changed.

Only offline Dart/Flutter tooling on Linux was exercised. Installed issuer,
secure-plugin I/O, protection/durability, cross-process custody, packaging/build/
delivery, Android device/death/relaunch, admitted history, authoritative counts,
private transport, credentials, network and live qualification are NOT_CHECKED.
Source refusal is a prerequisite, not M2 completion or a usable positive QA runtime.

Questions: none. Defaults: refuse all runtime QA work; no live, no secrets, no
upstream changes, no product-store migration, no installed issuer activation.
