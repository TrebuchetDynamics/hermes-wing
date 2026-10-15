import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor } from '../../support/inventory_keyboard.mjs';

test.describe.configure({ retries: 0 });
const draft = 'Synthetic retained overlay draft';
const closeButton = page => page.getByRole('button', { name: 'Close', exact: true });
const state = page => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()));

async function ready(page) {
  await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
  await page.evaluate(() => globalThis.wingE2EReduceMotion());
  await enableFlutterAccessibility(page, { delay: 0 });
}

async function shellOpen(page, width, destination, actor) {
  const activate = async control => {
    const role = await control.getAttribute('role');
    const name = (await control.getAttribute('aria-label') ?? await control.textContent() ?? '').replace(/\s+/g, ' ').trim();
    expect(name).toBeTruthy();
    if (actor) {
      await actor.reach(role, name);
      await actor.press('Enter');
    } else await control.click();
    return { role, name };
  };
  let returnFocus;
  if (width < 600) {
    returnFocus = await activate(page.getByRole('tab', { name: destination === 'Settings' ? 'More' : 'Profiles', exact: true }));
    if (destination === 'Settings') {
      if (actor) await activate(page.getByRole('button', { name: 'Settings', exact: true }));
      else await page.getByText('Settings', { exact: true }).last().click();
    }
  } else {
    returnFocus = await activate(page.getByRole('button', { name: destination === 'Settings' ? /^Settings(?: Settings)?$/ : 'Profiles', exact: true }));
  }
  await expect(closeButton(page)).toBeVisible();
  return returnFocus;
}

