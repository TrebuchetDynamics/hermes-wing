// Isolated daily-workflow projection of the shared deterministic fixture.
// Only inventory visibility changes; exact metadata, history and lifecycle state
// remain authoritative in serve_web.mjs. This is never a live Agent proxy.
import http from 'node:http';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const sessionId = 'e2e-hermes-session';
const lifecyclePath = '/e2e/hermes/lifecycle';
const receiptBound = 128;
const bodyBound = 1024 * 1024;
const configuredPort = Number(process.env.PORT ?? 8767);
const port = validPort(configuredPort) ? configuredPort : 8767;
const defaultHermesPort = port === 65535 ? 8768 : port + 1;
const configuredHermesPort = Number(process.env.HERMES_E2E_PORT ?? defaultHermesPort);
const hermesPort = validPort(configuredHermesPort) && configuredHermesPort !== port
  ? configuredHermesPort : defaultHermesPort;
let restoration = null;
let backend;
let stopping = false;
const servers = [];

function validPort(value) {
  return Number.isInteger(value) && value > 0 && value <= 65535;
}

function json(res, status, body) {
  const data = Buffer.from(JSON.stringify(body));
  res.writeHead(status, {
    'Content-Type': 'application/json', 'Content-Length': data.length,
    'Cache-Control': 'no-store', 'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type, Idempotency-Key',
    'Access-Control-Allow-Methods': 'GET,POST,PATCH,DELETE,OPTIONS',
  });
  res.end(data);
}

async function listen(server, listenPort) {
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(listenPort, '127.0.0.1', () => {
      server.removeListener('error', reject);
      resolve();
    });
  });
}

async function shutdown(code) {
  if (stopping) return;
  stopping = true;
  for (const server of servers) {
    server.close();
    server.closeAllConnections();
  }
  if (backend && backend.exitCode === null && backend.signalCode === null) {
    await new Promise(resolve => {
      const force = setTimeout(() => backend.kill('SIGKILL'), 2000);
      backend.once('exit', () => { clearTimeout(force); resolve(); });
      backend.kill('SIGTERM');
    });
  }
  process.exit(code);
}

process.once('SIGTERM', () => void shutdown(143));
process.once('SIGINT', () => void shutdown(130));

