# Understand Anything tooling execution

> Reference correction: [official Desktop authority](../../quality/official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


## Outcome and scope

Executed the **actual upstream deterministic scanner**, not a replacement file walker, against Wing, Hermes Agent, Hermes Conduit, and Hermes Desktop. Every final scan completed without read/stat failures and repeated byte-identically in consecutive runs. Outputs describe the working tree at scan time, not pristine commits; Wing's unrelated dirty files were preserved. Static census plus bounded real parser smoke tests only: no LLM analysis, fabricated symbols, generated graph, inference, dashboard, runtime service, hook, or profile/plugin configuration.

UA commit: `1d7418b8abfa543744ae029e63a482aee03f9022`. Node: `v26.7.0`. The shell's pnpm outside the tool workspace reported **12.9.1**; inside the pinned tool workspace it reported and executed **10.6.2** (root packageManager pin). No global package-manager change was made.

Repository HEADs:
- `wing`: `ca149a82189c8c9e5abd98b376bfeae1e43f6f3f`
- `hermes-agent`: `158fd638da1629c8e62caf9ade1515d162def8ab`
- `hermes-conduit`: `67a2e8de6b39d2086f59149e0f5fd8b1d44c1fe6`
- `hermes-desktop`: `withdrawn reference revision`

## Final census

| Repository | Files scanned | Additional ignore drops | Newline count | Parser samples |
| --- | ---: | ---: | ---: | ---: |
| wing | 884 | 21 | 217,027 | 24 |
| hermes-agent | 15,237 | 1,746 | 3,941,464 | 17 |
| hermes-conduit | 424 | 0 | 265,070 | 6 |
| hermes-desktop | 948 | 16 | 356,369 | 6 |

`filteredByIgnore` is UA's count of CLI/user-ignore drops **beyond its hardcoded defaults**, not total excluded files. Git-ignored files are not candidates; `--exclude-analysis-data` removes analysis directories before this counter. Counts include selected docs/config/scripts and unsupported language extensions, not just executable source. Newline counts use scanner byte-newline semantics, not semantic LOC. Generated code not matched by ignore rules can remain.

The final successful stdout was:

```text
wing: scan-project: filesScanned=884 filteredByIgnore=21 complexity=very-large repeat=byte-identical samples=24
hermes-agent: scan-project: filesScanned=15237 filteredByIgnore=1746 complexity=very-large repeat=byte-identical samples=17
hermes-conduit: scan-project: filesScanned=424 filteredByIgnore=0 complexity=large repeat=byte-identical samples=6
hermes-desktop: scan-project: filesScanned=948 filteredByIgnore=16 complexity=very-large repeat=byte-identical samples=6
Upstream statuses preserved; all four scanner outputs repeat byte-identically.
```

## Artifacts and reproduction

All paths below are relative to this report's directory:

- `tooling/wing-scan.json`
- `tooling/hermes-agent-scan.json`
- `tooling/hermes-conduit-scan.json`
- `tooling/hermes-desktop-scan.json`
- `tooling/wing-extract-sample.json`
- `tooling/hermes-agent-extract-sample.json`
- `tooling/hermes-conduit-extract-sample.json`
- `tooling/hermes-desktop-extract-sample.json`
- `tooling/summary.json`: exact exclusions, default patterns, language/category breakdowns, digests, commits, outcomes, and upstream status evidence.
- `tooling/run-scans.mjs`: reproducible wrapper around UA scanner and core APIs.
- `tooling/validate-graphs.mjs`: independent, read-only schema gate for sibling curated graphs.

From Wing root:

```bash
(cd tools/understand-anything && pnpm --version)
(cd tools/understand-anything && pnpm install --frozen-lockfile --ignore-scripts)
(cd tools/understand-anything && pnpm --filter @understand-anything/core build)
node docs/analysis/understand-anything/tooling/run-scans.mjs
node docs/analysis/understand-anything/tooling/validate-graphs.mjs --self-test
node --check docs/analysis/understand-anything/tooling/run-scans.mjs
node --check docs/analysis/understand-anything/tooling/validate-graphs.mjs
```

Install succeeded: 584 packages added, lockfile already current. Dependency lifecycle and root prepare scripts were deliberately suppressed. Explicit `tsc` core build succeeded. Bundled WASM grammars loaded and the selected parsers executed without native rebuilds. pnpm warned that the plugin-level `onlyBuiltDependencies` setting does not take effect; no configuration was changed to silence it.

The wrapper invokes exactly this shipped CLI for each repository (absolute paths are resolved at runtime, not persisted in census output):

```text
node tools/understand-anything/understand-anything-plugin/skills/understand/scan-project.mjs <repository-root> <tooling>/<name>-scan.json --exclude <comma-joined-patterns> --exclude-analysis-data
```

Inspected `scan-project.mjs`, `extract-structure.mjs`, its outcome mapper, core ignore implementation, tree-sitter initialization, Dart config/extractor, and core schema before execution. The scanner accepts an explicit output path; no snapshot or target-local `.ua` was necessary. `extract-structure.mjs` also accepts explicit input/output, but bounded extraction used `PluginRegistry`, `TreeSitterPlugin`, `builtinLanguageConfigs`, `registerAllParsers`, and shipped `analyzeFileWithOutcomes` directly. Output contains actual structural metadata/call entries, never source bodies.

## Exclusions and privacy

Wing additionally excludes `/hermes-agent/`, `/hermes-conduit/`, `/withdrawn source citation`, `/tools/`, and `/docs/analysis/understand-anything/`, so nested repositories, tool installs/builds, and concurrent analysis outputs are not Wing source inputs.

Every scan applies UA defaults (fully listed in `tooling/summary.json`), existing Git ignore rules, and the following explicit patterns:

- `.ua/`
- `.understand-anything/`
- `.hermes/`
- `.smoke/`
- `.pi/`
- `.codex/`
- `.claude/`
- `.agents/`
- `.dart_tool/`
- `.flutter-plugins*`
- `.gradle/`
- `.pub-cache/`
- `Pods/`
- `.symlinks/`
- `node_modules/`
- `build/`
- `dist/`
- `out/`
- `target/`
- `vendor/`
- `third_party/`
- `.venv/`
- `venv/`
- `__pycache__/`
- `.cache/`
- `.pytest_cache/`
- `.mypy_cache/`
- `.ruff_cache/`
- `coverage/`
- `htmlcov/`
- `test-results/`
- `playwright-report/`
- `screenshots/`
- `.env`
- `.env.*`
- `*.env`
- `*.pem`
- `*.key`
- `*.p12`
- `*.pfx`
- `*.keystore`
- `*.jks`
- `*credentials*.json`
- `*credentials*.yaml`
- `*credentials*.yml`
- `*secrets*.json`
- `*secrets*.yaml`
- `*secrets*.yml`
- `*.db`
- `*.sqlite`
- `*.sqlite3`
- `*.db-*`
- `*.sqlite-*`
- `*.log`
- `*.jsonl`
- `*.ndjson`
- `/logs/`
- `/sessions/`
- `/transcripts/`
- `/recordings/`
- `/state/`
- `/runtime/`
- `/profiles/`
- `/memories/`
- `fixtures/`
- `__fixtures__/`
- `testdata/`
- `__snapshots__/`
- `contributors/`
- `*transcript*.json`
- `*session*.json`
- `*state*.json`
- `*.wasm`
- `*.so`
- `*.dylib`
- `*.dll`
- `*.exe`
- `*.bin`
- `*.pyc`
- `*.parquet`
- `*.wav`
- `*.ogg`
- `*.webm`

Root anchoring of runtime/session/profile/state directories avoids accidentally removing production folders such as `lib/features/profiles` and `screens/state`. Fixture directories and contributor metadata are conservatively excluded everywhere; this is not a full test-fixture census. No env/log/database/transcript content was emitted or sampled. Secret/state protection is path-based, not a guarantee that arbitrary misnamed source files can never contain sensitive text. Only bounded structural metadata is emitted for source samples.

UA never wrote into upstream targets: before/after `git status --porcelain=v1 -uall` strings match. Agent and Conduit stayed clean. Desktop's five pre-existing `.claude` deletions were preserved. No ignore files, hooks, or `.ua` directories were created there. Tool install/build writes remain under its checkout; analysis writes remain here.

## Parser evidence and limitations

Every selected sample had successful structure and call-graph outcomes: Wing 24/24, Agent 17/17, Conduit 6/6, Desktop 6/6. Selection is up to three lexically first files per supported tree-sitter language after census exclusions. Non-code parsers were registered, but this smoke test deliberately samples tree-sitter source extensions only. Successful calls are **not** proof that every language construct was extracted or every call resolved.

- Wing has **401 `.dart` files** in its final census. Its three Dart parser samples are Android integration test source files, with real functions/imports extracted. This checkout includes a Dart WASM package and Dart extractor: Dart is not globally unsupported. Scanner labels alone do not establish parser availability; supported parser selection uses core language configs.
- Dart extraction is syntax-shaped, not Dart analyzer/type resolution. Parameter names are flattened across required/named/optional groups; constructor initializer parameters lose types; export visibility is derived from leading underscores. The smoke test does not establish complete handling of modern records, patterns, extensions, mixins, generated Riverpod/localization code, or Flutter runtime behavior across all 401 files.
- UA gracefully degrades missing grammars; a structurally valid empty result can still count as a successful parser outcome. Call entries are lexical evidence, not complete inter-file semantic/runtime relationships. No per-function full-project analysis was performed.
- Language/category detection is rule-based and extension fallback may label an unsupported extension as a language and classify it as code. Census counts must not be mistaken for parser coverage or an architecture graph.
- No graph was manufactured from census entries. Other agents' curated sibling graphs remain independent work.

## Validation executed

```bash
(cd tools/understand-anything && pnpm exec vitest run tests/skill/understand/test_scan_project.test.mjs tests/skill/understand/test_extract_structure_cli.test.mjs tests/skill/understand/test_extract_structure_outcomes.test.mjs)
(cd tools/understand-anything && pnpm --filter @understand-anything/core exec vitest run src/__tests__/schema.test.ts src/plugins/extractors/__tests__/dart-extractor.test.ts src/plugins/extractors/__tests__/swift-extractor.test.ts)
```

Results: **111 tests passed in 3 files** for scanner/extraction CLI/outcomes; **156 tests passed in 3 files** for schema/Dart/Swift. Both commands exited 0. Validator self-test exited 0 and printed `UA core schema loaded; invalid input and noncanonical edge rejection verified. No graph generated.` Both scripts passed `node --check`.

When sibling graphs are available, run:

```bash
node docs/analysis/understand-anything/tooling/validate-graphs.mjs
# Or validate explicit paths:
node docs/analysis/understand-anything/tooling/validate-graphs.mjs docs/analysis/understand-anything/wing-graph.json
```

The validator uses UA's strict `KnowledgeGraphSchema.safeParse` plus `validateGraph`, rejects any automatic correction/drop, and checks duplicate node/layer IDs and layer/tour references. It reads graphs without rewriting them. Missing sibling graphs return exit 2; invalid graphs return exit 1. Actual sibling graph acceptance was intentionally not awaited or claimed.

## Issues encountered

The first repeat check detected a difference because creating the excluded Wing output file between scans changes UA's candidate-based additional-ignore count. The wrapper now materializes that output before the two passes; final four outputs repeated byte-identically. Contributor filename metadata was removed through an explicit exclusion before the final artifact set. No remaining execution blocker. Counts can change when the dirty worktree or concurrently created excluded analysis files change; content digests fingerprint only retained file bytes.
