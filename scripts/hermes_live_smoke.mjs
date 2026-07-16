#!/usr/bin/env node
import process from 'process';

const DEFAULT_BASE_URL = 'http://127.0.0.1:8642';
const DEFAULT_MESSAGE = 'Hermes Wing live smoke: reply with a short acknowledgement.';

function usage() {
  console.log(`Hermes Agent live smoke

Usage:
  HERMES_BASE_URL=http://127.0.0.1:8642 HERMES_API_KEY=... node scripts/hermes_live_smoke.mjs [options]

Options:
  --base-url <url>      Hermes API base URL. Default: HERMES_BASE_URL or ${DEFAULT_BASE_URL}
  --api-key <key>       Bearer API key. Default: HERMES_API_KEY
  --message <text>      Text turn to send. Default: ${DEFAULT_MESSAGE}
  --timeout-ms <n>      SSE/read timeout. Default: 30000
  --stop-smoke          Also POST /v1/runs/{run_id}/stop after starting the run
  --json                Print only JSON summary
`);
}

function readArgs(argv) {
  const options = {
    baseUrl: process.env.HERMES_BASE_URL || DEFAULT_BASE_URL,
    apiKey: process.env.HERMES_API_KEY || '',
    message: DEFAULT_MESSAGE,
    timeoutMs: 30000,
    stopSmoke: false,
    jsonOnly: false,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--help' || arg === '-h') {
      usage();
      process.exit(0);
    }
    if (arg === '--stop-smoke') {
      options.stopSmoke = true;
      continue;
    }
    if (arg === '--json') {
      options.jsonOnly = true;
      continue;
    }
    const next = () => {
      const value = argv[++i];
      if (!value) throw new Error(`Missing value for ${arg}`);
      return value;
    };
    if (arg === '--base-url') options.baseUrl = next();
    else if (arg === '--api-key') options.apiKey = next();
    else if (arg === '--message') options.message = next();
    else if (arg === '--timeout-ms') options.timeoutMs = Number(next());
    else throw new Error(`Unknown option: ${arg}`);
  }
  if (!Number.isFinite(options.timeoutMs) || options.timeoutMs <= 0) {
    throw new Error('--timeout-ms must be a positive number');
  }
  return options;
}

function endpoint(baseUrl, path) {
  const base = new URL(baseUrl);
  const prefix = base.pathname.replace(/\/+$/, '');
  base.pathname = `${prefix}${path}`;
  base.search = '';
  base.hash = '';
  return base;
}

function headers(options, json = false) {
  const result = {};
  if (options.apiKey.trim()) result.Authorization = `Bearer ${options.apiKey.trim()}`;
  if (json) result['Content-Type'] = 'application/json';
  return result;
}

async function requestJson(options, method, path, body) {
  const response = await fetch(endpoint(options.baseUrl, path), {
    method,
    headers: headers(options, body !== undefined),
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`${method} ${path} failed: HTTP ${response.status} ${text.slice(0, 300)}`);
  }
  return text ? JSON.parse(text) : {};
}

function supportsRuns(capabilities) {
  const features = capabilities?.features || {};
  return Boolean(
    features.run_submission &&
      features.run_events_sse &&
      features.run_stop &&
      features.run_approval_response,
  );
}

async function readSse(response, timeoutMs) {
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`SSE request failed: HTTP ${response.status} ${text.slice(0, 300)}`);
  }
  if (!response.body) throw new Error('SSE response did not include a body');

  const events = [];
  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  let currentEvent = 'message';
  let currentData = [];
  let doneSeen = false;
  const deadline = Date.now() + timeoutMs;

  const flush = () => {
    if (currentData.length === 0) {
      currentEvent = 'message';
      return;
    }
    const data = currentData.join('\n');
    events.push({ event: currentEvent, data });
    if (data.trim() === '[DONE]' || currentEvent === 'done') doneSeen = true;
    currentEvent = 'message';
    currentData = [];
  };

  while (!doneSeen && Date.now() < deadline) {
    const remaining = deadline - Date.now();
    const read = reader.read();
    const timeout = new Promise((resolve) => setTimeout(() => resolve('timeout'), remaining));
    const result = await Promise.race([read, timeout]);
    if (result === 'timeout') break;
    if (result.done) break;
    buffer += decoder.decode(result.value, { stream: true });

    while (buffer.includes('\n')) {
      const index = buffer.indexOf('\n');
      const raw = buffer.slice(0, index);
      buffer = buffer.slice(index + 1);
      const line = raw.endsWith('\r') ? raw.slice(0, -1) : raw;
      if (!line) {
        flush();
      } else if (line.startsWith('event:')) {
        currentEvent = line.slice(6).trim() || 'message';
      } else if (line.startsWith('data:')) {
        currentData.push(line.slice(5).trimStart());
      }
    }
  }
  if (buffer.trim()) currentData.push(buffer.trim());
  flush();
  await reader.cancel().catch(() => {});
  return events;
}