function proxy(req, res, backendPort) {
  const url = new URL(req.url, 'http://fixture.invalid');
  const path = url.pathname;
  const inventory = restoration && req.method === 'GET' && path === '/api/sessions';
  const metadataMatch = path.match(/^\/api\/sessions\/([^/]+)$/);
  const metadata = restoration && req.method === 'GET' && metadataMatch;
  const receipt = path === lifecyclePath || path.startsWith(`${lifecyclePath}/`);
  const reset = req.method === 'POST' && [
    '/e2e/hermes/reset', '/e2e/hermes/model-picker',
    '/e2e/hermes/session-restoration', '/e2e/hermes/presentation',
    '/e2e/hermes/long-transcript',
  ].includes(path);
  const state = restoration;
  const reads = inventory ? state.inventory_reads : metadata ? state.metadata_reads : null;
  // Reserve before forwarding, so concurrent requests cannot exceed the bound.
  if (reads && reads.length >= receiptBound) {
    req.resume();
    return json(res, 409, { error: 'synthetic restoration receipt bound' });
  }
  const read = inventory ? {
    profile_id: url.searchParams.get('profile'),
    offset: Number(url.searchParams.get('offset') ?? 0),
    limit: Number(url.searchParams.get('limit') ?? 50),
    session_ids: [], omitted_session_id: null, status: null,
  } : metadata ? {
    profile_id: url.searchParams.get('profile'),
    session_id: decodeURIComponent(metadataMatch[1]),
    returned_session_id: null, status: null,
  } : null;
  if (inventory && (!Number.isInteger(read.limit) || read.limit < 1 || read.limit > 200 ||
      !Number.isInteger(read.offset) || read.offset < 0 || read.offset > 1000000)) {
    req.resume();
    return json(res, 400, { error: 'invalid synthetic session page' });
  }
  if (read) reads.push(read);
  // Re-page the two authoritative lifecycle sessions, with a server-side page
  // cap of one. The remembered pointer really is on page two, not just hidden.
  const upstreamPath = inventory
    ? `/api/sessions?limit=200&offset=0&profile=${encodeURIComponent(url.searchParams.get('profile') ?? '')}`
    : req.url;
  const upstream = http.request({
    hostname: '127.0.0.1', port: backendPort,
    method: req.method, path: upstreamPath,
    headers: { ...req.headers, host: `127.0.0.1:${backendPort}` },
  }, response => {
    if (!(inventory || metadata || receipt || reset)) {
      res.writeHead(response.statusCode, response.headers);
      response.pipe(res);
      return;
    }
    const chunks = [];
    let size = 0;
    response.on('data', chunk => {
      size += chunk.length;
      if (size > bodyBound) {
        response.destroy();
        if (!res.headersSent) json(res, 502, { error: 'synthetic response bound' });
        return;
      }
      chunks.push(chunk);
    });
    response.on('end', () => {
      try {
        const body = JSON.parse(Buffer.concat(chunks));
        const success = response.statusCode >= 200 && response.statusCode < 300;
        if (reset && success) restoration = null;
        if (path === lifecyclePath && req.method === 'POST' && success) {
          restoration = { session_id: sessionId, inventory_reads: [], metadata_reads: [] };
        }
        if (inventory) {
          read.status = response.statusCode;
          if (success) {
            if (body.has_more) throw new Error('synthetic inventory bound');
            const ordered = [
              ...body.data.filter(session => session.id !== sessionId),
              ...body.data.filter(session => session.id === sessionId),
            ];
            body.limit = 1;
            body.offset = read.offset;
            body.has_more = read.offset + 1 < ordered.length;
            body.data = ordered.slice(read.offset, read.offset + 1);
            if (read.offset === 0) read.omitted_session_id = sessionId;
            read.session_ids = body.data.map(session => session.id);
          }
        }
        if (metadata) {
          read.status = response.statusCode;
          read.returned_session_id = success ? body.session?.id ?? null : null;
        }
        if (receipt && restoration && body.synthetic === true) {
          body.restoration = restoration;
        }
        json(res, response.statusCode, body);
      } catch {
        if (!res.headersSent) json(res, 502, { error: 'synthetic backend response invalid' });
      }
    });
    response.on('error', () => {
      if (!res.headersSent) json(res, 502, { error: 'synthetic backend unavailable' });
      else res.destroy();
    });
  });
  upstream.on('error', () => {
    if (!res.headersSent) json(res, 502, { error: 'synthetic backend unavailable' });
    else res.destroy();
  });
  req.on('aborted', () => upstream.destroy());
  res.on('close', () => { if (!res.writableFinished) upstream.destroy(); });
  req.pipe(upstream);
}

try {
  // Reserve both backend ports together. Never contact them until this exact
  // child announces both successful loopback binds; bind races fail closed.
  const reservations = [http.createServer(), http.createServer()];
  servers.push(...reservations);
  await Promise.all(reservations.map(server => listen(server, 0)));
  const backendPorts = reservations.map(server => server.address().port);
  await Promise.all(reservations.map(server => new Promise(resolve => server.close(resolve))));
  backend = spawn(process.execPath, [fileURLToPath(new URL('../../serve_web.mjs', import.meta.url))], {
    env: { ...process.env, PORT: String(backendPorts[0]), HERMES_E2E_PORT: String(backendPorts[1]) },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  backend.stderr.pipe(process.stderr);
  await new Promise((resolve, reject) => {
    const expected = new Set([
      `Server running at http://127.0.0.1:${backendPorts[0]}/`,
      `Hermes API running at http://127.0.0.1:${backendPorts[1]}/`,
    ]);
    let pending = '';
    const timer = setTimeout(() => reject(new Error('synthetic backend startup timeout')), 10000);
    backend.once('error', reject);
    backend.once('exit', () => { clearTimeout(timer); reject(new Error('synthetic backend exited')); });
    backend.stdout.on('data', chunk => {
      pending += chunk;
      const lines = pending.split('\n');
      pending = lines.pop();
      for (const line of lines) expected.delete(line.trim());
      if (!expected.size) { clearTimeout(timer); resolve(); }
    });
  });
  backend.once('exit', () => { if (!stopping) void shutdown(1); });
  for (const [index, publicPort] of [port, hermesPort].entries()) {
    const server = http.createServer((req, res) => {
      try { proxy(req, res, backendPorts[index]); }
      catch { req.resume(); json(res, 400, { error: 'invalid synthetic request' }); }
    });
    servers.push(server);
    await listen(server, publicPort);
  }
  console.log(`Server running at http://127.0.0.1:${port}/`);
  console.log(`Hermes API running at http://127.0.0.1:${hermesPort}/`);
} catch (error) {
  console.error(error.message);
  await shutdown(1);
}
