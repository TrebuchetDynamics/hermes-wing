import type { ExtensionAPI, ExtensionCommandContext, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { access, appendFile, mkdir, readFile } from "node:fs/promises";
import { dirname, join, relative, resolve } from "node:path";

const COMMAND_NAME = "navivox-loop";
const PROJECT_NAME = "navivox";
const STATE_ENTRY_TYPE = "navivox-loop-state";
const RECENT_LOG_LIMIT = 12;
const DEFAULT_MAX_ITERATIONS = 3;
const MAX_ALLOWED_ITERATIONS = 10;
const SELF_IMPROVEMENT_ON_FAILURE = false;

const ACTIVE_START_POLICY = "active default start: status-only-no-replace";
const RESTART_POLICY = "restart: explicit-confirm-before-replace";

const REQUIRED_WORKFLOWS = [
	"using-superpowers",
	"test-driven-development",
	"verification-before-completion",
];

type LoopDecision = "continue" | "stop" | "blocked" | "done";

type LoopState = {
	active: boolean;
	topic: string;
	iteration: number;
	maxIterations: number;
	lastDecision: LoopDecision | "idle" | null;
	logPath: string;
	projectRoot: string;
	repoRoot: string;
	branch: string;
	failureCount: number;
};

type RepoPreflight = {
	projectRoot: string;
	repoRoot: string;
	branch: string;
	status: string;
	projectStatus: string;
	ok: boolean;
	error?: string;
};

type ParsedCommand = {
	action: "start" | "restart" | "status" | "stop" | "help";
	topic: string;
	maxIterations: number;
};

let state: LoopState | null = null;

export default function navivoxDeliveryLoop(pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		state = await reconstructState(ctx);
		setLoopStatus(ctx);
	});

	pi.on("session_tree", async (_event, ctx) => {
		state = await reconstructState(ctx);
		setLoopStatus(ctx);
	});

	pi.on("agent_end", async (event, ctx) => {
		const current = await ensureState(ctx);
		if (!current.active) return;

		const assistantText = latestAssistantText(event.messages ?? []);
		const decision = parseFinalDecision(assistantText);
		const ciGreen = hasCiGreen(assistantText);

		if (!decision) {
			await markBlocked(pi, ctx, "assistant_decision_missing", {
				ciGreen,
				finalLine: finalNonEmptyLine(assistantText),
			});
			return;
		}

		current.lastDecision = decision;
		await appendLoopLog(current.logPath, "assistant_decision", {
			iteration: current.iteration,
			decision,
			ciGreen,
			finalLine: finalNonEmptyLine(assistantText),
		});

		if ((decision === "continue" || decision === "done") && !ciGreen) {
			current.failureCount += 1;
			current.active = false;
			current.lastDecision = "blocked";
			persistState(pi, current);
			await appendLoopLog(current.logPath, "ci_gate_missing", {
				iteration: current.iteration,
				decision,
				reason: "continue/done requires CI_GREEN: yes",
			});
			setLoopStatus(ctx);
			await maybeQueueSelfImprovement(pi, current, "ci_gate_missing");
			return;
		}

		if (decision === "blocked") {
			current.failureCount += 1;
			current.active = false;
			persistState(pi, current);
			await appendLoopLog(current.logPath, "blocked", {
				iteration: current.iteration,
				reason: "assistant reported LOOP_DECISION: blocked",
			});
			setLoopStatus(ctx);
			await maybeQueueSelfImprovement(pi, current, "blocked_decision");
			return;
		}

		if (decision === "stop") {
			current.active = false;
			persistState(pi, current);
			await appendLoopLog(current.logPath, "stopped", {
				iteration: current.iteration,
				reason: "assistant reported LOOP_DECISION: stop",
			});
			setLoopStatus(ctx);
			return;
		}

		if (decision === "done") {
			current.active = false;
			persistState(pi, current);
			await appendLoopLog(current.logPath, "done", {
				iteration: current.iteration,
				reason: "assistant reported LOOP_DECISION: done with CI_GREEN: yes",
			});
			setLoopStatus(ctx);
			return;
		}

		if (current.iteration >= current.maxIterations) {
			current.active = false;
			current.lastDecision = "stop";
			persistState(pi, current);
			await appendLoopLog(current.logPath, "stopped", {
				iteration: current.iteration,
				reason: "maxIterations reached after green iteration",
			});
			setLoopStatus(ctx);
			return;
		}

		await queueNextIteration(pi, ctx, current);
	});

	pi.registerCommand("navivox-loop", {
		description: "Run a bounded autonomous Navivox delivery loop",
		handler: async (args, ctx) => {
			const parsed = parseCommand(args);
			const current = await ensureState(ctx);

			if (parsed.action === "help") {
				showStatus(pi, ctx, current, true);
				return;
			}

			if (parsed.action === "status") {
				showStatus(pi, ctx, current, false);
				return;
			}

			if (parsed.action === "stop") {
				if (!current.active) {
					showStatus(pi, ctx, current, false);
					return;
				}
				current.active = false;
				current.lastDecision = "stop";
				persistState(pi, current);
				await appendLoopLog(current.logPath, "stopped", { reason: "user requested /navivox-loop stop" });
				setLoopStatus(ctx);
				showStatus(pi, ctx, current, false);
				return;
			}

			if (parsed.action === "start" && current.active) {
				// ACTIVE_START_POLICY: status-only-no-replace. Do not ask to replace active state.
				showStatus(pi, ctx, current, true, "Loop already active; default start does not replace state.");
				return;
			}

			if (parsed.action === "restart" && current.active) {
				if (!ctx.hasUI) {
					showStatus(
						pi,
						ctx,
						current,
						true,
						"Loop already active; restart requires interactive confirmation before replacing state.",
					);
					return;
				}
				// RESTART_POLICY: explicit-confirm-before-replace.
				const confirmed = await ctx.ui.confirm(
					"Replace active navivox-loop state?",
					"/navivox-loop restart will stop the active loop and start a new bounded state. Continue?",
				);
				if (!confirmed) {
					showStatus(pi, ctx, current, true, "Restart cancelled; active loop state preserved.");
					return;
				}
			}

			await ctx.waitForIdle();
			const preflight = await runRepoPreflight(pi, ctx);
			if (!preflight.ok) {
				const blocked = stateFromPreflight(preflight, parsed);
				blocked.active = false;
				blocked.lastDecision = "blocked";
				state = blocked;
				persistState(pi, blocked);
				await appendLoopLog(blocked.logPath, "blocked", {
					reason: "repo preflight failed",
					error: preflight.error,
				});
				setLoopStatus(ctx);
				showStatus(pi, ctx, blocked, false, `Repo preflight failed: ${preflight.error ?? "unknown error"}`);
				return;
			}

			const nextState = stateFromPreflight(preflight, parsed);
			nextState.active = true;
			nextState.iteration = 0;
			nextState.lastDecision = null;
			nextState.failureCount = 0;
			state = nextState;
			persistState(pi, nextState);
			await appendLoopLog(nextState.logPath, "loop_start", {
				topic: nextState.topic,
				maxIterations: nextState.maxIterations,
				repoRoot: nextState.repoRoot,
				branch: nextState.branch,
				activeStartPolicy: ACTIVE_START_POLICY,
				restartPolicy: RESTART_POLICY,
			});
			setLoopStatus(ctx);
			await queueNextIteration(pi, ctx, nextState);
		},
	});
}

