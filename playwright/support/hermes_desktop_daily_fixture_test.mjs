import assert from 'node:assert/strict';
import { test } from 'node:test';
import http from 'node:http';
import { spawn } from 'node:child_process';
import { once } from 'node:events';

async function reservePort() {
  const server = http.createServer();
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  return server;
}

async function withFixture(body) {
  const reservations = await Promise.all([reservePort(), reservePort()]);
  const ports = reservations.map(server => server.address().port);
  await Promise.all(reservations.map(server => new Promise(resolve => server.close(resolve))));
  const child = spawn(process.execPath, ['scripts/support/desktop_daily_workflow_fixture.mjs'], {
    env: { ...process.env, PORT: String(ports[0]), HERMES_E2E_PORT: String(ports[1]) },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  const exited = once(child, 'exit');
  let errors = '';
  child.stderr.on('data', chunk => { errors += chunk; });
  try {
    await new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error(`fixture startup timeout: ${errors}`)), 10000);
      let output = '';
      child.once('exit', () => { clearTimeout(timer); reject(new Error(`fixture exited: ${errors}`)); });
      child.once('error', reject);
      child.stdout.on('data', chunk => {
        output += chunk;
        if (ports.every(port => output.includes(`http://127.0.0.1:${port}/`))) {
          clearTimeout(timer);
          resolve();
        }
      });
    });
    const origin = `http://127.0.0.1:${ports[1]}`;
    const request = async (path, method = 'GET', payload) => {
      const response = await fetch(`${origin}${path}`, { method,
        ...(payload === undefined ? {} : { headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload) }), signal: AbortSignal.timeout(5000) });
      return { status: response.status, body: await response.json() };
    };
    await body(request, origin);
  } finally {
    const force = setTimeout(() => child.kill('SIGKILL'), 4000);
    child.kill('SIGTERM');
    const [code, signal] = await exited;
    clearTimeout(force);
    assert.ok(code === 143 || signal === 'SIGTERM', `unexpected cleanup ${code}/${signal}: ${errors}`);
    for (const port of ports) {
      await assert.rejects(fetch(`http://127.0.0.1:${port}/`, { signal: AbortSignal.timeout(1000) }));
    }
    console.log(JSON.stringify({ cleanup: 'reaped; public ports closed', pid: child.pid, code, signal, ports }));
  }
}

const control = '/e2e/hermes/lifecycle';
const session = 'e2e-hermes-session';
const modelRoute = `/api/sessions/${session}/model?profile=default`;
const pair = { provider: 'alpha', model: 'alpha/model-99' };

test('daily seed preserves one owner through explicit model lock and authoritative run recovery', { timeout: 30000 }, async () => {
  await withFixture(async (request, origin) => {
    assert.equal((await request(control, 'POST', { scenario: 'desktop-daily' })).status, 200);
    const discovery = (await request('/v1/capabilities')).body;
    assert.deepEqual(discovery.endpoints.session_model_lock, {
      method: 'POST', path: '/api/sessions/{session_id}/model', profile_scoped: true,
    });
    assert.equal(discovery.profile_context.name, 'profile');
    assert.equal((await request(modelRoute, 'POST', pair)).status, 409);
    assert.equal((await request(`/api/sessions/${session}?profile=default`)).body.session.runtime, undefined);
    const lock = await request(modelRoute, 'POST', pair);
    assert.equal(lock.status, 200);
    assert.equal(lock.body.session_id, session);
    assert.equal(lock.body.runtime.model, pair.model);
    const metadata = await request(`/api/sessions/${session}?profile=default`);
    assert.deepEqual(metadata.body.session.runtime, lock.body.runtime);
    const inventory = await request('/api/sessions?profile=default&offset=0&limit=50');
    assert.equal(inventory.body.has_more, true);
    assert.ok(!inventory.body.data.some(item => item.id === session));

    const submitted = await request('/v1/runs?profile=default', 'POST', {
      session_id: session, message: 'Synthetic combined prompt', input: 'Synthetic combined prompt',
    });
    assert.equal(submitted.status, 202);
    const stream = await fetch(`${origin}/v1/runs/run_1/events?profile=default`, { signal: AbortSignal.timeout(5000) });
    const reader = stream.body.getReader();
    let events = '';
    while (!events.includes('approval.request')) {
      const chunk = await reader.read();
      assert.equal(chunk.done, false);
      events += new TextDecoder().decode(chunk.value);
    }
    assert.equal((await request('/v1/runs/run_1/approval?profile=default', 'POST', {
      request_id: 'wrong', choice: 'once',
    })).status, 409);
    assert.equal((await request('/v1/runs/run_1/approval?profile=default', 'POST', {
      request_id: 'approval_run_1', choice: 'once',
    })).status, 200);
    while (!(await reader.read()).done) { /* Drain the authoritative terminal stream. */ }
    assert.equal((await request('/v1/runs/run_1?profile=default')).body.status, 'completed');
    assert.equal((await request('/v1/runs?profile=default', 'POST', {
      session_id: session, message: 'Synthetic stop prompt', input: 'Synthetic stop prompt',
    })).status, 202);
    assert.equal((await request('/v1/runs/run_2/stop?profile=default', 'POST', {})).body.status, 'stopping');
    assert.equal((await request('/v1/runs/run_2?profile=default')).body.status, 'stopping');
    assert.equal((await request(`${control}/terminal`, 'POST', { run_id: 'run_2' })).status, 200);
    assert.equal((await request('/v1/runs/run_2?profile=default')).body.status, 'cancelled');

    const before = (await request(control)).body;
    await request(`/api/sessions/${session}?profile=default`);
    await request(`/api/sessions/${session}/messages?profile=default`);
    const after = (await request(control)).body;
    for (const key of ['submits', 'approvals', 'stops', 'model_locks']) assert.deepEqual(after[key], before[key]);
    assert.equal(after.submits.length, 2);
    assert.equal(after.approvals.length, 1);
    assert.equal(after.stops.length, 1);
    assert.equal(after.model_locks.length, 2);
    assert.ok(after.model_locks.every(item => item.profile_id === 'default' && item.session_id === session));
    assert.equal(after.model_locks[0].status, 'rejected');
    assert.equal(after.model_locks[1].status, 'accepted');
    assert.equal(after.unexpected_mutations.length, 0);
    const canonical = after.sessions.find(item => item.session_id === session);
    assert.deepEqual(canonical.messages.map(item => item.id), [
      'assistant-welcome', 'user_run_1', 'canonical_run_1', 'user_run_2', 'canonical_run_2',
    ]);
    assert.equal(after.approvals[0].request_id, 'approval_run_1');
    for (const key of ['submits', 'approvals', 'stops']) {
      assert.ok(after[key].every(item => item.session_id === session && item.profile_id === 'default'));
    }
    assert.ok(after.restoration.metadata_reads.some(read => read.returned_session_id === session));
    console.log(JSON.stringify({ synthetic: true, submits: after.submits.length,
      approvals: after.approvals.length, stops: after.stops.length, model_locks: after.model_locks.length }));
  });
});

