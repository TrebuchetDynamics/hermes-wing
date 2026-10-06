// Simple HTTP server that serves Flutter web build with proper CORS and no-cache
import http from "http";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { handleLifecycle } from './playwright/support/hermes_lifecycle_fixture.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "build/web");
const configuredPort = Number(process.env.PORT ?? 8767);
const port =
  Number.isInteger(configuredPort) &&
  configuredPort > 0 &&
  configuredPort <= 65535
    ? configuredPort
    : 8767;
const defaultHermesPort = port === 65535 ? 8768 : port + 1;
const configuredHermesPort = Number(
  process.env.HERMES_E2E_PORT ?? defaultHermesPort,
);
const hermesPort =
  Number.isInteger(configuredHermesPort) &&
  configuredHermesPort > 0 &&
  configuredHermesPort <= 65535 &&
  configuredHermesPort !== port
    ? configuredHermesPort
    : defaultHermesPort;

const MIME = {
  ".html": "text/html",
  ".js": "application/javascript",
  ".mjs": "application/javascript",
  ".wasm": "application/wasm",
  ".css": "text/css",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".json": "application/json",
  ".otf": "font/otf",
  ".woff2": "font/woff2",
  ".ico": "image/x-icon",
  ".map": "application/json",
};

const hermesState = {
  sessions: [],
  nextSessionNumber: 2,
  nextMessageId: 1,
  nextRunId: 1,
  stopCount: 0,
  decisions: [],
  runs: new Map(),
  presentationMode: false,
  longTranscript: false,
  audioAdvertised: false,
  audioFailure: false,
  spokenTexts: [],
  modelPicker: false,
  modelLocks: [],
  rejectModelLock: false,
  sessionRestoration: null,
  lifecycle: null,
};

function resetHermesState() {
  for (const run of hermesState.runs.values()) run.release?.("reset");
  for (const pending of hermesState.sessionRestoration?.pending.values() ?? []) {
    pending.resolve("reset");
  }
  hermesState.sessionRestoration = null;
  hermesState.lifecycle = null;
  hermesState.sessions = [
    {
      id: "e2e-hermes-session",
      source: "e2e",
      model: "hermes-agent",
      title: "E2E Hermes Session",
      messages: [
        {
          id: "assistant-welcome",
          role: "assistant",
          content: "E2E Hermes is ready.",
        },
      ],
    },
  ];
  hermesState.nextSessionNumber = 2;
  hermesState.nextMessageId = 1;
  hermesState.nextRunId = 1;
  hermesState.stopCount = 0;
  hermesState.decisions = [];
  hermesState.runs.clear();
  hermesState.presentationMode = false;
  hermesState.longTranscript = false;
  hermesState.audioAdvertised = false;
  hermesState.audioFailure = false;
  hermesState.spokenTexts = [];
  hermesState.modelPicker = false;
  hermesState.modelLocks = [];
  hermesState.rejectModelLock = false;
}

function silentWavDataUrl() {
  const bytes = Buffer.alloc(46);
  bytes.write("RIFF", 0);
  bytes.writeUInt32LE(38, 4);
  bytes.write("WAVEfmt ", 8);
  bytes.writeUInt32LE(16, 16);
  bytes.writeUInt16LE(1, 20);
  bytes.writeUInt16LE(1, 22);
  bytes.writeUInt32LE(8000, 24);
  bytes.writeUInt32LE(16000, 28);
  bytes.writeUInt16LE(2, 32);
  bytes.writeUInt16LE(16, 34);
  bytes.write("data", 36);
  bytes.writeUInt32LE(2, 40);
  return `data:audio/wav;base64,${bytes.toString("base64")}`;
}

resetHermesState();

async function readJsonBody(req) {
  let body = "";
  for await (const chunk of req) body += chunk;
  return body ? JSON.parse(body) : {};
}

function json(res, status, body) {
  const data = Buffer.from(JSON.stringify(body));
  res.writeHead(status, {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "Authorization, Content-Type, Idempotency-Key",
    "Access-Control-Allow-Methods": "GET,POST,PATCH,DELETE,OPTIONS",
    "Cache-Control": "no-store",
    "Content-Length": data.length,
  });
  res.end(data);
}

function findHermesSession(id) {
  return hermesState.sessions.find((session) => session.id === id);
}