async function ensureState(ctx: ExtensionContext): Promise<LoopState> {
	if (state) return state;
	state = await reconstructState(ctx);
	return state;
}

async function reconstructState(ctx: ExtensionContext): Promise<LoopState> {
	const projectRoot = await findProjectRoot(ctx.cwd);
	let restored = idleState(projectRoot);

	for (const entry of ctx.sessionManager.getBranch()) {
		if (entry.type !== "custom") continue;
		if (entry.customType !== STATE_ENTRY_TYPE) continue;
		const data = entry.data as Partial<LoopState> | undefined;
		if (!data) continue;
		restored = normalizeState({ ...restored, ...data });
	}

	return restored;
}

function persistState(pi: ExtensionAPI, nextState: LoopState) {
	state = normalizeState(nextState);
	pi.appendEntry(STATE_ENTRY_TYPE, state);
}

function idleState(projectRoot: string): LoopState {
	return {
		active: false,
		topic: "Navivox delivery loop",
		iteration: 0,
		maxIterations: DEFAULT_MAX_ITERATIONS,
		lastDecision: "idle",
		logPath: loopLogPath(projectRoot),
		projectRoot,
		repoRoot: projectRoot,
		branch: "unknown",
		failureCount: 0,
	};
}

function normalizeState(input: LoopState): LoopState {
	return {
		...input,
		active: Boolean(input.active),
		iteration: Number.isFinite(input.iteration) ? input.iteration : 0,
		maxIterations: clampIterations(input.maxIterations),
		failureCount: Number.isFinite(input.failureCount) ? input.failureCount : 0,
		logPath: input.logPath || loopLogPath(input.projectRoot),
		lastDecision: input.lastDecision ?? null,
	};
}

