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

async function shellOpen(page, width, destination) {
  if (width < 600) {
    await page.getByRole('tab', { name: destination === 'Settings' ? 'More' : 'Profiles', exact: true }).click();
    if (destination === 'Settings') await page.getByText('Settings', { exact: true }).last().click();
  } else {
    await page.getByRole('button', { name: destination === 'Settings' ? /^Settings(?: Settings)?$/ : 'Profiles', exact: true }).click();
  }
  await expect(closeButton(page)).toBeVisible();
}

for (const width of [390, 1280]) {
  for (const destination of ['Settings', 'Profiles']) {
    test(`${destination} retains chat through Back/Forward, Escape and Close at ${width}px/200% text`, async ({ page, request }, testInfo) => {
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
      await shellOpen(page, width, destination);
      await expect.poll(() => page.evaluate(() => history.length)).toBe(length + 1);
      await actor.assertFocus('button', 'Close');
      await actor.press('Tab');
      await expect(composer).not.toBeVisible();
      await actor.press('Shift+Tab');
      await actor.assertFocus('button', 'Close');
      await page.goBack();
      await expect(closeButton(page)).not.toBeVisible();
      await expect(composer).toBeVisible();
      await composer.click();
      await expect(page.locator('input:focus, textarea:focus')).toHaveValue(draft);
      expect(page.url()).toBe(location);
      await expect(page.getByRole('group', { name: /E2E Hermes is ready\.$/ })).toBeVisible();
      await page.goForward();
      await expect(closeButton(page)).toBeVisible();
      await page.keyboard.press('Escape');
      await expect(closeButton(page)).not.toBeVisible();
      await expect(composer).toBeVisible();
      await shellOpen(page, width, destination);
      await actor.assertFocus('button', 'Close');
      await actor.press('Enter');
      await expect(closeButton(page)).not.toBeVisible();
      await composer.click();
      await expect(page.locator('input:focus, textarea:focus')).toHaveValue(draft);
      expect(page.url()).toBe(location);
      expect(await state(page)).toEqual(before);
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

    test(`${destination} does not restore the previous session after owner replacement at ${width}px/200% text`, async ({ page, request }) => {
      expect((await request.post(`${APP}e2e/hermes/reset`)).ok()).toBe(true);
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
      await expect(closeButton(page)).toBeVisible();
      await page.goBack();
      await expect(closeButton(page)).not.toBeVisible();
      await expect(composer).toBeVisible();
      expect(await state(page)).toEqual(replacement);
      await expect(page.getByRole('group', { name: /E2E Hermes is ready\.$/ })).not.toBeVisible();
      await expect(page.getByRole('button', { name: 'Thinking…', exact: true })).not.toBeVisible();
      await page.goForward();
      await expect(closeButton(page)).toBeVisible();
      expect(await state(page)).toEqual(replacement);
      await page.keyboard.press('Escape');
      await expect(closeButton(page)).not.toBeVisible();
      await expect(composer).toBeVisible();
      expect(await state(page)).toEqual(replacement);
      expect(page.url()).toBe(location);
      expect(writes).toEqual([{ method: 'POST', route: '/api/sessions' }]);
      expect(errors).toEqual([]);
    });

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
