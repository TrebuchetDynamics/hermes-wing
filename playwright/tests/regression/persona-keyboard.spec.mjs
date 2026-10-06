import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor, focusedNode } from '../../support/inventory_keyboard.mjs';

const initial = '\n\n\t  Inert original persona. café 東京. \n\n';
const draft = '\n\t  Inert explicit draft.\n  Unicode: café 東京 🪽 e\u0301. \t\n\n';
const newer = '\n\t  Inert newer server persona. café 東京. \n\n';
const privateError = { error: 'synthetic private persona failure' };

// Only per-test existing advertised scoped SOUL and Profiles read contracts.
// No default-fixture, Agent authentication or production-availability change.
for (const width of [390, 1280]) {
  for (const mode of ['cancel', 'save', 'unchanged', 'read-failure', 'write-failure', 'conflict']) {
    test(`Persona keyboard-only ${mode} revision-safe completion/reopen at ${width}px`, async ({ page }, testInfo) => {
      const trace = [], requests = [], readbacks = [], pendingBodies = [], errors = [], outcomes = [];
      const actor = keyboardActor(page, testInfo, trace);
      const field = actor.control('textbox', 'Persona');
      const save = actor.control('button', 'Save');
      const cancel = actor.control('button', 'Cancel');
      const ids = new Map();
      let persisted = { soul: initial, revision: 'persona-r1' };
      let failed = false, release;
      const writes = [], reads = [];
      const shape = request => {
        const url = new URL(request.url());
        return { origin: url.origin, path: url.pathname, query: Object.fromEntries(url.searchParams),
          method: request.method(), ifMatch: request.headers()['if-match'] ?? null, body: request.postData() };
      };
      const isApi = url => /^\/(api|v1|health)(\/|$)/.test(url.pathname);
      page.on('pageerror', error => errors.push(error.message));
      page.on('request', request => {
        if (isApi(new URL(request.url()))) {
          ids.set(request, requests.length + 1);
          requests.push({ id: ids.get(request), ...shape(request) });
        }
      });
      page.on('response', response => {
        if (isApi(new URL(response.url()))) pendingBodies.push(response.body().then(buffer => {
          expect(buffer.length).toBeLessThan(65536);
          readbacks.push({ id: ids.get(response.request()), ...shape(response.request()), status: response.status(),
            body: JSON.parse(buffer.toString('utf8')), bytes: [...buffer], terminal: 'complete-response-read' });
        }));
      });
      const settle = async () => { await Promise.all(pendingBodies); readbacks.sort((a, b) => a.id - b.id); };
      const owner = () => page.evaluate(() => {
        const state = JSON.parse(globalThis.wingE2EHermesStateSummary());
        return { profile: state.selected_profile_id, session: state.active_session_id,
          provider: state.assigned_provider, model: state.assigned_model, status: state.status };
      });
      const shellRole = width === 390 ? 'tab' : 'button';
      const chatName = width === 390 ? 'Chat' : 'Chat';
      const openPersona = async () => {
        if (width === 390) {
          await actor.reach('tab', 'More'); await actor.press('Enter');
          await actor.reach('button', 'Persona');
        } else await actor.reach('button', 'Persona');
        await actor.press('Enter');
        await expect(page.getByRole('heading', { name: 'Persona', exact: true })).toBeVisible();
        if (width === 1280) await expect(page).toHaveURL(/#\/soul$/);
      };
      const edit = async text => {
        await actor.reach('textbox', 'Persona');
        await page.keyboard.press('ControlOrMeta+A'); await actor.record('ControlOrMeta+A');
        await page.keyboard.type(text); await actor.record(`type ${JSON.stringify(text)}`);
        await expect(field).toHaveValue(text);
      };
      const activate = async (name, key) => {
        await actor.reach('button', name);
        trace.push({ activationIntent: key, focusedBefore: await focusedNode(page) });
        await actor.press(key);
      };
      const pendingProof = async number => {
        await expect.poll(() => writes.length).toBe(number);
        await expect(save).toBeDisabled(); await expect(cancel).toBeDisabled();
        const safeActivation = async () => {
          const focus = await focusedNode(page);
          if (focus.role === 'button' && ['Save', 'Cancel'].includes(focus.name)) {
            await actor.press('Enter'); await actor.press('Space');
          } else trace.push({ assertion: 'disabled activation withheld from unrelated control', focused: focus });
        };
        await safeActivation();
        for (let step = 0; step < 12; step++) { await actor.press('Tab'); await safeActivation(); }
        for (let step = 0; step < 12; step++) { await actor.press('Shift+Tab'); await safeActivation(); }
        expect(writes).toHaveLength(number);
        expect(readbacks.filter(r => r.method === 'PUT')).toHaveLength(number - 1);
        expect(await owner()).toEqual(beforeOwner);
        await expect(page.getByRole('heading', { name: 'Persona', exact: true })).toBeVisible();
        outcomes.push({ phase: 'pending', writes: number, duplicates: 0, cancelDisabled: true });
      };
      let beforeOwner, afterOwner, bootstrapCount, readback;
      try {
        await page.route(url => url.pathname === '/v1/capabilities', async route => {
          const response = await route.fetch(); const base = await response.json();
          await route.fulfill({ response, json: { ...base,
            profile_context: { type: 'query', name: 'profile', required: true, default_profile_id: 'default' },
            auth: { ...base.auth, granted_scopes: [...base.auth.granted_scopes, 'profiles:read', 'profiles:write'] },
            endpoints: { ...base.endpoints,
              profiles: { method: 'GET', path: '/api/profiles', required_scopes: ['profiles:read'] },
              profile_soul: { method: 'GET', path: '/api/profiles/{name}/soul', required_scopes: ['profiles:read'] },
              profile_soul_update: { method: 'PUT', path: '/api/profiles/{name}/soul', required_scopes: ['profiles:write'] },
            },
          } });
        });
        await page.route(url => url.pathname === '/api/profiles', route => route.fulfill({ status: 200, json: {
          data: [{ id: 'default', name: 'Fixture profile', revision: 'profile-r1' }],
        } }));
        await page.route(url => url.pathname === '/api/profiles/default/soul', async route => {
          const request = route.request();
          expect(shape(request).query).toEqual({ profile: 'default' });
          if (request.method() === 'GET') {
            const fail = mode === 'read-failure' && !failed;
            if (fail) failed = true;
            const body = fail ? privateError : { ...persisted };
            reads.push({ status: fail ? 503 : 200, body });
            return route.fulfill({ status: fail ? 503 : 200, json: body });
          }
          expect(request.method()).toBe('PUT');
          expect(request.headers()['if-match']).toBe(persisted.revision);
          const body = request.postDataJSON();
          expect(body).toEqual({ soul: draft });
          const write = { ...shape(request), status: null, response: null };
          writes.push(write);
          await new Promise(resolve => { release = resolve; });
          let status = 200;
          if (!failed && mode === 'write-failure') { failed = true; status = 503; }
          else if (!failed && mode === 'conflict') {
            failed = true; status = 412; persisted = { soul: newer, revision: 'persona-r2' };
          } else persisted = { soul: body.soul, revision: mode === 'conflict' ? 'persona-r3' : 'persona-r2' };
          write.status = status; write.response = status === 200 ? { ...persisted } : privateError;
          return route.fulfill({ status, json: write.response });
        });
        await page.setViewportSize({ width, height: 1400 });
        await page.goto(`${APP}#/profiles`);
        await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
        await enableFlutterAccessibility(page, { delay: 500 });
        await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
        await expect.poll(owner).toEqual({ profile: 'default', session: 'e2e-hermes-session', provider: null, model: null, status: 'connected' });
        await page.evaluate(() => globalThis.wingE2EHermesLoadDefaultProfileInventory());
        await expect(actor.control('group', 'Fixture profile, ID: default, Active chat, Default')).toBeVisible();
        // End bootstrap. All subsequent UI actions use physical keyboard keys only.
        await settle(); bootstrapCount = requests.length;
        beforeOwner = await owner();
        expect(beforeOwner).toEqual({ profile: 'default', session: 'e2e-hermes-session', provider: null, model: null, status: 'connected' });
        await openPersona();
        if (mode === 'read-failure') {
          await expect(save).toBeDisabled();
          await expect(page.locator('flt-semantics').getByText('Hermes could not complete that profile change.', { exact: true })).toBeVisible();
          await actor.reach('button', 'Retry');
          await actor.visibleFocus('button', 'Retry', 'persona-retry');
          expect(writes).toEqual([]); await activate('Retry', 'Space');
        }
        await actor.reach('textbox', 'Persona'); await expect(field).toHaveValue(initial);
        await actor.visibleFocus('textbox', 'Persona', 'persona-field');
        // Named forward escape and backward return without activating Chat.
        await actor.reach(shellRole, chatName); await actor.reach('textbox', 'Persona', 'Shift+Tab');
        if (mode !== 'unchanged') await edit(draft);
        expect(writes).toEqual([]);
        await actor.reach('button', 'Cancel'); await actor.visibleFocus('button', 'Cancel', 'persona-cancel', 'Shift+Tab');
        await actor.reach('button', 'Save'); await actor.visibleFocus('button', 'Save', 'persona-save', 'Shift+Tab');
        await activate(mode === 'cancel' ? 'Cancel' : 'Save', 'Enter');
        if (!['cancel', 'unchanged'].includes(mode)) {
          await pendingProof(1); release();
          if (mode === 'write-failure' || mode === 'conflict') {
            const message = mode === 'conflict' ? /This profile changed elsewhere/ : 'Hermes could not complete that profile change.';
            await expect(page.locator('flt-semantics').getByText(message, { exact: mode !== 'conflict' })).toBeVisible();
            await actor.reach('textbox', 'Persona');
            await expect(field).toHaveValue(mode === 'conflict' ? newer : draft);
            await settle(); expect(writes).toHaveLength(1);
            outcomes.push({ phase: 'rejected-no-auto-retry', status: writes[0].status, document: mode === 'conflict' ? newer : draft });
            if (mode === 'conflict') await edit(draft);
            await activate('Save', 'Space'); await pendingProof(2); release();
          }
        }
        await expect(page).toHaveURL(/#\/profiles$/); await expect(field).toHaveCount(0);
        await settle();
        const expected = ['cancel', 'unchanged'].includes(mode) ? { soul: initial, revision: 'persona-r1' }
          : { soul: draft, revision: mode === 'conflict' ? 'persona-r3' : 'persona-r2' };
        // Read-only authoritative fixture observation; no UI or state injection.
        readback = await page.evaluate(async () => {
          const response = await fetch('/api/profiles/default/soul?profile=default');
          const bytes = [...new Uint8Array(await response.arrayBuffer())];
          return { status: response.status, body: JSON.parse(new TextDecoder().decode(new Uint8Array(bytes))), bytes };
        });
        expect(readback).toEqual({ status: 200, body: expected, bytes: [...Buffer.from(JSON.stringify(expected), 'utf8')] });
        const count = writes.length, readCount = reads.length;
        await openPersona(); await actor.reach('textbox', 'Persona'); await expect(field).toHaveValue(expected.soul);
        expect(reads).toHaveLength(readCount + 1); expect(reads.at(-1).body).toEqual(expected);
        await activate('Cancel', 'Space'); await expect(page).toHaveURL(/#\/profiles$/);
        expect(writes).toHaveLength(count);
        expect(writes.map(w => w.status)).toEqual(['cancel', 'unchanged'].includes(mode) ? []
          : mode === 'conflict' ? [412, 200] : mode === 'write-failure' ? [503, 200] : [200]);
        expect(writes.map(w => w.ifMatch)).toEqual(['cancel', 'unchanged'].includes(mode) ? []
          : mode === 'conflict' ? ['persona-r1', 'persona-r2'] : mode === 'write-failure' ? ['persona-r1', 'persona-r1'] : ['persona-r1']);
        for (const w of writes) expect(w.body).toBe(JSON.stringify({ soul: draft }));
        await settle();
        const workflow = requests.slice(bootstrapCount);
        const soulGet = { method: 'GET', path: '/api/profiles/default/soul', query: { profile: 'default' } };
        const soulPut = { ...soulGet, method: 'PUT' };
        const profilesGet = { method: 'GET', path: '/api/profiles', query: {} };
        // Existing production _runProfileMutation refreshes the host collection
        // after success or 412, before the editor completes/reconciles its SOUL.
        const expectedWorkflow = [soulGet];
        if (mode === 'read-failure') expectedWorkflow.push(soulGet);
        if (!['cancel', 'unchanged'].includes(mode)) {
          expectedWorkflow.push(soulPut);
          if (mode === 'conflict') expectedWorkflow.push(profilesGet, soulGet);
          if (['conflict', 'write-failure'].includes(mode)) expectedWorkflow.push(soulPut);
          expectedWorkflow.push(profilesGet);
        }
        expectedWorkflow.push(soulGet, soulGet); // complete readback, keyboard reopen
        expect(workflow.map(({ method, path, query }) => ({ method, path, query }))).toEqual(expectedWorkflow);
        expect(requests.filter(r => r.method !== 'GET')).toHaveLength(writes.length);
        expect(requests.every(r => r.origin === new URL(APP).origin)).toBe(true);
        expect(readbacks.map(r => r.id)).toEqual(requests.map(r => r.id));
        afterOwner = await owner(); expect(afterOwner).toEqual(beforeOwner); expect(errors).toEqual([]);
        await expect(page.getByText(/synthetic private persona failure/)).toHaveCount(0);
        await testInfo.attach('persona-keyboard-receipt.json', { contentType: 'application/json', body: JSON.stringify({
          target: 'fresh compiled JS-release Chromium deterministic advertised-contract fixture only', width, height: 1400, mode,
          reducedMotion: true, initial, newer, draft, bootstrapRequests: requests.slice(0, bootstrapCount), workflowRequests: workflow,
          responseReadbacks: readbacks, writes, reads, readback, beforeOwner, afterOwner, outcomes, trace, pageErrors: errors,
          lineEndings: 'LF; browser CRLF, native desktop, real Agent/provider and screen-reader qualification not claimed',
        }) });
      } finally {
        await testInfo.attach('persona-keyboard-trace.json', { contentType: 'application/json', body: JSON.stringify({ trace, requests, readbacks, outcomes, errors }) });
        await testInfo.attach('persona-keyboard-semantics.txt', { contentType: 'text/plain', body: await page.locator('body').ariaSnapshot() });
      }
    });
  }
}