function sessionMetadata({ messages, ...session }) {
  return { ...session, message_count: messages.length,
    preview: messages.at(-1)?.content ?? "" };
}

function restorationReceipt() {
  const state = hermesState.sessionRestoration;
  if (!state) return { synthetic: false };
  return {
    synthetic: true,
    session_ids: hermesState.sessions.map(session => session.id),
    metadata_mode: state.metadataMode,
    list_pages: state.listPages,
    metadata_reads: state.metadataReads,
    message_reads: state.messageReads,
    pending: [...state.pending.keys()],
    mutations: state.mutations,
    counters: { lists: state.listPages.length, metadata: state.metadataReads.length,
      messages: state.messageReads.length, mutations: state.mutations.length },
  };
}

async function handleHermesApi(req, res, url) {
  if (req.method === "OPTIONS") return json(res, 204, {});
  const lifecycleHandled = await handleLifecycle(req, res, url, hermesState,
    json, readJsonBody, resetHermesState);
  if (lifecycleHandled !== false) return lifecycleHandled;
  if (req.method === "POST" && url === "/e2e/hermes/reset") {
    resetHermesState();
    return json(res, 200, { reset: true });
  }
  // Test-only fixed synthetic inventory and explicit read gates, never Agent routes.
  if (req.method === "POST" && url === "/e2e/hermes/session-restoration") {
    resetHermesState();
    hermesState.sessions = Array.from({ length: 60 }, (_, index) => {
      const suffix = String(index).padStart(3, "0");
      const id = `synthetic-restoration-${suffix}`;
      return { id, source: "e2e", model: "hermes-agent",
        title: `Synthetic conversation ${suffix}`,
        messages: [{ id: `${id}-canonical`, role: "assistant",
          content: `Canonical history for ${id}.` }] };
    });
    hermesState.sessionRestoration = { metadataMode: "immediate", pending: new Map(),
      listPages: [], metadataReads: [], messageReads: [], mutations: [] };
    return json(res, 200, restorationReceipt());
  }
  if (req.method === "GET" && url === "/e2e/hermes/session-restoration") {
    return json(res, 200, restorationReceipt());
  }
  if (req.method === "POST" && url === "/e2e/hermes/session-restoration/metadata") {
    const state = hermesState.sessionRestoration;
    if (!state) return json(res, 409, { error: "scenario not seeded" });
    const body = await readJsonBody(req);
    if (["park", "immediate"].includes(body.action) && body.request_id == null) {
      state.metadataMode = body.action;
    } else if (["release", "fail"].includes(body.action) &&
        Number.isInteger(body.request_id) && state.pending.has(body.request_id)) {
      state.pending.get(body.request_id).resolve(body.action);
    } else {
      return json(res, 400, { error: "invalid metadata control" });
    }
    return json(res, 200, restorationReceipt());
  }
  const restoration = hermesState.sessionRestoration;
  if (restoration && /^(\/api\/|\/v1\/)/.test(url) &&
      ["POST", "PATCH", "DELETE", "PUT"].includes(req.method)) {
    if (restoration.mutations.length >= 256) return json(res, 409, { error: "fixture bound" });
    // Record attempted mutations, including unsupported routes, but never their bodies.
    restoration.mutations.push({ method: req.method, path: url });
  }
  if (req.method === "POST" && url === "/e2e/hermes/audio") {
    const body = await readJsonBody(req);
    hermesState.audioAdvertised = body.enabled === true;
    hermesState.audioFailure = body.fail === true;
    return json(res, 200, {
      enabled: hermesState.audioAdvertised,
      fail: hermesState.audioFailure,
    });
  }
  if (req.method === "GET" && url === "/e2e/hermes/audio") {
    return json(res, 200, { spokenTexts: hermesState.spokenTexts });
  }
  if (req.method === "POST" && url === "/e2e/hermes/model-picker") {
    resetHermesState();
    hermesState.modelPicker = true;
    hermesState.rejectModelLock = true;
    return json(res, 200, { synthetic: true, selectable: 303 });
  }
  if (req.method === "GET" && url === "/e2e/hermes/model-picker") {
    return json(res, 200, { synthetic: true, locks: hermesState.modelLocks,
      selected: hermesState.sessions[0].runtime ?? null });
  }
  if (req.method === "GET" && url === "/api/model/options" && hermesState.modelPicker) {
    return json(res, 200, { provider: "beta", model: "shared", providers: [
      ...["alpha", "beta", "gamma"].map(slug => ({
        slug, label: `Display ${slug}`, authenticated: true,
        models: ["shared", ...Array.from({ length: 100 }, (_, i) => `${slug}/model-${i}`)],
      })),
      { slug: "unconfigured", label: "Forbidden", models: ["shared", "hidden"] },
    ] });
  }
  if (req.method === "POST" && url === "/api/sessions/e2e-hermes-session/model" && hermesState.modelPicker) {
    const { provider, model } = await readJsonBody(req);
    if (!["alpha", "beta", "gamma"].includes(provider) ||
        !(model === "shared" || Array.from({ length: 100 }, (_, i) => `${provider}/model-${i}`).includes(model))) {
      return json(res, 400, { error: "synthetic invalid identity" });
    }
    hermesState.modelLocks.push({ provider, model });
    if (hermesState.rejectModelLock) {
      hermesState.rejectModelLock = false;
      return json(res, 409, { error: "synthetic rejection" });
    }
    const runtime = { provider, model, model_lock: "accepted", route_source: "session" };
    hermesState.sessions[0].runtime = runtime;
    hermesState.sessions[0].model = model;
    return json(res, 200, { session_id: "e2e-hermes-session", runtime });
  }
  if (req.method === "POST" && url === "/e2e/hermes/presentation") {
    resetHermesState();
    hermesState.presentationMode = true;
    hermesState.sessions[0].title = "Gateway readiness";
    hermesState.sessions[0].messages[0].content =
      "Hermes is connected and ready.";
    return json(res, 200, { seeded: true });
  }
  // Fixed, synthetic transcript scenarios; no caller-provided content or paths.
  if (req.method === "POST" && url === "/e2e/hermes/long-transcript") {
    const body = await readJsonBody(req);
    if (![250, 1000].includes(body.count)) return json(res, 400, { error: "invalid count" });
    resetHermesState();
    hermesState.sessions[0].messages = Array.from({ length: body.count }, (_, i) => ({
      id: `synthetic-${i}`, role: i % 2 ? "assistant" : "user",
      content: `Synthetic loaded turn ${i}`,
    }));
    hermesState.longTranscript = true;
    return json(res, 200, { synthetic: true, count: body.count });
  }
  if (req.method === "POST" && url === "/e2e/hermes/append-transcript") {
    const session = hermesState.sessions[0];
    if (session.messages.length > 1100) return json(res, 409, { error: "fixture bound" });
    const i = session.messages.length;
    session.messages.push({ id: `synthetic-${i}`, role: "assistant", content: `Synthetic loaded turn ${i}` });
    return json(res, 200, { synthetic: true, count: session.messages.length });
  }
  if (req.method === "GET" && url === "/e2e/hermes/stop-count") {
    return json(res, 200, { stopCount: hermesState.stopCount });
  }
  if (req.method === "GET" && url === "/e2e/hermes/run-count") {
    return json(res, 200, { runCount: hermesState.runs.size });
  }
  if (req.method === "GET" && url === "/e2e/hermes/decisions") {
    return json(res, 200, { decisions: hermesState.decisions });
  }
  if (req.method === "GET" && url === "/health") {
    return json(res, 200, { status: "ok", platform: "hermes-agent" });
  }
  if (req.method === "GET" && url === "/health/detailed") {
    return json(res, 200, {
      status: "ok",
      platform: "hermes-agent",
      version: "0.16.0",
      gateway_state: "running",
      active_agents: 0,
    });
  }
  if (req.method === "GET" && url === "/v1/capabilities") {
    return json(res, 200, {
      object: "hermes.api_server.capabilities",
      schema_version: 1,
      platform: "hermes-agent",
      model: "hermes-agent",
      ...(hermesState.lifecycle ? { profile_context: { type: 'query', name: 'profile',
        required: true, default_profile_id: 'default' } } : {}),
      auth: {
        type: "bearer",
        required: false,
        granted_scopes: ["gateway:read", "tasks:read"],
      },
      features: {
        session_chat_streaming: true,
        run_submission: true,
        run_status: true,
        run_events_sse: true,
        run_stop: true,
        run_approval_response: true,
        tool_progress_events: true,
        audio_api: hermesState.audioAdvertised,
        realtime_voice: false,
      },
      endpoints: {
        health_detailed: {
          method: "GET",
          path: "/health/detailed",
          required_scopes: ["gateway:read"],
        },
        sessions: { method: "GET", path: "/api/sessions" },
        session: { method: "GET", path: "/api/sessions/{session_id}" },
        session_create: { method: "POST", path: "/api/sessions" },
        session_messages: {
          method: "GET",
          path: "/api/sessions/{session_id}/messages",
        },
        session_chat_stream: {
          method: "POST",
          path: "/api/sessions/{session_id}/chat/stream",
        },
        session_update: { method: "PATCH", path: "/api/sessions/{session_id}" },
        session_delete: {
          method: "DELETE",
          path: "/api/sessions/{session_id}",
        },
        session_fork: {
          method: "POST",
          path: "/api/sessions/{session_id}/fork",
        },
        models: { method: "GET", path: "/v1/models" },
        ...(hermesState.modelPicker ? {
          model_options: { method: "GET", path: "/api/model/options" },
          session_model_lock: { method: "POST", path: "/api/sessions/{session_id}/model",
            ...(hermesState.lifecycle?.scenario === 'desktop-daily' ? { profile_scoped: true } : {}) },
        } : {}),
        skills: { method: "GET", path: "/v1/skills" },
        toolsets: { method: "GET", path: "/v1/toolsets" },
        jobs: {
          method: "GET",
          path: "/api/jobs",
          required_scopes: ["tasks:read"],
        },
        runs: { method: "POST", path: "/v1/runs" },
        run_status: { method: "GET", path: "/v1/runs/{run_id}" },
        run_events: { method: "GET", path: "/v1/runs/{run_id}/events" },
        run_approval: { method: "POST", path: "/v1/runs/{run_id}/approval" },
        run_stop: { method: "POST", path: "/v1/runs/{run_id}/stop" },
        ...(hermesState.audioAdvertised
          ? {
              audio_speak: {
                method: "POST",
                path: "/api/audio/speak",
              },
            }
          : {}),
      },
    });
  }
  if (req.method === "POST" && url === "/api/audio/speak") {
    if (!hermesState.audioAdvertised) {
      return json(res, 404, { error: "audio unavailable" });
    }
    const body = await readJsonBody(req);
    hermesState.spokenTexts.push(String(body.text ?? ""));
    if (hermesState.audioFailure) {
      return json(res, 500, { error: "synthetic audio failure" });
    }
    return json(res, 200, { data_url: silentWavDataUrl() });
  }
  if (req.method === "GET" && url === "/v1/models") {
    return json(res, 200, {
      object: "list",
      data: [{ id: "hermes-agent", owned_by: "hermes" }],
    });
  }
  if (req.method === "GET" && url === "/v1/skills") {
    return json(res, 200, {
      object: "list",
      data: [
        {
          name: "github",
          description: "GitHub workflow skill",
          category: "github",
        },
        {
          name: "ascii-art",
          description: "ASCII art generation",
          category: "creative",
        },
      ],
    });
  }
  if (req.method === "GET" && url === "/v1/toolsets") {
    return json(res, 200, {
      object: "list",
      platform: "api_server",
      data: [
        {
          name: "default",
          label: "Default Tools",
          enabled: true,
          configured: true,
          tools: ["read_file"],
        },
        {
          name: "web",
          label: "Web Tools",
          enabled: false,
          configured: true,
          tools: ["web_search"],
        },
      ],
    });
  }
  if (req.method === "GET" && url === "/api/jobs") {
    return json(res, 200, {
      jobs: [
        {
          id: "job_1",
          name: "Morning check",
          enabled: true,
          state: "scheduled",
          schedule_display: "Every day at 09:00",
        },
      ],
    });
  }
  if (req.method === "GET" && url === "/api/sessions") {
    const query = new URL(req.url, "http://fixture.invalid").searchParams;
    const limit = Number(query.get("limit") ?? 50);
    const offset = Number(query.get("offset") ?? 0);
    if (!Number.isInteger(limit) || limit < 1 || limit > 200 ||
        !Number.isInteger(offset) || offset < 0 || offset > 1000000) {
      return json(res, 400, { error: "invalid session page" });
    }
    const data = hermesState.sessions.slice(offset, offset + limit).map(sessionMetadata);
    if (restoration) {
      if (restoration.listPages.length >= 256) return json(res, 409, { error: "fixture bound" });
      restoration.listPages.push({ offset, limit, ids: data.map(session => session.id) });
    }
    return json(res, 200, {
      object: "list",
      limit, offset, has_more: offset + limit < hermesState.sessions.length,
      data,
    });
  }
  if (req.method === "POST" && url === "/api/sessions") {
    const body = await readJsonBody(req);
    const session = {
      id: body.id || `e2e-hermes-session-${hermesState.nextSessionNumber}`,
      source: "e2e",
      model: "hermes-agent",
      title: `E2E Hermes Session ${hermesState.nextSessionNumber++}`,
      messages: [],
    };
    hermesState.sessions.push(session);
    const { messages, ...wireSession } = session;
    return json(res, 200, { object: "hermes.session", session: wireSession });
  }
  const sessionMatch = url.match(/^\/api\/sessions\/([^/]+)$/);
  if (req.method === "GET" && sessionMatch) {
    const id = decodeURIComponent(sessionMatch[1]);
    const session = findHermesSession(id);
    let read;
    if (restoration) {
      if (restoration.metadataReads.length >= 256) return json(res, 409, { error: "fixture bound" });
      read = { request_id: restoration.metadataReads.length + 1,
        session_id: id, profile: new URL(req.url, "http://fixture.invalid").searchParams.get("profile"),
        status: "reading" };
      restoration.metadataReads.push(read);
      if (restoration.metadataMode === "park" && session) {
        const outcome = await new Promise(resolve => {
          restoration.pending.set(read.request_id, { resolve });
          res.once("close", () => resolve("closed"));
        });
        restoration.pending.delete(read.request_id);
        if (outcome === "closed" || res.destroyed) { read.status = "closed"; return; }
        if (outcome === "fail" || outcome === "reset") {
          read.status = outcome === "fail" ? "failed" : "reset";
          return json(res, 503, { error: { code: "synthetic_metadata_failure",
            message: "Synthetic metadata read unavailable" } });
        }
      }
      read.status = session ? "completed" : "not_found";
    }
    if (!session) return json(res, 404, { error: { code: "session_not_found",
      message: "session not found" } });
    return json(res, 200, { object: "hermes.session", session: sessionMetadata(session) });
  }
  if (req.method === "DELETE" && sessionMatch) {
    const sessionId = decodeURIComponent(sessionMatch[1]);
    const before = hermesState.sessions.length;
    hermesState.sessions = hermesState.sessions.filter(
      (session) => session.id !== sessionId,
    );
    return json(res, 200, {
      object: "hermes.session.deleted",
      id: sessionId,
      deleted: hermesState.sessions.length < before,
    });
  }
  if (req.method === "PATCH" && sessionMatch) {
    const session = findHermesSession(decodeURIComponent(sessionMatch[1]));
    if (!session)
      return json(res, 404, { error: { message: "session not found" } });
    const body = await readJsonBody(req);
    if (Object.hasOwn(body, "title")) session.title = String(body.title ?? "");
    const { messages, ...wireSession } = session;
    return json(res, 200, { object: "hermes.session", session: wireSession });
  }
  const forkMatch = url.match(/^\/api\/sessions\/([^/]+)\/fork$/);
  if (req.method === "POST" && forkMatch) {
    const source = findHermesSession(decodeURIComponent(forkMatch[1]));
    if (!source)
      return json(res, 404, { error: { message: "session not found" } });
    const body = await readJsonBody(req);
    const fork = {
      id: body.id || `e2e-hermes-session-${hermesState.nextSessionNumber}`,
      source: "e2e",
      model: source.model,
      title: body.title || `${source.title} fork`,
      parent_session_id: source.id,
      messages: source.messages.map((message) => ({ ...message })),
    };
    hermesState.sessions.push(fork);
    const { messages, ...wireSession } = fork;
    return json(res, 201, { object: "hermes.session", session: wireSession });
  }
  const messagesMatch = url.match(/^\/api\/sessions\/([^/]+)\/messages$/);
  if (req.method === "GET" && messagesMatch) {
    const session = findHermesSession(decodeURIComponent(messagesMatch[1]));
    if (!session)
      return json(res, 404, { error: { message: "session not found" } });
    if (restoration) {
      if (restoration.messageReads.length >= 256) return json(res, 409, { error: "fixture bound" });
      restoration.messageReads.push({ session_id: session.id,
        message_ids: session.messages.map(message => message.id) });
    }
    const query = new URL(req.url, 'http://fixture.invalid').searchParams;
    const offset = hermesState.longTranscript ? Number(query.get('offset') ?? 0) : 0;
    const limit = hermesState.longTranscript ? Number(query.get('limit') ?? 500) : 500;
    if (!Number.isInteger(offset) || offset < 0 || offset > 2000 ||
        !Number.isInteger(limit) || limit < 1 || limit > 500) return json(res, 400, { error: 'invalid page' });
    const end = session.messages.length - offset;
    const page = hermesState.longTranscript
      ? session.messages.slice(Math.max(0, end - limit), Math.max(0, end)) : session.messages;
    return json(res, 200, {
      object: "list",
      session_id: session?.id ?? "",
      pagination: { offset, limit, order: 'latest' },
      data: page.map((message) => ({
        id: message.id,
        session_id: session.id,
        role: message.role,
        content: message.content,
      })),
    });
  }
  if (req.method === "POST" && url === "/v1/runs") {
    const body = await readJsonBody(req);
    const session = findHermesSession(body.session_id);
    const runId = `run_${hermesState.nextRunId++}`;
    const presentation = hermesState.presentationMode;
    const reply = presentation
      ? "Gateway is healthy. Profiles, skills, and toolsets are ready."
      : `Hermes echo: ${body.message}`;
    if (session) {
      session.messages.push({
        id: `msg_${hermesState.nextMessageId++}`,
        role: "user",
        content: body.message,
      });
    }
    hermesState.runs.set(runId, {
      id: runId,
      session_id: body.session_id,
      reply,
      approval_id: `approval_${runId}`,
      presentation,
      status: "running",
      release: null,
    });
    return json(res, 200, {
      object: "hermes.run",
      run: { id: runId, session_id: body.session_id },
    });
  }
  const runStatusMatch = url.match(/^\/v1\/runs\/([^/]+)$/);
  if (req.method === "GET" && runStatusMatch) {
    const run = hermesState.runs.get(decodeURIComponent(runStatusMatch[1]));
    if (!run) return json(res, 404, { error: { message: "run not found" } });
    return json(res, 200, {
      object: "hermes.run",
      run_id: run.id,
      session_id: run.session_id,
      status: run.status,
      ...(run.status === "completed" ? { output: run.reply } : {}),
    });
  }
  const runEventsMatch = url.match(/^\/v1\/runs\/([^/]+)\/events$/);
  if (req.method === "GET" && runEventsMatch) {
    const run = hermesState.runs.get(decodeURIComponent(runEventsMatch[1]));
    if (!run) return json(res, 404, { error: { message: "run not found" } });
    res.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Access-Control-Allow-Origin": "*",
      "Cache-Control": "no-store",
    });
    res.write(
      `event: approval.request\ndata: ${JSON.stringify({
        run_id: run.id,
        command: "echo e2e",
        description: "Approve e2e browser run?",
        choices: ["once", "session", "always", "deny"],
      })}\n\n`,
    );
    const decision = await new Promise((resolve) => {
      if (!run) return resolve("missing");
      run.release = resolve;
      res.once("close", () => resolve("closed"));
    });
    if (res.writableEnded || decision === "closed") return;
    if (decision === "stop" || decision === "reset" || decision === "deny") {
      if (run) run.status = "cancelled";
      res.end(
        `event: run.cancelled\ndata: ${JSON.stringify({ run_id: run.id, session_id: run.session_id, status: 'cancelled' })}\n\n` +
          `data: [DONE]\n\n`,
      );
      return;
    }
    const session = findHermesSession(run?.session_id);
    if (session) {
      session.messages.push({
        id: `msg_${hermesState.nextMessageId++}`,
        role: "assistant",
        content: run.reply,
      });
    }
    const tool = run?.presentation ? "read_file" : "bash";
    const toolPreview = run?.presentation
      ? "health + capabilities"
      : "echo e2e";
    const toolResult = run?.presentation
      ? "Gateway checks complete"
      : "tool complete";
    if (run) run.status = "completed";
    res.end(
      `event: tool.started\ndata: ${JSON.stringify({
        tool,
        preview: toolPreview,
      })}\n\n` +
        `event: tool.completed\ndata: ${JSON.stringify({
          tool,
          result_text: toolResult,
        })}\n\n` +
        `event: message.delta\ndata: ${JSON.stringify({ delta: run?.reply ?? "" })}\n\n` +
        `event: run.completed\ndata: ${JSON.stringify({ status: "completed" })}\n\n` +
        `data: [DONE]\n\n`,
    );
    return;
  }
  const runActionMatch = url.match(/^\/v1\/runs\/([^/]+)\/(approval|stop)$/);
  if (req.method === "POST" && runActionMatch) {
    const body = await readJsonBody(req);
    const run = hermesState.runs.get(decodeURIComponent(runActionMatch[1]));
    if (!run) return json(res, 404, { error: { message: "run not found" } });
    const action = runActionMatch[2];
    if (action === "stop") {
      hermesState.stopCount += 1;
      run.status = 'cancelled';
    } else {
      const decision = body.choice ?? body.decision;
      if (!["once", "session", "always", "deny"].includes(decision)) {
        return json(res, 400, {
          error: { message: "invalid approval choice" },
        });
      }
      if (!run.release) {
        return json(res, 409, { error: { message: "approval not active" } });
      }
      hermesState.decisions.push(decision);
      run.release(decision);
      return json(res, 200, {});
    }
    run?.release?.("stop");
    return json(res, 200, {});
  }
  return false;
}