for (const width of [390, 1280]) {
  test(`Profiles rendered owner switch survives overlay history at ${width}px/200% text`, async ({ page, request }) => {
    expect((await request.post(`${APP}e2e/hermes/reset`)).ok()).toBe(true);
    const writes = [], reads = [], errors = [];
    const session = 'synthetic-coder-session';
    const reply = 'Synthetic coding profile history.';
    page.on('pageerror', error => errors.push(error.name));
    page.on('console', message => {
      if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(message.text())) errors.push('render error');
    });
    page.on('request', request => {
      const url = new URL(request.url());
      if (!/^\/(api|v1)\//.test(url.pathname)) return;
      if (request.method() !== 'GET') writes.push({ method: request.method(), route: url.pathname });
      else reads.push({ route: url.pathname, profile: url.searchParams.get('profile') });
    });
    // Per-test synthetic advertised read contracts, matching profile-keyboard coverage.
    await page.route(url => url.pathname === '/v1/capabilities', async route => {
      const response = await route.fetch();
      const base = await response.json();
      await route.fulfill({ response, json: {
        ...base,
        profile_context: { type: 'query', name: 'profile', required: true, default_profile_id: 'default' },
        auth: { ...base.auth, granted_scopes: [...base.auth.granted_scopes, 'profiles:read'] },
        endpoints: { ...base.endpoints,
          profiles: { method: 'GET', path: '/api/profiles', profile_scoped: false, required_scopes: ['profiles:read'] },
        },
      } });
    });
    await page.route(url => url.pathname === '/api/profiles', route => route.fulfill({ json: { data: [
      { id: 'default', name: 'Home profile', revision: 'r1' },
      { id: 'coder', name: 'Coding profile', revision: 'r2' },
    ] } }));
    await page.route(url => url.pathname === '/api/sessions' && url.searchParams.get('profile') === 'coder', route => route.fulfill({ json: {
      object: 'list', offset: 0, limit: 50, has_more: false,
      data: [{ id: session, title: 'Synthetic coding session', source: 'e2e', model: 'hermes-agent' }],
    } }));
    await page.route(url => url.pathname === `/api/sessions/${session}/messages`, route => route.fulfill({ json: {
      object: 'list', session_id: session,
      data: [{ id: 'synthetic-coder-reply', session_id: session, role: 'assistant', content: reply }],
    } }));
    await page.setViewportSize({ width, height: 1400 });
    await page.goto(`${APP}?e2eTextScale=2#/hermes?view=synthetic-profile-overlay`);
    await ready(page);
    await page.evaluate(() => globalThis.wingE2EHermesConnect());
    await expect.poll(async () => (await state(page)).active_session_id).toBe('e2e-hermes-session');
    await page.evaluate(() => globalThis.wingE2EHermesLoadDefaultProfileInventory());
    await expect(page.getByRole('group', { name: /E2E Hermes is ready\.$/ })).toBeVisible();
    expect(await state(page)).toMatchObject({ selected_profile_id: 'default', active_session_id: 'e2e-hermes-session', has_error: false });
    const location = page.url();
    await shellOpen(page, width, 'Profiles');
    await page.getByRole('button', { name: 'Chat with Coding profile', exact: true }).click();
    await expect.poll(async () => (await state(page)).selected_profile_id).toBe('coder');
    await expect(page.getByRole('group', { name: /Synthetic coding profile history\.$/ })).toBeVisible();
    await expect(closeButton(page)).not.toBeVisible();
    const replacement = await state(page);
    expect(replacement).toMatchObject({ status: 'connected', selected_profile_id: 'coder', active_session_id: session, has_error: false });
    const assertChat = async () => {
      await expect(closeButton(page)).not.toBeVisible();
      await expect(page.getByRole('group', { name: /Synthetic coding profile history\.$/ })).toBeVisible();
      await expect(page.getByRole('group', { name: /E2E Hermes is ready\.$/ })).not.toBeVisible();
      expect(await state(page)).toEqual(replacement);
    };
    await assertChat();
    expect(page.url()).toBe(location);
    await shellOpen(page, width, 'Profiles');
    await expect(page.getByRole('group', { name: 'Coding profile, ID: coder, Active chat', exact: true })).toBeVisible();
    await expect(page.getByRole('group', { name: 'Home profile, ID: default, Active chat, Default', exact: true })).not.toBeVisible();
    expect(await state(page)).toEqual(replacement);
    await page.goBack();
    await assertChat();
    await page.goForward();
    await expect(closeButton(page)).toBeVisible();
    await page.keyboard.press('Escape');
    await assertChat();
    expect(page.url()).toBe(location);
    expect(reads).toContainEqual({ route: '/api/sessions', profile: 'coder' });
    expect(reads).toContainEqual({ route: `/api/sessions/${session}/messages`, profile: 'coder' });
    expect(writes).toEqual([]);
    expect(errors).toEqual([]);
  });

  for (const destination of ['Settings', 'Profiles']) {
    test(`${destination} keyboard shell entry retains chat through Back/Forward, Escape and Close at ${width}px/200% text`, async ({ page, request }, testInfo) => {
      expect((await request.post(`${APP}e2e/hermes/reset`)).ok()).toBe(true);
      const errors = [], writes = [], trace = [];
      page.on('pageerror', error => errors.push(error.name));
      page.on('console', message => {
        if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(message.text())) errors.push('render error');
      });
      page.on('request', request => {
        const route = new URL(request.url()).pathname;
        if (/^\/(api|v1)\//.test(route) && request.method() !== 'GET') writes.push({ method: request.method(), route });
      });
      const actor = keyboardActor(page, testInfo, trace);
      await page.setViewportSize({ width, height: 1000 });
      await page.goto(`${APP}?e2eTextScale=2#/hermes?view=synthetic-overlay`);
      await ready(page);
      // Only bootstrap uses the existing synthetic connection hook.
      await page.evaluate(() => globalThis.wingE2EHermesConnect());
      await expect(page.getByRole('textbox', { name: 'Message Hermes…', exact: true })).toBeVisible();
      const composer = page.getByRole('textbox').last();
      await composer.click();
      await page.locator('input:focus, textarea:focus').fill(draft);
      const before = await state(page);
      expect(before).toMatchObject({ status: 'connected', selected_profile_id: null, active_session_id: 'e2e-hermes-session', has_error: false });
      const location = page.url();
      const length = await page.evaluate(() => history.length);
      const returnFocus = await shellOpen(page, width, destination, actor);
      await expect.poll(() => page.evaluate(() => history.length)).toBe(length + 1);
      await actor.assertFocus('button', 'Close');
      await actor.press('Tab');
      await expect(composer).not.toBeVisible();
      await actor.press('Shift+Tab');
      await actor.assertFocus('button', 'Close');
      await page.goBack();
      await expect(closeButton(page)).not.toBeVisible();
      await expect(composer).toBeVisible();
      await actor.assertFocus(returnFocus.role, returnFocus.name);
      expect(page.url()).toBe(location);
      await expect(page.getByRole('group', { name: /E2E Hermes is ready\.$/ })).toBeVisible();
      await page.goForward();
      await expect(closeButton(page)).toBeVisible();
      await page.keyboard.press('Escape');
      await expect(closeButton(page)).not.toBeVisible();
      await expect(composer).toBeVisible();
      await actor.assertFocus(returnFocus.role, returnFocus.name);
      await shellOpen(page, width, destination, actor);
      await actor.assertFocus('button', 'Close');
      await actor.press('Enter');
      await expect(closeButton(page)).not.toBeVisible();
      await actor.assertFocus(returnFocus.role, returnFocus.name);
      await composer.click();
      await expect(page.locator('input:focus, textarea:focus')).toHaveValue(draft);
      expect(page.url()).toBe(location);
      expect(await state(page)).toEqual(before);
      expect(writes).toEqual([]);
      expect(errors).toEqual([]);
    });

    test(`${destination} restores composer focus after local slash entry at ${width}px/200% text`, async ({ page, request }) => {
      expect((await request.post(`${APP}e2e/hermes/reset`)).ok()).toBe(true);
      await page.setViewportSize({ width, height: 1000 });
      await page.goto(`${APP}?e2eTextScale=2#/hermes?view=synthetic-focus-overlay`);
      await ready(page);
      await page.evaluate(() => globalThis.wingE2EHermesConnect());
      const composer = page.getByRole('textbox', { name: 'Message Hermes…', exact: true });
      await expect(composer).toBeVisible();
      await composer.click();
      const writes = [], errors = [];
      page.on('pageerror', error => errors.push(error.name));
      page.on('request', request => {
        const route = new URL(request.url()).pathname;
        if (/^\/(api|v1)\//.test(route) && request.method() !== 'GET') writes.push({ method: request.method(), route });
      });
      const location = page.url(), before = await state(page);
      for (const dismissal of ['close', 'escape', 'back']) {
        await page.locator('input:focus, textarea:focus').fill(`/${destination.toLowerCase()}`);
        await page.getByRole('button', { name: new RegExp(`^/${destination.toLowerCase()} `) }).click();
        await expect(closeButton(page)).toBeVisible();
        if (dismissal === 'close') await closeButton(page).click();
        else if (dismissal === 'escape') await page.keyboard.press('Escape');
        else await page.goBack();
        await expect(closeButton(page)).not.toBeVisible();
        await expect(page.locator('input:focus, textarea:focus')).toHaveValue('');
        expect(page.url()).toBe(location);
        expect(await state(page)).toEqual(before);
      }
      expect(writes).toEqual([]);
      expect(errors).toEqual([]);
    });

    test(`${destination} receives stream completion while hidden at ${width}px/200% text`, async ({ page, request }) => {
      expect((await request.post(`${APP}e2e/hermes/reasoning-disclosure`)).ok()).toBe(true);
      const writes = [], errors = [];
      page.on('pageerror', error => errors.push(error.name));
      page.on('console', message => {
        if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(message.text())) errors.push('render error');
      });
      page.on('request', request => {
        const route = new URL(request.url()).pathname;
        if (/^\/(api|v1)\//.test(route) && request.method() !== 'GET') writes.push({ method: request.method(), route });
      });
      await page.setViewportSize({ width, height: 1000 });
      await page.goto(`${APP}?e2eTextScale=2#/hermes?view=synthetic-stream-overlay`);
      await ready(page);
      await page.evaluate(() => globalThis.wingE2EHermesConnect());
      const composer = page.getByRole('textbox', { name: 'Message Hermes…', exact: true });
      await expect(composer).toBeVisible();
      await composer.click();
      const prompt = 'Synthetic overlay streaming request';
      await page.locator('input:focus, textarea:focus').fill(prompt);
      await page.getByRole('button', { name: 'Send', exact: true }).click();
      await expect(page.getByRole('button', { name: 'Thinking…', exact: true })).toBeVisible();
      const running = await state(page);
      expect(running).toMatchObject({ status: 'connected', active_session_id: 'e2e-hermes-session', has_error: false, last_turn_status: 'streaming' });
      const location = page.url();
      await shellOpen(page, width, destination);
      await expect(page.getByRole('button', { name: 'Thinking…', exact: true })).not.toBeVisible();
      expect(await state(page)).toEqual(running);
      await page.goBack();
      await expect(closeButton(page)).not.toBeVisible();
      await expect(page.getByRole('button', { name: 'Thinking…', exact: true })).toBeVisible();
      expect(await state(page)).toEqual(running);
      await page.goForward();
      await expect(closeButton(page)).toBeVisible();
      // Release only the synthetic server; the mounted production channel consumes SSE.
      const completed = await request.post(`${APP}e2e/hermes/reasoning-disclosure/complete`);
      expect(completed.ok()).toBe(true);
      expect(await completed.json()).toEqual({ run_id: 'run_1', session_id: 'e2e-hermes-session' });
      await expect.poll(async () => (await state(page)).last_turn_status).toBe('completed');
      await expect(closeButton(page)).toBeVisible();
      await page.keyboard.press('Escape');
      await expect(closeButton(page)).not.toBeVisible();
      await expect(page.getByRole('button', { name: 'Thought', exact: true })).toBeVisible();
      await expect(page.getByRole('group', { name: /Hermes echo: Synthetic overlay streaming request$/ })).toBeVisible();
      await expect(page.getByRole('group', { name: /E2E Hermes is ready\.$/ })).toBeVisible();
      expect(page.url()).toBe(location);
      expect(await state(page)).toMatchObject({ status: 'connected', active_session_id: 'e2e-hermes-session', has_error: false, last_turn_status: 'completed' });
      expect(writes).toEqual([{ method: 'POST', route: '/v1/runs' }]);
      expect(errors).toEqual([]);
    });

    for (const lateCompletion of [false, true]) {
      test(`${destination} does not restore the previous session after owner replacement${lateCompletion ? ' and late old-run completion' : ''} at ${width}px/200% text`, async ({ page, request }) => {
        expect((await request.post(`${APP}e2e/hermes/${lateCompletion ? 'reasoning-disclosure' : 'reset'}`)).ok()).toBe(true);
        const writes = [], errors = [];
        page.on('pageerror', error => errors.push(error.name));
        page.on('request', request => {
          const route = new URL(request.url()).pathname;
          if (/^\/(api|v1)\//.test(route) && request.method() !== 'GET') writes.push({ method: request.method(), route });
        });
        await page.setViewportSize({ width, height: 1000 });
        await page.goto(`${APP}?e2eTextScale=2#/hermes?view=synthetic-owner-overlay`);
        await ready(page);
        await page.evaluate(() => globalThis.wingE2EHermesConnect());
        const composer = page.getByRole('textbox', { name: 'Message Hermes…', exact: true });
        await expect(composer).toBeVisible();
        const before = await state(page);
        expect(before).toMatchObject({ status: 'connected', active_session_id: 'e2e-hermes-session', has_error: false });
        let stream;
        const prompt = 'Synthetic replaced overlay run';
        if (lateCompletion) {
          const response = page.waitForResponse(response => new URL(response.url()).pathname === '/v1/runs/run_1/events');
          await composer.click();
          await page.locator('input:focus, textarea:focus').fill(prompt);
          await page.getByRole('button', { name: 'Send', exact: true }).click();
          await expect(page.getByRole('button', { name: 'Thinking…', exact: true })).toBeVisible();
          expect(await state(page)).toMatchObject({ active_session_id: before.active_session_id, last_turn_status: 'streaming', has_error: false });
          stream = await response;
        }
        const location = page.url();
        await shellOpen(page, width, destination);
        // Drive an external session replacement through the existing production-channel seam.
        const createdResponse = page.waitForResponse(response => new URL(response.url()).pathname === '/api/sessions' && response.request().method() === 'POST');
        await page.evaluate(() => globalThis.wingE2EHermesCreateSession('Synthetic overlay replacement'));
        const response = await createdResponse;
        expect(response.ok()).toBe(true);
        const created = (await response.json()).session;
        expect(created.id).toEqual(expect.any(String));
        expect(created.id).not.toBe(before.active_session_id);
        await expect.poll(async () => (await state(page)).active_session_id).toBe(created.id);
        const replacement = await state(page);
        expect(replacement).toMatchObject({ status: 'connected', has_error: false, last_turn_status: null });
        expect(replacement.active_session_id).toEqual(expect.any(String));
        if (lateCompletion) {
          // Complete the original server-owned run only after replacement has settled.
          const completed = await request.post(`${APP}e2e/hermes/reasoning-disclosure/complete`);
          expect(completed.ok()).toBe(true);
          expect(await completed.json()).toEqual({ run_id: 'run_1', session_id: before.active_session_id });
          expect(await stream.finished()).toBeNull();
          const canonical = await request.get(`${APP}v1/runs/run_1`);
          expect(canonical.ok()).toBe(true);
          expect(await canonical.json()).toMatchObject({ run_id: 'run_1', session_id: before.active_session_id, status: 'completed', output: `Hermes echo: ${prompt}` });
          const history = await request.get(`${APP}api/sessions/${before.active_session_id}/messages`);
          expect(history.ok()).toBe(true);
          const messages = (await history.json()).data;
          const reply = messages.find(message => message.role === 'assistant' && message.content === `Hermes echo: ${prompt}`);
          expect(reply).toMatchObject({ session_id: before.active_session_id, id: expect.any(String) });
          // A canonical turn ID appears only after the production channel's final history reconciliation.
          await expect.poll(() => page.evaluate(id => JSON.parse(globalThis.wingE2EHermesSessionSummary(id)), before.active_session_id)).toEqual({ session_id: before.active_session_id, last_turn_id: reply.id, last_turn_status: 'completed' });
          expect(await state(page)).toEqual(replacement);
        }
        await expect(closeButton(page)).toBeVisible();
        await page.goBack();
        await expect(closeButton(page)).not.toBeVisible();
        await expect(composer).toBeVisible();
        expect(await state(page)).toEqual(replacement);
        await expect(page.getByRole('group', { name: /E2E Hermes is ready\.$/ })).not.toBeVisible();
        await expect(page.getByRole('button', { name: 'Thinking…', exact: true })).not.toBeVisible();
        if (lateCompletion) {
          await expect(page.getByRole('group', { name: new RegExp(`Hermes echo: ${prompt}$`) })).not.toBeVisible();
          await expect(page.getByRole('button', { name: 'Thought', exact: true })).not.toBeVisible();
        }
        await page.goForward();
        await expect(closeButton(page)).toBeVisible();
        expect(await state(page)).toEqual(replacement);
        await page.keyboard.press('Escape');
        await expect(closeButton(page)).not.toBeVisible();
        await expect(composer).toBeVisible();
        expect(await state(page)).toEqual(replacement);
        expect(page.url()).toBe(location);
        expect(writes).toEqual([...(lateCompletion ? [{ method: 'POST', route: '/v1/runs' }] : []), { method: 'POST', route: '/api/sessions' }]);
        expect(errors).toEqual([]);
      });
    }

    test(`direct ${destination} deep link returns to disconnected chat at ${width}px/200% text`, async ({ page }, testInfo) => {
      const writes = [];
      page.on('request', request => {
        const route = new URL(request.url()).pathname;
        if (/^\/(api|v1)\//.test(route) && request.method() !== 'GET') writes.push(request.method());
      });
      await page.setViewportSize({ width, height: 1000 });
      await page.goto(`${APP}?e2eTextScale=2#/${destination.toLowerCase()}`);
      await ready(page);
      await expect(closeButton(page)).toBeVisible();
      const before = await state(page);
      expect(before.status).toBe('disconnected');
      const actor = keyboardActor(page, testInfo, []);
      await actor.assertFocus('button', 'Close');
      await page.keyboard.press('Escape');
      await expect(closeButton(page)).not.toBeVisible();
      await expect(page).toHaveURL(/#\/hermes$/);
      expect(await state(page)).toEqual(before);
      expect(writes).toEqual([]);
    });
  }
}