function stateFromPreflight(preflight: RepoPreflight, parsed: ParsedCommand): LoopState {
	return normalizeState({
		active: false,
		topic: parsed.topic,
		iteration: 0,
		maxIterations: parsed.maxIterations,
		lastDecision: null,
		logPath: loopLogPath(preflight.projectRoot),
		projectRoot: preflight.projectRoot,
		repoRoot: preflight.repoRoot,
		branch: preflight.branch,
		failureCount: 0,
	});
}

async function runRepoPreflight(pi: ExtensionAPI, ctx: ExtensionContext): Promise<RepoPreflight> {
	const projectRoot = await findProjectRoot(ctx.cwd);
	const repoRootResult = await pi.exec("git", ["rev-parse", "--show-toplevel"], { cwd: projectRoot, timeout: 5000 });
	const branchResult = await pi.exec("git", ["rev-parse", "--abbrev-ref", "HEAD"], { cwd: projectRoot, timeout: 5000 });
	const statusResult = await pi.exec("git", ["status", "--short"], { cwd: projectRoot, timeout: 5000 });

	if (repoRootResult.code !== 0) {
		return {
			projectRoot,
			repoRoot: projectRoot,
			branch: "unknown",
			status: statusResult.stdout,
			projectStatus: "",
			ok: false,
			error: firstError(repoRootResult.stderr, "git rev-parse --show-toplevel failed"),
		};
	}

	const repoRoot = repoRootResult.stdout.trim();
	const projectPath = pathForGit(repoRoot, projectRoot);
	const projectStatusResult = await pi.exec("git", ["status", "--short", "--", projectPath], {
		cwd: repoRoot,
		timeout: 5000,
	});

	return {
		projectRoot,
		repoRoot,
		branch: branchResult.stdout.trim() || "unknown",
		status: statusResult.stdout,
		projectStatus: projectStatusResult.stdout,
		ok: branchResult.code === 0 && statusResult.code === 0 && projectStatusResult.code === 0,
		error:
			branchResult.code === 0 && statusResult.code === 0 && projectStatusResult.code === 0
				? undefined
				: firstError(branchResult.stderr || statusResult.stderr || projectStatusResult.stderr, "git preflight failed"),
	};
}

async function queueNextIteration(pi: ExtensionAPI, ctx: ExtensionContext, current: LoopState) {
	current.iteration += 1;
	current.active = true;
	persistState(pi, current);
	await appendLoopLog(current.logPath, "iteration_queued", {
		iteration: current.iteration,
		topic: current.topic,
		maxIterations: current.maxIterations,
	});
	const recentLogs = await readRecentLogs(current.logPath, RECENT_LOG_LIMIT);
	const prompt = buildIterationPrompt(current, recentLogs);
	setLoopStatus(ctx);
	if (ctx.isIdle()) {
		pi.sendUserMessage(prompt);
	} else {
		pi.sendUserMessage(prompt, { deliverAs: "followUp" });
	}
}

async function markBlocked(pi: ExtensionAPI, ctx: ExtensionContext, reason: string, details: Record<string, unknown>) {
	const current = await ensureState(ctx);
	current.active = false;
	current.lastDecision = "blocked";
	current.failureCount += 1;
	persistState(pi, current);
	await appendLoopLog(current.logPath, "blocked", {
		iteration: current.iteration,
		reason,
		...details,
	});
	setLoopStatus(ctx);
	await maybeQueueSelfImprovement(pi, current, reason);
}

async function maybeQueueSelfImprovement(pi: ExtensionAPI, current: LoopState, reason: string) {
	if (!SELF_IMPROVEMENT_ON_FAILURE) return;
	const recentLogs = await readRecentLogs(current.logPath, RECENT_LOG_LIMIT);
	await appendLoopLog(current.logPath, "self_improvement_queued", { reason, iteration: current.iteration });
	pi.sendUserMessage(buildSelfImprovementPrompt(current, recentLogs, reason), { deliverAs: "followUp" });
}

