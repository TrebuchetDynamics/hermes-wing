import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor, focusedNode } from '../../support/inventory_keyboard.mjs';

const refreshName = 'Refresh gateway status';
const fallbackName = 'Connected. Basic health is available, but detailed status could not be loaded.';
const basicName = 'Connected. Showing basic health because this gateway does not advertise detailed status.';
const privateError = { error: { message: 'synthetic private health metadata' } };
const detail = call => ({ status: 'ok', platform: 'hermes-agent',
  version: call === 1 ? 'fixture-initial' : 'fixture-recovered', gateway_state: 'running', active_agents: call });

// Synthetic per-test read responses; no default fixture change or write grant.
for (const width of [390, 1280]) {
  for (const mode of ['success', 'failure', 'unsupported']) {
    test(`Connections keyboard-only ${mode} pending/fallback/recovery preserves Chat at ${width}px`, async ({ page }, testInfo) => {
      const trace = [], requests = [], readbacks = [], responseReads = [], errors = [], outcomes = [];
      const ids = new Map();
      const actor = keyboardActor(page, testInfo, trace);
      const refresh = actor.control('button', refreshName);
      const retry = actor.control('button', 'Retry');
      const fallback = actor.control('group', fallbackName);
      const shellRole = width === 390 ? 'tab' : 'button';
      const shellName = width === 390 ? 'Chat' : 'Chat';
      let healthCalls = 0, release;
      const isApi = url => url.pathname.startsWith('/api/') || url.pathname.startsWith('/v1/') || url.pathname.startsWith('/health');
      const requestShape = request => {
        const url = new URL(request.url());
        return { origin: url.origin, method: request.method(), path: url.pathname,
          query: Object.fromEntries(url.searchParams), profile: url.searchParams.get('profile') };
      };
      page.on('pageerror', error => errors.push(error.message));
      page.on('request', request => {
        if (isApi(new URL(request.url()))) {
          ids.set(request, requests.length + 1);
          requests.push({ id: ids.get(request), ...requestShape(request) });
        }
      });
      page.on('response', response => {
        if (isApi(new URL(response.url()))) responseReads.push(response.json().then(body => {
          expect(Buffer.byteLength(JSON.stringify(body))).toBeLessThan(65536);
          readbacks.push({ id: ids.get(response.request()), ...requestShape(response.request()),
            status: response.status(), body, terminal: 'response-body-read' });
        }));
      });
      const owner = () => page.evaluate(() => {
        const state = JSON.parse(globalThis.wingE2EHermesStateSummary());
        return { profile: state.selected_profile_id, session: state.active_session_id,
          provider: state.assigned_provider, model: state.assigned_model, status: state.status };
      });
      const settled = async () => { await Promise.all(responseReads); readbacks.sort((a, b) => a.id - b.id); };
      const healthRequest = { origin: new URL(APP).origin, method: 'GET', path: '/health/detailed', query: {}, profile: null };
      const activateHealth = async key => {
        const current = await focusedNode(page);
        expect(current.role).toBe('button');
        expect([refreshName, 'Retry']).toContain(current.name);
        trace.push({ activationIntent: key, focusedBefore: current });
        await actor.press(key);
      };
      const pendingProof = async (call, actionName) => {
        await expect.poll(() => healthCalls).toBe(call);
        await expect(refresh).toBeDisabled();
        if (await retry.count()) await expect(retry).toBeDisabled();
        // Disabled Flutter controls may retain focus or be skipped. Never activate
        // whatever non-health control receives focus after the rebuild.
        const safeActivation = async () => {
          const current = await focusedNode(page);
          if (current.role === 'button' && [refreshName, 'Retry'].includes(current.name)) {
            await activateHealth('Enter');
            const next = await focusedNode(page);
            if (next.role === 'button' && [refreshName, 'Retry'].includes(next.name)) await activateHealth('Space');
          } else trace.push({ assertion: 'pending activation withheld from non-health control', focused: current });
        };
        await safeActivation();
        const traversalStart = trace.length;
        for (let step = 0; step < 12; step++) { await actor.press('Tab'); await safeActivation(); }
        for (let step = 0; step < 12; step++) { await actor.press('Shift+Tab'); await safeActivation(); }
        expect(healthCalls).toBe(call);
        expect(requests.filter(r => r.path === '/health/detailed')).toHaveLength(call);
        expect(readbacks.filter(r => r.path === '/health/detailed')).toHaveLength(call - 1);
        expect(await owner()).toEqual(beforeOwner);
        outcomes.push({ action: actionName, call, phase: 'pending', responseCompleted: false,
          detailedCalls: healthCalls, extraPendingReads: 0, traversalStart, traversalEnd: trace.length });
      };
      let beforeOwner, afterOwner, initial;
      try {
        await page.route(url => url.pathname === '/v1/capabilities', async route => {
          const response = await route.fetch();
          const base = await response.json();
          const endpoints = { ...base.endpoints };
          if (mode === 'unsupported') delete endpoints.health_detailed;
          await route.fulfill({ response, json: { ...base, endpoints,
            profile_context: { type: 'query', name: 'profile', required: true, default_profile_id: 'default' } } });
        });
        await page.route(url => url.pathname === '/health/detailed', async route => {
          const call = ++healthCalls;
          const ok = call === 1 ? mode === 'success' : await new Promise(resolve => { release = resolve; });
          await route.fulfill({ status: ok ? 200 : 503, json: ok ? detail(call) : privateError });
        });
        await page.setViewportSize({ width, height: 1400 });
        await page.goto(`${APP}#/gateway`);
        await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
        await enableFlutterAccessibility(page, { delay: 500 });
        await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
        // Initialization ends here. From here every UI action is one of four keys.
        if (mode === 'unsupported') {
          await expect(page.getByText(basicName, { exact: true })).toBeVisible();
          await expect(refresh).toHaveCount(0);
          await expect(retry).toHaveCount(0);
          await expect(fallback).toHaveCount(0);
        } else if (mode === 'failure') {
          await expect(fallback).toBeVisible();
          await expect(retry).toBeEnabled();
        } else {
          await expect(page.getByText(/fixture-initial/)).toBeVisible();
          await expect(refresh).toBeEnabled();
          await expect(retry).toHaveCount(0);
        }
        await settled();
        beforeOwner = await owner();
        expect(beforeOwner).toEqual({ profile: 'default', session: 'e2e-hermes-session', provider: null, model: null, status: 'connected' });
        expect(healthCalls).toBe(mode === 'unsupported' ? 0 : 1);
        initial = requests.length;
        const firstName = mode === 'failure' ? 'Retry' : refreshName;
        if (mode !== 'unsupported') {
          await actor.reach('button', firstName);
          await actor.visibleFocus('button', firstName, 'connections-first-health');
          await activateHealth('Enter');
          await pendingProof(2, firstName);
          release(false);
          await expect(fallback).toBeVisible();
          await expect(retry).toBeEnabled();
          await expect(refresh).toBeEnabled();
          await settled();
          expect(readbacks.filter(r => r.path === '/health/detailed').at(-1)).toMatchObject({ status: 503, body: privateError, terminal: 'response-body-read' });
          await expect(page.getByText(/synthetic private/)).toHaveCount(0);
          outcomes.push({ call: 2, phase: 'terminal-sanitized-failure', status: 503, responseCompleted: true, owner: await owner() });
          await actor.reach('button', 'Retry');
          await actor.visibleFocus('button', 'Retry', 'connections-recovery-retry', 'Shift+Tab');
          // Named forward shell escape and backward return, without activation.
          await actor.reach(shellRole, shellName);
          await actor.visibleFocus(shellRole, shellName, 'connections-shell');
          await actor.reach('button', 'Retry', 'Shift+Tab');
          await activateHealth('Space');
          await pendingProof(3, 'Retry');
          await expect(fallback).toBeVisible();
          release(true);
          await expect(page.getByText(/fixture-recovered/)).toBeVisible();
          await expect(refresh).toBeEnabled();
          await expect(retry).toHaveCount(0);
          await expect(fallback).toHaveCount(0);
          await settled();
          outcomes.push({ call: 3, phase: 'terminal-detailed-success', status: 200, responseCompleted: true, owner: await owner() });
          expect(requests.slice(initial).map(({ id, ...request }) => request)).toEqual([healthRequest, healthRequest]);
          expect(readbacks.filter(r => r.path === '/health/detailed').map(({ status, body }) => ({ status, body }))).toEqual([
            { status: mode === 'success' ? 200 : 503, body: mode === 'success' ? detail(1) : privateError },
            { status: 503, body: privateError }, { status: 200, body: detail(3) },
          ]);
          await actor.reach('button', refreshName);
          await actor.reach(shellRole, shellName);
          await actor.reach('button', refreshName, 'Shift+Tab');
        } else {
          // No health action exists: navigate only between named shell controls.
          await actor.reach(shellRole, shellName);
          await actor.visibleFocus(shellRole, shellName, 'connections-basic-shell');
          const connectionsName = width === 390 ? 'Connections' : 'Connections';
          await actor.reach(shellRole, connectionsName);
          await actor.reach(shellRole, shellName, 'Shift+Tab');
          expect(requests.slice(initial)).toEqual([]);
        }
        afterOwner = await owner();
        expect(afterOwner).toEqual(beforeOwner);
        await settled();
        expect(requests.every(r => r.method === 'GET' && r.origin === new URL(APP).origin)).toBe(true);
        expect(readbacks.map(r => r.id)).toEqual(requests.map(r => r.id));
        expect(readbacks.every(r => r.terminal === 'response-body-read')).toBe(true);
        expect(errors).toEqual([]);
        await expect(page).toHaveURL(/#\/gateway$/);
        await testInfo.attach('connections-keyboard-receipt.json', { contentType: 'application/json', body: JSON.stringify({
          target: 'fresh compiled JS-release Chromium deterministic read-only fixture only', width, height: 1400, mode, reducedMotion: true,
          bootstrapRequests: requests.slice(0, initial), workflowRequests: requests.slice(initial), responseReadbacks: readbacks,
          healthOwner: { origin: new URL(APP).origin, operation: 'health_detailed', scope: 'gateway:read', profileScoped: false },
          beforeOwner, afterOwner, outcomes, healthCalls, mutationRequests: 0, trace, pageErrors: errors,
        }) });
      } finally {
        await testInfo.attach('connections-keyboard-semantic-nodes.json', { contentType: 'application/json', body: JSON.stringify(await page.locator('flt-semantics').evaluateAll(nodes => nodes.map(node => ({ text: node.textContent, attributes: Object.fromEntries([...node.attributes].map(attribute => [attribute.name, attribute.value])) })))) });
        await testInfo.attach('connections-keyboard-trace.json', { contentType: 'application/json', body: JSON.stringify({ trace, requests, readbacks, outcomes, errors }) });
        await testInfo.attach('connections-keyboard-semantics.txt', { contentType: 'text/plain', body: await page.locator('body').ariaSnapshot() });
      }
    });
  }
}