test('daily model exception rejects wrong owners, raw pairs and unrelated domain writes', { timeout: 30000 }, async () => {
  await withFixture(async request => {
    await request(control, 'POST', { scenario: 'desktop-daily' });
    for (const profile of ['other', '']) {
      assert.equal((await request(`/api/sessions/${session}/model?profile=${profile}`, 'POST', pair)).status, 403);
    }
    assert.equal((await request(`/api/sessions/${session}/model`, 'POST', pair)).status, 403);
    assert.equal((await request('/api/sessions/synthetic-untouched/model?profile=default', 'POST', pair)).status, 403);
    for (const invalid of [
      { provider: 'unconfigured', model: 'hidden' },
      { provider: 'alpha', model: 'beta/model-99' },
      { ...pair, extra: true }, null, [],
    ]) assert.equal((await request(modelRoute, 'POST', invalid)).status, 400);
    for (const [method, route] of [
      ['POST', '/api/sessions'], ['PATCH', '/api/providers/alpha'],
      ['DELETE', `/api/sessions/${session}`], ['PUT', '/api/config'],
    ]) assert.equal((await request(`${route}?profile=default`, method, {})).status, 403);
    const rejected = (await request(control)).body;
    assert.equal(rejected.model_locks.length, 0);
    assert.equal((await request(modelRoute, 'POST', pair)).status, 409);
    assert.equal((await request(modelRoute, 'POST', pair)).status, 200);
    const stable = (await request(control)).body;
    assert.equal((await request(control, 'POST', { scenario: 'unknown' })).status, 400);
    assert.equal((await request(control, 'POST', { scenario: 'desktop-daily', extra: true })).status, 400);
    assert.deepEqual((await request(control)).body.model_locks, stable.model_locks);
    assert.equal((await request(`/api/sessions/${session}?profile=default`)).body.session.runtime.model, pair.model);
    // The fixed receipt cap rejects before state mutation, not after recording.
    for (let i = 2; i < 128; i++) assert.equal((await request(modelRoute, 'POST', pair)).status, 200);
    assert.equal((await request(modelRoute, 'POST', pair)).status, 409);
    assert.equal((await request(control)).body.model_locks.length, 128);
  });
});

test('legacy no-body lifecycle seed still forbids model and other domain mutations', { timeout: 30000 }, async () => {
  await withFixture(async request => {
    await request(control, 'POST', { scenario: 'desktop-daily' });
    await request(modelRoute, 'POST', pair);
    await request(modelRoute, 'POST', pair);
    assert.equal((await request(control, 'POST')).status, 200);
    const receipt = (await request(control)).body;
    assert.equal(receipt.scenario, undefined);
    assert.equal(receipt.model_locks, undefined);
    assert.deepEqual(receipt.submits, []);
    assert.equal((await request(`/api/sessions/${session}?profile=default`)).body.session.runtime, undefined);
    assert.equal((await request(modelRoute, 'POST', pair)).status, 403);
    assert.equal((await request('/api/sessions?profile=default', 'POST', {})).status, 403);
    assert.equal((await request(control)).body.unexpected_mutations.length, 2);
    assert.equal((await request('/v1/capabilities')).body.endpoints.session_model_lock, undefined);
    await request('/e2e/hermes/model-picker', 'POST');
    assert.deepEqual((await request('/v1/capabilities')).body.endpoints.session_model_lock, {
      method: 'POST', path: '/api/sessions/{session_id}/model',
    });
  });
});