function buildIterationPrompt(current: LoopState, recentLogs: string[]): string {
	const projectPath = pathForGit(current.repoRoot, current.projectRoot);
	const fullGate = fullCiGate(current);
	const logsBlock = recentLogs.length > 0 ? recentLogs.join("\n") : "(no prior log records)";

	return `Scope lock: target repo ${current.repoRoot}; target project ${current.projectRoot}; branch ${current.branch}; loop iteration ${current.iteration}/${current.maxIterations}.

You are running /navivox-loop, a bounded autonomous delivery loop for Navivox.
Topic: ${current.topic}

Recent loop context:
Latest navivox-loop JSONL log records read from ${current.logPath} (newest ${RECENT_LOG_LIMIT}):
\`\`\`jsonl
${logsBlock}
\`\`\`

Hard requirements for this iteration:
1. Start with a scope lock and repo preflight. Run and report:
   - pwd
   - git rev-parse --show-toplevel
   - git rev-parse --abbrev-ref HEAD
   - git status --short
   - git status --short -- ${projectPath}
2. Preserve unrelated dirty work. Never stage or commit unrelated files. Stage only exact files you changed, and only after checking git status for those paths.
3. Use project-relevant skills/workflows: ${REQUIRED_WORKFLOWS.join(", ")}. If debugging unexpected behavior, use systematic-debugging or diagnose before fixing.
4. Select exactly one high-impact, builder-ready, one vertical slice. Keep it small enough to validate in this iteration.
5. Use test-first or characterization-test-first development. Show the failing test or characterization before implementation.
6. Report exact changed files.
7. Run the full Navivox CI gate before claiming green:
${fullGate.map((cmd) => `   - ${cmd}`).join("\n")}
8. Commit/push only safe changes. If ${projectPath} is still an untracked project tree or unrelated dirty work makes a safe commit impossible, do not stage a partial tree; report the blocker instead.
9. Report commit hash and push status. Use exact wording if skipped: commit: skipped (<reason>); push: skipped (<reason>).
10. Write CI_GREEN: yes only after every full gate command above exits 0 in this iteration. Otherwise write CI_GREEN: no.
11. Final line must be exactly one of:
LOOP_DECISION: continue
LOOP_DECISION: stop
LOOP_DECISION: blocked
LOOP_DECISION: done

Continue only when the repo gate is green and the slice is safely delivered. Never continue on vibes.`;
}

function buildSelfImprovementPrompt(current: LoopState, recentLogs: string[], reason: string): string {
	const extensionPath = join(current.projectRoot, ".pi", "extensions", "navivox-delivery-loop.ts");
	const fullGate = fullCiGate(current);
	return `Scope lock: target repo ${current.repoRoot}; target project ${current.projectRoot}; branch ${current.branch}; self-improvement reason: ${reason}.

Self-improve the /navivox-loop Pi extension reliability after a stopped loop.
Read these files first:
- ${extensionPath}
- ${current.logPath}

Recent loop logs:
\`\`\`jsonl
${recentLogs.join("\n") || "(no prior log records)"}
\`\`\`

Improve exactly one reliability issue in the extension itself. Use test-driven-development or characterization-test-first. Preserve unrelated dirty work. Run the full gate:
${fullGate.map((cmd) => `- ${cmd}`).join("\n")}

Report exact changed files, validation commands, commit hash, and push status. Write CI_GREEN: yes only after the full gate passes. End with exactly one LOOP_DECISION line.`;
}

function fullCiGate(current: LoopState): string[] {
	const projectPath = pathForGit(current.repoRoot, current.projectRoot);
	return [
		`cd ${current.projectRoot}/app && flutter analyze`,
		`cd ${current.projectRoot}/app && flutter test`,
		`cd ${current.repoRoot} && git diff --check -- ${projectPath}`,
	];
}

async function appendLoopLog(logPath: string, event: string, data: Record<string, unknown>) {
	await mkdir(dirname(logPath), { recursive: true });
	const record = {
		timestamp: new Date().toISOString(),
		event,
		...data,
	};
	await appendFile(logPath, `${JSON.stringify(record)}\n`, "utf8");
}

async function readRecentLogs(logPath: string, limit: number): Promise<string[]> {
	try {
		const content = await readFile(logPath, "utf8");
		return content.trim().split(/\r?\n/).filter(Boolean).slice(-limit);
	} catch {
		return [];
	}
}

