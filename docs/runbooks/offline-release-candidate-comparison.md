# Read-only offline release candidate comparison

Run this source-checkout tool with Node.js 22 or later. It does not build,
extract, launch, install, sign, download, publish, or write candidate files.
It requires the complete public candidate bundle, including the published
`release-qualification-index.json`, and an explicit candidate source tree.
See [required public inputs](../quality/2026-10-06-m6-candidate-admission.md#required-public-inputs)
and the [existing execution gate](release-alpha.md#local-artifact-verification).
Do not run that execution gate merely to use this offline tool.

Obtain all seven expected identity fields and the public Android certificate
fingerprint independently from an admitted release record. Never populate them
solely by reading the candidate being examined. No signing secrets are needed.
The source revision is an expected identity, not a claim that this tool inspected
Git history: supply the independently reviewed source checkout at that revision.
The tool checks its four dependency lock/module files, not the entire source tree.
Keep both input trees stable and read-only for the duration; this is not an atomic
snapshot of a concurrently modified filesystem.

From the Wing tooling checkout (which need not be the candidate checkout):

```bash
node scripts/compare_release_candidate.mjs \
  --source-root /public/reviewed-candidate-source \
  --candidate-dir /public/reviewed-candidate-bundle \
  --source-revision '<40 lowercase hex characters>' \
  --tag v0.1.0-alpha.1 \
  --version 0.1.0 \
  --build-number 7 \
  --run-id 12 \
  --run-attempt 1 \
  --repository example/wing \
  --android-certificate-sha256 '<64 lowercase hex characters>'
```

All values above are placeholders/examples, not real release evidence. Replace
every value with the independently admitted candidate context. Every option is
required exactly once, in any order. Unknown options, positional arguments,
missing values and malformed identities fail closed. The tag must match the
version and use `vMAJOR.MINOR.PATCH-alpha.NUMBER`. Build/run/attempt values are
1–20 decimal digits; identity strings are at most 120 characters. The certificate
is a public SHA-256 fingerprint with no colons or spaces. Root arguments are at
most 4096 characters, must name existing directories, and must not traverse
symlinks (including parent directories). Relative roots are explicitly resolved
against the command's working directory; absolute public roots are recommended.
There is no HEAD, version-file, CI environment or certificate environment fallback.

## What the result means

Exit 0 prints exactly:

```text
Offline candidate comparison matched. Signatures and runtime NOT_CHECKED.
```

Exit 1 prints only `Offline candidate comparison failed.` to stderr, with no
candidate content, supplied arguments, filesystem paths or exception details.
There is no help-only success exit; use this runbook for usage. Failure includes
missing files, unsafe file types/symlinks, oversized inputs, malformed schemas,
identity/certificate disagreements, byte mismatches and an absent/altered index.

The command reuses `readJson`, `verifyManifest` and `qualificationIndex` from
[release_evidence.mjs](../../scripts/release_evidence.mjs). It checks the independent
public certificate against the Android manifest separately, then deep-compares
the published index with recomputed bindings for all three manifests, four
client artifacts, dependency inputs, auxiliary files and required Android/host receipts. Object key order is irrelevant;
array order and exact fields remain significant. It preserves the existing
schema and receipt contracts. JSON reads are limited to 128 KiB, text smoke
receipts to 8 KiB, dependency inputs to 16 MiB and artifact hashes to 2 GiB per
file. Text reads remain bounded even if a file grows after the first hash.
Files must be nonempty regular files with no symlinked parents. There is no
recursive directory enumeration, private-state search or artifact execution.

A match proves offline consistency with supplied expectations, not provenance,
signing custody, cryptographic signature validity, checksum-sidecar syntax,
truth of recorded runtime observations, full-source identity, a clean Git tree,
or absence of unrelated files in the bundle. Independent admission and the
separate execution/signature gate remain necessary. Source-dirty flags retain
the existing manifest semantics; the index does not contain them.
Actual candidate comparison, signatures, runtime, install, upgrade, recovery,
Android qualification and M6 remain NOT_CHECKED/unverified until corresponding
real evidence exists. Synthetic test passes do not advance those claims.

## Checkout delivery and verification

The complete production local import closure is
`compare_release_candidate.mjs` → `release_evidence.mjs` → Node built-ins only.
Run from the Wing source checkout and retain both modules together. No package,
installer, distribution manifest or packaged runtime support is added or claimed.
The imported verifier's emit/aggregate/current-identity and toolchain subprocess
paths are not called by the comparator; its direct CLI guard is inactive on import.

```bash
node --check scripts/compare_release_candidate.mjs
node --check scripts/release_evidence.mjs
node --check test/tooling/compare_release_candidate_test.mjs
node --test test/tooling/compare_release_candidate_test.mjs test/tooling/release_evidence_test.mjs
```

Use the profile's approved `TMPDIR` for tests. The fixtures are isolated synthetic
files deleted by test hooks. They exercise the actual comparator subprocess with
exact exits and fixed outputs, a blank tool lookup PATH, poisoned identity
environment, separate source/bundle trees, byte snapshots before/after every
invocation, matching inputs and discriminating failure cases. They are not
observed releases or platform qualification.

### Executed Node.js 22 baseline

`DOC-M6-CHECKER-NODE22`: on Linux x86_64, Node.js **v22.22.2**, the three
syntax commands above exited 0 and the combined test command passed **97 tests**,
zero failures, cancellations or skips. The tested source base was
`caaff7803e4b2abebbf03557d0f12b166530b2ab`; all four inputs were unchanged after
execution. The existing user-space runtime was used without installation or
network access. SHA-256 inputs:

- `scripts/compare_release_candidate.mjs`: `2490316191285d19b37468f2a8800c65ebbe6b12c2130f4dc839f076979e925c`
- `scripts/release_evidence.mjs`: `3a55e27bb7d1a75a2b6cb4f309a775dc57c43059918e8bf243d851fca0755d96`
- `test/tooling/compare_release_candidate_test.mjs`: `f8ab12bf39e573da99e3eb8c9659a225ab31216b505eda90dbcb80891066d164`
- `test/tooling/release_evidence_test.mjs`: `409b1ccb1ac412b360a6fde7764efb28efd735bfabb85af655f3ed0fe5e2ba38`

This qualifies the synthetic comparator/verifier checks on Node.js 22, not an
actual release candidate or the earlier 120-test historical input. Signatures,
M1–M5, installed upgrade/recovery and M6 remain unverified. The next proof slice
is `DOC-M6-INTEGRATED-RECEIPT-GAP`: identify the first missing same-artifact
Android workflow binding without acquiring, building, installing or signing it.

Historical service-bearing manifests and bootstrap payloads are not accepted by
the current client-only comparison contract. Preserve their receipts as history,
not as evidence for a new release. No legacy release mode is offered.