function safeStaticFilePath(requestPath) {
  let decoded;
  try {
    decoded = decodeURIComponent(requestPath);
  } catch {
    return null;
  }
  if (decoded.includes("\0")) return null;

  const relativeRequestPath = decoded.replace(/^[/\\]+/, "");
  if (relativeRequestPath.split(/[\\/]/).includes("..")) return null;

  const filePath = path.normalize(`${root}/${relativeRequestPath}`);
  const relativePath = path.relative(root, filePath);
  if (
    relativePath === ".." ||
    relativePath.startsWith(`..${path.sep}`) ||
    path.isAbsolute(relativePath)
  ) {
    return null;
  }
  return filePath;
}

const server = http.createServer(async (req, res) => {
  try {
    let url = req.url.split("?")[0];
    const handled = await handleHermesApi(req, res, url);
    if (handled !== false) return;
    if (url === "/") url = "/index.html";

    const filePath = safeStaticFilePath(url);
    const relativePath =
      filePath === null ? ".." : path.relative(root, filePath);

    // Security: reject malformed or out-of-root paths before filesystem access.
    if (
      filePath === null ||
      relativePath === ".." ||
      relativePath.startsWith(`..${path.sep}`) ||
      path.isAbsolute(relativePath)
    ) {
      res.writeHead(403);
      res.end("Forbidden");
      return;
    }

    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end("Not Found");
        return;
      }

      const ext = path.extname(filePath);
      res.writeHead(200, {
        "Content-Type": MIME[ext] || "application/octet-stream",
        "Access-Control-Allow-Origin": "*",
        "Cache-Control": "no-store, no-cache, must-revalidate",
        Pragma: "no-cache",
        Expires: "0",
        "Content-Length": data.length,
      });
      res.end(data);
    });
  } catch {
    if (!res.headersSent) {
      json(res, 400, { error: { message: "Invalid JSON request body" } });
    } else {
      res.destroy();
    }
  }
});

const hermesServer = http.createServer(async (req, res) => {
  try {
    const url = req.url.split("?")[0];
    const handled = await handleHermesApi(req, res, url);
    if (handled === false) {
      json(res, 404, { error: { message: "not found" } });
    }
  } catch {
    if (!res.headersSent) {
      json(res, 400, { error: { message: "Invalid JSON request body" } });
    } else {
      res.destroy();
    }
  }
});

server.listen(port, "127.0.0.1", () => {
  console.log(`Server running at http://127.0.0.1:${port}/`);
});
hermesServer.listen(hermesPort, "127.0.0.1", () => {
  console.log(`Hermes API running at http://127.0.0.1:${hermesPort}/`);
});