function parseCommand(args: string): ParsedCommand {
	const tokens = args.trim().split(/\s+/).filter(Boolean);
	const first = tokens[0] ?? "start";
	const known = new Set(["start", "restart", "status", "stop", "help"]);
	const action = (known.has(first) ? first : "start") as ParsedCommand["action"];
	const rest = known.has(first) ? tokens.slice(1) : tokens;
	let maxIterations = DEFAULT_MAX_ITERATIONS;
	const topicParts: string[] = [];

	for (let i = 0; i < rest.length; i += 1) {
		const token = rest[i];
		if (token.startsWith("--max=")) {
			maxIterations = clampIterations(Number(token.slice("--max=".length)));
			continue;
		}
		if (token === "--max" && rest[i + 1]) {
			maxIterations = clampIterations(Number(rest[i + 1]));
			i += 1;
			continue;
		}
		topicParts.push(token);
	}

	return {
		action,
		topic: topicParts.join(" ").trim() || "Select and deliver one high-impact Navivox slice at a time.",
		maxIterations,
	};
}

function clampIterations(value: number): number {
	if (!Number.isFinite(value)) return DEFAULT_MAX_ITERATIONS;
	return Math.max(1, Math.min(MAX_ALLOWED_ITERATIONS, Math.floor(value)));
}

function latestAssistantText(messages: unknown[]): string {
	for (let i = messages.length - 1; i >= 0; i -= 1) {
		const message = messages[i] as { role?: string; content?: unknown };
		if (message?.role !== "assistant") continue;
		return textContent(message.content);
	}
	return "";
}

function textContent(content: unknown): string {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";
	return content
		.filter((block): block is { type: string; text: string } => {
			return Boolean(block && typeof block === "object" && (block as { type?: string }).type === "text");
		})
		.map((block) => block.text)
		.join("\n");
}

function parseFinalDecision(text: string): LoopDecision | undefined {
	const finalLine = finalNonEmptyLine(text);
	const match = finalLine.match(/^LOOP_DECISION: (continue|stop|blocked|done)$/);
	return match?.[1] as LoopDecision | undefined;
}

function hasCiGreen(text: string): boolean {
	return /^CI_GREEN: yes$/m.test(text);
}

function finalNonEmptyLine(text: string): string {
	const lines = text.trim().split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
	return lines[lines.length - 1] ?? "";
}

async function findProjectRoot(start: string): Promise<string> {
	let dir = resolve(start);
	while (true) {
		if ((await exists(join(dir, "app", "pubspec.yaml"))) && (await exists(join(dir, "README.md")))) {
			return dir;
		}
		const parent = dirname(dir);
		if (parent === dir) return resolve(start);
		dir = parent;
	}
}

async function exists(path: string): Promise<boolean> {
	try {
		await access(path);
		return true;
	} catch {
		return false;
	}
}

function loopLogPath(projectRoot: string): string {
	return join(projectRoot, ".pi", `${PROJECT_NAME}-loop`, "logs.jsonl");
}

function pathForGit(repoRoot: string, projectRoot: string): string {
	const rel = relative(repoRoot, projectRoot) || ".";
	return rel.split("\\").join("/");
}

function firstError(stderr: string, fallback: string): string {
	return stderr.trim().split(/\r?\n/).find(Boolean) ?? fallback;
}

function setLoopStatus(ctx: ExtensionContext) {
	if (!ctx.hasUI || !state) return;
	const mode = state.active ? "active" : "idle";
	ctx.ui.setStatus(COMMAND_NAME, `${mode} ${state.iteration}/${state.maxIterations}`);
}

function showStatus(
	pi: ExtensionAPI,
	ctx: ExtensionCommandContext,
	current: LoopState,
	includeHelp: boolean,
	prefix?: string,
) {
	const lines = [
		prefix,
		`/navivox-loop status: ${current.active ? "active" : "idle"}`,
		`iteration: ${current.iteration}/${current.maxIterations}`,
		`topic: ${current.topic}`,
		`lastDecision: ${current.lastDecision ?? "none"}`,
		`logPath: ${current.logPath}`,
		`repoRoot: ${current.repoRoot}`,
		`branch: ${current.branch}`,
	].filter(Boolean) as string[];

	if (includeHelp) {
		lines.push(
			"commands: /navivox-loop, /navivox-loop start, /navivox-loop restart, /navivox-loop status, /navivox-loop stop",
			ACTIVE_START_POLICY,
			RESTART_POLICY,
		);
	}

	const content = lines.join("\n");
	pi.sendMessage({ customType: COMMAND_NAME, content, display: true, details: current });
	if (ctx.hasUI) ctx.ui.notify(content, current.active ? "info" : "warning");
}
