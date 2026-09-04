# Transcript performance evidence

Status: benchmark harness implemented; native measurements blocked. No rendering
optimization or device performance claim is supported by this receipt.

## Reproducible workload

[The native integration benchmark](../../integration_test/hermes_transcript_performance_test.dart)
generates exactly 100,000 and 1,000,000 ASCII bytes for paragraphs, fenced code,
a giant line, eight-column tables, and an unclosed fence. It never reads real
transcripts or downloads images. Each case mounts twice for warmup and ten times
for measurement, then appends twenty 1 KiB tails with a requested 50 ms cadence
while alternating scroll position.

The report records mount wall time, frame build/raster p95, post-close RSS and
process maximum RSS. Mount time includes test pumping and layout; it is not
isolated Markdown parse CPU time. Stream update times include the requested
50 ms pump and must not be mislabeled interaction stalls. Frame callbacks can be
empty in a non-device test environment; null percentiles are missing evidence,
not zero-cost rendering. Maximum RSS is process lifetime RSS, not per-case heap
allocation. The harness preserves full authoritative text in `HermesRichText`.

Run a selected case first, then omit the two `TRANSCRIPT_*` defines for the
whole matrix:

```bash
xvfb-run -a flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/hermes_transcript_performance_test.dart \
  -d linux --profile \
  --dart-define=TRANSCRIPT_CASE=paragraphs \
  --dart-define=TRANSCRIPT_BYTES=100000 \
  --dart-define=BENCHMARK_SOURCE=<reviewed-source-and-dirty-state>
```

Flutter's existing integration driver writes `reportData` to its test output;
the benchmark also emits `TRANSCRIPT_PERFORMANCE` JSON. Retain that report with
the exact bundle's digest, dependency lock digests, target display/renderer,
physical memory, Flutter version, source revision and working-tree patch digest.
The source label alone does not identify an artifact.

## Attempt on 2026-09-04

- Source baseline: `5cd4400e582590e6d1d6337a2bbfc32291b36f0e`, dirty workspace.
- Available target: Linux x64, Ubuntu 24.04.4, software rendering, Xvfb.
- Host class: AMD Ryzen 9 5900X, 24 logical CPUs, 65,738,968 KiB physical RAM.
- Requested case: 100,000-byte paragraphs, profile build.
- Result: build did not reach runtime. CMake's `audioplayers_linux` plugin
  dependency check failed because `gstreamer-1.0` was unavailable.
- Artifact digest, warm/cold timing, frame percentiles, interaction stall and
  memory settlement: **unmeasured**. No benchmark artifact was produced.
- `flutter test --profile` is not supported by this pinned CLI; use the
  `flutter drive --profile` command above.

No system packages were installed. Provision the documented Linux build
dependencies before repeating this command. This desktop development host is
not Android or physical mobile qualification.

## Remaining qualification

Investigate p95 frame work above 32 ms on a named 60 Hz target, interaction stalls
above 100 ms, or memory that fails to settle after five open/close cycles. These
are investigation thresholds, not results or absolute memory budgets.

Still required: successful native runs of all cases; isolated parser profiling;
true interaction-latency/stop-control measurements; cold-process samples;
200% text and reduced-motion correctness; a deeper/wider table matrix; and
artifact-bound before/after comparisons if an optimization becomes necessary.
Only then select less rebuilding, immutable completed blocks, or an accessible
bounded preview. Copy/export must retain full text and safe link/image policies.
