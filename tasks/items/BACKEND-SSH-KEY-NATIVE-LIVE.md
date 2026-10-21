+++
schema = 1
id = "BACKEND-SSH-KEY-NATIVE-LIVE"
title = "Live checks for BACKEND-SSH-KEY-NATIVE"
short = "Live checks for BACKEND-SSH-KEY-NATIVE"
status = "open"
goal = "REMOTE-BACKENDS"
section = "Needs decision"
rank = 46000
depends_on = ["BACKEND-SSH-KEY-NATIVE"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for BACKEND-SSH-KEY-NATIVE left pending."
acceptance = ["Each check passes on the real target: - Full-app qualification remains open. Provide the approved host, independently reviewed fingerprint, permitted SSH authentication and separate Agent credential through an approved secret channel; none was supplied with this invocation. Do not infer authorization for provider spending or personal-runtime changes."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](../../docs/product/hermes-desktop-parity.md#statuses), [retained offline task history](../../todo.archive.md).
- Native Linux: execute the production managed form with isolated app state against the approved host; independently record reachability, host trust, SSH authentication, Agent authentication/denial, exact profile/model/history reads, disconnect and explicit reconnect without mutation replay. All cells remain NOT_CHECKED.
- Native Android: provide an explicitly approved disposable app/device and route, then independently execute the same production managed-form acceptance cells. Dry-run placeholder serial and ADB-reverse preparation do not qualify actual Android reachability. All cells remain NOT_CHECKED. - On each native platform, exercise denied/replaced client keys, changed host fingerprint rejection and cancellation during document selection, host review and bootstrap, including late-result rejection. Python fixture rejection is not a full-app result. - On each native platform, qualify generated-key secure-storage denial, public-only native clipboard, deliberate saved-key reuse and unchanged public identity after an actual process exit/relaunch retaining only owned isolated app state. Same-process reconnects and substituted storage do not qualify these cells. - Qualify real Linux chooser and Android document selection independently, including cancellation, revoked/unreadable input, bounded/malformed inputs and encrypted-key recovery. Existing harness substitutes document acquisition and excludes physical storage/chooser/encrypted-key qualification. - Before a later native fixture execution, reconcile the reusable launcher's scratch source-copy/SDK-copy preparation with the execution environment's worktree-only scratch-copy and shared-SDK rules. The --run path was not invoked or modified here; retain source/artifact-bound sanitized fixture receipts separately from approved-host evidence.
- Touches: none before conversion; ** stands for the whole repository
