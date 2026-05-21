# Navivox TODO

[BLOCKED] Commit/push Transcript surface plan and context updates — 2026-05-20 20:56 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing only plan/context files would add a partial project tree.
  evidence: `git rev-parse --show-toplevel` => `/home/xel/git/sages-openclaw`; `git status --short -- /home/xel/git/sages-openclaw/workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: saved the implementation plan and context wording without staging a partial commit; wait for ownership decision before commit/push.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Run Subagent-Driven Development execution — 2026-05-20 21:02 CST
  blocker: current pi harness has no Agent/subagent dispatch tool, so fresh implementer/spec-review/code-review subagents cannot be launched.
  evidence: available tool surface in this session is file/command tools (`read`, `bash`, `edit`, `write`, `multi_tool_use.parallel`); no Agent/TodoWrite dispatch tool is exposed.
  unblocks when: this work runs in a subagent-capable harness, or Juan approves switching to inline execution.
  owner: harness / Juan
  workaround/pivot: prepared Task 1 subagent dispatch packet at `docs/superpowers/plans/2026-05-20-transcript-surface-task1-subagent-packet.md`.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Commit/push Voice run lifecycle spec — 2026-05-21 08:34 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing the Voice run spec would require adding a partial project tree.
  evidence: `git status --short -- workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: saved design spec at `docs/superpowers/specs/2026-05-20-voice-run-lifecycle-design.md` without staging a partial commit.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Commit/push Voice run lifecycle implementation plan — 2026-05-21 08:39 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing the implementation plan would require adding a partial project tree.
  evidence: `git status --short -- workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: saved implementation plan at `docs/superpowers/plans/2026-05-21-voice-run-lifecycle.md` without staging a partial commit.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Commit/push Voice run lifecycle implementation — 2026-05-21 08:53 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing the validated implementation would require adding a partial project tree.
  evidence: `git status --short -- workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`; full `flutter test` passed locally after the implementation.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: completed and validated the client-local Voice run lifecycle implementation without staging a partial commit.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Commit/push navivox-loop iteration 1 voice failure-reason slice — 2026-05-21 09:01 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing the validated iteration slice would require adding a partial project tree.
  evidence: `git status --short -- workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`; `flutter analyze`, `flutter test`, and `git diff --check -- workspace-mineru/navivox-app` all exited 0 in this iteration.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: completed the timeout failure-reason slice and left it unstaged.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Navivox full gate for Pi delivery-loop extension — 2026-05-21 08:52 CST
  blocker: full repo gate is red from pre-existing Navivox app test/model drift and unrelated root whitespace outside the extension slice.
  evidence: `flutter analyze` reports undefined getter `voiceCapability` in `app/test/core/channel/gateway_navivox_channel_test.dart:149-152`; `flutter test` reports `loads profile contacts from snapshot and applies gateway updates` expected `available`, actual `unavailable`; unscoped `git diff --check` reports trailing whitespace in `.sisyphus/plans/gormes-port-master-plan.md:3` and `:5`.
  unblocks when: Navivox voice capability expectations are reconciled with `NavivoxProfileContact`, and unrelated root whitespace is fixed or excluded by an agreed gate scope.
  owner: Navivox app owner / root workspace owner
  workaround/pivot: completed the extension slice with focused contract test and scoped `git diff --check -- workspace-mineru/navivox-app`; did not modify unrelated app/root WIP.
  next check: 2026-05-21 10:00 CST
