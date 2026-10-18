# Official Flutter MCP for Wing architecture work

## Scope

Status: Accepted

The owner clarified that the request is to use the official Dart/Flutter MCP
server for architecture work on Hermes Wing, not create an MVP, add app-side AI,
or install the entire supplied list of tools. Acceptance here covers that tooling
purpose; it does not approve unseen refactors or grant live Agent access.

This is developer tooling only. Hermes Agent remains the unmodified authority;
Wing keeps existing Riverpod providers, channel contracts and adaptive UI.

## Observed baseline

- Wing already has AGENTS.md, CONTEXT.md, CONTRIBUTING.md, flutter_lints and
  additional asynchronous/context lints. CI runs format/analyze/tests, coverage
  and browser/native checks. Do not replace these with another quality score.
- Installed Dart is 3.12.2 under the project's Flutter 3.44.2 toolchain.
  `dart mcp-server --help` succeeds. Do not upgrade to the online docs' Flutter
  3.47 baseline just to follow new examples.
- A real temporary stdio MCP session initialized server `dart and flutter
  tooling` version 0.1.4. With `--disable=all` and explicit enablement of
  `analyze_files,lsp,roots`, tools/list exposed only those three tools.
- MCP LSP resolved ManagedSshConnectionController and its provider to their
  actual Dart locations. MCP analyze_files with applyFixes=false returned
  `No errors` for the API channel, SSH controller and connection panel.
  This is scoped static-analysis evidence, not a whole-project pass or proof
  of correct layering, error propagation, runtime behavior or native SSH.
- The managed connector installation request for `dart` was rejected because
  it is not a catalog entry. No persistent server was registered and no Hermes
  configuration was edited. Temporary stdio access is verified; native reusable
  connector availability is not. Both temporary processes were closed afterward.

## Planner decisions

1. Use the SDK's existing official server directly for bounded, read-only code
   intelligence. No package install, in-app bridge, new daemon, or replacement
   backend is needed. Keep the exact worker workspace as the sole project root.
2. Start with the existing SSH channel/controller/presentation boundary. Trace
   ownership, cancellation and failure propagation using MCP symbol locations,
   direct source and the nearest tests. Reuse the prior SSH failure-feedback
   planning instead of creating a second implementation task for the same bug.
3. Produce a short source-backed architecture assessment and at most three
   justified changes. Prefer deletion/reuse of existing seams over new layers,
   framework/state-management migrations or a repository-wide rewrite. Separate
   reproduced behavior from inspected risks and architecture preferences.
4. Keep fixes, formatting, package tools, runtime attachment, app launch, hot
   reload/restart, device enumeration and mutation tools disabled for this audit.
   Always pass applyFixes=false. Do not enable protocol-traffic logging, which
   could retain source/private runtime data. Roots are scope, not an OS sandbox.
5. Existing CLI checks remain the acceptance authority. MCP is another way to
   inspect the project, not permission to skip tests or erase red results.
6. Do not hand-edit MCP configuration or patch Hermes to bypass the catalog.
   If a persistent connection is later needed, use a supported connection-manager
   path when available; report the missing catalog support rather than claim a
   native connection. This does not block temporary official MCP analysis.

## Deliberately not adopted

- Official Flutter agent skills/rules: valid optional references, but no bulk
  import or architecture rewrite. Project ADRs take precedence over generic
  examples. The guessed standalone rules/rules.md URL returned 404; use the
  repository's current directory listing instead of assuming that filename.
- InkPal: its advertised setup can add inkpal_bridge and patch app entrypoints;
  unnecessary for this scoped SDK-tooling request and requires separate review.
- Falcon and community skill packs: no measured gap or compatibility evidence
  justifies another required linter/install. flutter-pro-skills was not identified
  reliably enough to endorse a particular repository.
- flutter_ai_toolkit, flutter-ai-labs and neomage concern app-side AI/UI/agent
  examples. The official flutter_ai_toolkit page describes chat widgets and an
  LLM provider abstraction; it does not substantiate the supplied all-in-one
  RAG/ReAct description. None is a Wing dependency or a new Agent authority.

- dart_agent_core and Genkit Dart: app-side agent frameworks, not replacements
  for the SDK's analyzer/LSP MCP. Adding an agent loop/provider runtime to Wing
  would conflict with its existing Agent authority and is outside this request.
  Genkit's skill is useful when developing Genkit applications, not evidence
  that Wing needs Genkit. See [dart_agent_core](https://pub.dev/packages/dart_agent_core)
  and [official Genkit skills](https://github.com/genkit-ai/skills).
- code_swarm: an external AI review workflow, not static architecture validation.
  Its package describes concurrent provider calls and source review; using it
  would need separate source-sharing and usage-cost approval. Do not follow its
  API-key-in-command-line examples. Existing read-only review delegation is
  sufficient for the bounded review. See [package](https://pub.dev/packages/code_swarm).
- flutter_skill_gen: not adopted. Versioned documentation describes scanning plus
  agent-CLI/background generation, not just a deterministic local context export.
  Generated instructions would need source review, drift handling and protection
  of existing AGENTS/ADRs; no demonstrated gap justifies another generator now.
  See [documented workflow](https://pub.dev/documentation/flutter_skill_gen/1.1.0).

## Sources

Inspected 2026-10-18; upstream documentation is not a compatibility guarantee:

- [Flutter tooling](https://docs.flutter.dev/ai/tools)
- [Official plugins](https://github.com/flutter/agent-plugins)
- [Dart MCP source and tool inventory](https://github.com/dart-lang/ai/tree/main/pkgs/dart_mcp_server)
- [Hermes MCP filtering and configuration](https://hermes-agent.nousresearch.com/docs/reference/mcp-config-reference)
- [Flutter AI Toolkit](https://pub.dev/packages/flutter_ai_toolkit)
- [Wing conventions](../../AGENTS.md), [client ADR](../adr/client.md),
  [required checks](../../CONTRIBUTING.md#required-checks).

Detailed MCP responses stay in private task evidence, not public transcripts or
repository fixtures. This plan authorizes neither implementation nor scheduling.