async function run(options) {
  const summary = {
    baseUrl: options.baseUrl,
    health: false,
    capabilities: false,
    sessionsListed: false,
    sessionCreated: false,
    transport: 'unknown',
    runStarted: false,
    eventsSeen: [],
    approvalResponded: false,
    stopAccepted: false,
    messagesReloaded: false,
  };

  const health = await requestJson(options, 'GET', '/health');
  summary.health = true;

  const capabilities = await requestJson(options, 'GET', '/v1/capabilities');
  summary.capabilities = true;

  await requestJson(options, 'GET', '/api/sessions');
  summary.sessionsListed = true;

  const sessionId = `navi-smoke-${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const created = await requestJson(options, 'POST', '/api/sessions', {
    id: sessionId,
    title: 'Hermes Wing live smoke',
  });
  const effectiveSessionId = created?.session?.id || sessionId;
  summary.sessionCreated = true;
  summary.sessionId = effectiveSessionId;

  if (supportsRuns(capabilities)) {
    summary.transport = 'runs';
    const run = await requestJson(options, 'POST', '/v1/runs', {
      session_id: effectiveSessionId,
      message: options.message,
    });
    const runId = run?.run?.id || run?.id;
    if (!runId) throw new Error('POST /v1/runs did not return run.id');
    summary.runStarted = true;
    summary.runId = runId;

    if (options.stopSmoke) {
      await requestJson(options, 'POST', `/v1/runs/${encodeURIComponent(runId)}/stop`, {});
      summary.stopAccepted = true;
    }

    const response = await fetch(endpoint(options.baseUrl, `/v1/runs/${encodeURIComponent(runId)}/events`), {
      headers: headers(options),
    });
    const events = await readSse(response, options.timeoutMs);
    summary.eventsSeen = events.map((entry) => entry.event);
    const approval = events.find((entry) => entry.event === 'approval.request');
    if (approval) {
      const data = JSON.parse(approval.data);
      await requestJson(options, 'POST', `/v1/runs/${encodeURIComponent(runId)}/approval`, {
        approval_id: data.approval_id,
        decision: 'deny',
      });
      summary.approvalResponded = true;
    }
    if (events.length === 0) throw new Error('Run event stream produced no events before timeout');
  } else {
    summary.transport = 'session_chat_stream';
    const response = await fetch(
      endpoint(options.baseUrl, `/api/sessions/${encodeURIComponent(effectiveSessionId)}/chat/stream`),
      {
        method: 'POST',
        headers: headers(options, true),
        body: JSON.stringify({ message: options.message }),
      },
    );
    const events = await readSse(response, options.timeoutMs);
    summary.eventsSeen = events.map((entry) => entry.event);
    if (events.length === 0) throw new Error('Session chat stream produced no events before timeout');
  }

  const messages = await requestJson(options, 'GET', `/api/sessions/${encodeURIComponent(effectiveSessionId)}/messages`);
  summary.messagesReloaded = Array.isArray(messages?.data);
  summary.healthStatus = health?.status || 'unknown';
  summary.model = capabilities?.model || capabilities?.platform || 'unknown';
  return summary;
}

try {
  const options = readArgs(process.argv.slice(2));
  const summary = await run(options);
  if (options.jsonOnly) {
    console.log(JSON.stringify(summary));
  } else {
    console.log(JSON.stringify(summary, null, 2));
    console.log('Hermes live smoke passed');
  }
} catch (error) {
  console.error(`Hermes live smoke failed: ${error.message}`);
  process.exit(1);
}
