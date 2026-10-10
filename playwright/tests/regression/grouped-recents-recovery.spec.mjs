import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor, focusedNode, scopedInventory } from '../../support/inventory_keyboard.mjs';

test.describe.configure({ retries: 0 });

test('grouped recents keyboard hide/return and pending exact-owner rejection', async ({ page, request }, testInfo) => {
  test.setTimeout(120000);
  const trace = [], requests = [], errors = [], phases = [];
  const actor = keyboardActor(page, testInfo, trace);
  const id = 'synthetic-recents-recovery';
  const history = `/api/sessions/${id}/messages`;
  let release;
  page.on('pageerror', error => errors.push(error.message));
  page.on('request', r => {
    const url = new URL(r.url());
    if (/^\/(api|v1|health)(\/|$)/.test(url.pathname)) requests.push({ method: r.method(), path: url.pathname, query: Object.fromEntries(url.searchParams), body: r.postDataJSON() });
  });
  const state = () => page.evaluate(() => {
    const s = JSON.parse(globalThis.wingE2EHermesStateSummary());
    return { profile: s.selected_profile_id, session: s.active_session_id, status: s.status, error: s.has_error };
  });
  const initial = { profile: 'default', session: 'e2e-hermes-session', status: 'connected', error: false };
  const exactRead = { method: 'GET', path: history, query: { profile: 'default', limit: '500', offset: '0', order: 'latest' }, body: null };
  let rowName;
  const absent = async () => {
    await expect(actor.control('button', rowName)).toHaveCount(0);
    await expect(actor.control('button', 'New Session')).toHaveCount(0);
    await expect(page.getByRole('heading', { name: 'Source: e2e', exact: true })).toHaveCount(0);
    for (const direction of ['Tab', 'Shift+Tab']) {
      for (let i = 0; i < 8; i++) {
        await actor.press(direction);
        expect((await focusedNode(page)).name).not.toMatch(/^Open |^New Session$/);
      }
    }
  };
  const restoreFocus = async slug => {
    await actor.reach('button', rowName);
    const row = await actor.assertFocus('button', rowName);
    const focused = await row.screenshot({ animations: 'disabled' });
    await actor.press('Shift+Tab');
    const unfocused = await row.screenshot({ animations: 'disabled' });
    expect(focused.equals(unfocused), 'same restored row paints keyboard focus').toBe(false);
    await testInfo.attach(`${slug}-focused.png`, { body: focused, contentType: 'image/png' });
    await testInfo.attach(`${slug}-unfocused.png`, { body: unfocused, contentType: 'image/png' });
    await actor.press('Tab');
    await actor.assertFocus('button', rowName);
    await actor.press('Tab');
    await actor.reach('button', rowName, 'Shift+Tab');
  };
  const hideReturn = async mode => {
    if (mode === 'collapse') {
      await actor.reach('button', 'Collapse'); await actor.press('Space');
      await absent();
      await actor.reach('button', 'Expand', 'Shift+Tab'); await actor.press('Enter');
    } else {
      await page.setViewportSize({ width: 390, height: 844 });
      await absent();
      await testInfo.attach('compact-hidden.png', { body: await page.screenshot({ animations: 'disabled' }), contentType: 'image/png' });
      await page.setViewportSize({ width: 1280, height: 600 });
    }
    await expect(actor.control('button', rowName)).toHaveCount(1);
    await expect(page.getByRole('heading', { name: 'Source: e2e', exact: true })).toHaveCount(1);
  };
  const tools = async () => {
    await actor.reach('button', 'Tools', 'Shift+Tab'); await actor.press('Enter');
    await expect(page).toHaveURL(/#\/tools$/);
  };
  const pending = async () => {
    let fetched;
    const ready = new Promise(resolve => { fetched = resolve; });
    const gate = new Promise(resolve => { release = resolve; });
    await page.route(`**${history}?*`, async route => {
      // Hold an actual deterministic response, not a fabricated success payload.
      const response = await route.fetch();
      fetched();
      await gate;
      await route.fulfill({ response });
    });
    await actor.reach('button', rowName);
    await actor.press('Enter');
    await ready;
    await expect(page).toHaveURL(/#\/tools$/);
    await expect(page.getByText('Opening session…', { exact: true })).toHaveCount(1);
    await expect(actor.control('button', rowName)).toBeDisabled();
  };
  const finishPending = async () => {
    const response = page.waitForResponse(r => new URL(r.url()).pathname === history);
    release();
    await response;
    await page.unroute(`**${history}?*`);
    await expect(page.getByText('Opening session…', { exact: true })).toHaveCount(0);
    await expect(page).toHaveURL(/#\/tools$/);
    await expect.poll(state).toEqual(initial);
  };
  try {
    expect((await request.post(`${APP}e2e/hermes/reset`)).ok()).toBe(true);
    const seed = await request.post(`${APP}api/sessions`, { data: { id } });
    expect(seed.ok()).toBe(true);
    const seeded = (await seed.json()).session;
    expect(seeded.id).toBe(id);
    rowName = `Open ${seeded.title}`;
    await scopedInventory(page, ['sessions', 'session_create', 'session_messages']);
    await page.setViewportSize({ width: 1280, height: 600 });
    await page.goto(`${APP}#/tools`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
    await enableFlutterAccessibility(page, { delay: 0 });
    await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
    await expect.poll(state).toEqual(initial);
    const bootstrap = requests.slice();
    phases.push({ phase: 'initial explicit fixture connection', requests: bootstrap });
    for (const [mode, key] of [['collapse', 'Enter'], ['compact', 'Space']]) {
      const start = requests.length;
      await actor.reach('button', rowName);
      await hideReturn(mode);
      await restoreFocus(mode);
      expect(requests.slice(start)).toEqual([]);
      await actor.press(key);
      await expect(page).toHaveURL(/#\/hermes$/);
      await expect.poll(state).toEqual({ ...initial, session: id });
      expect(requests.slice(start)).toEqual([exactRead]);
      await tools();
      expect(requests.slice(start)).toEqual([exactRead]);
      phases.push({ phase: `${mode} return + explicit ${key} Open`, requests: requests.slice(start) });
    }
    // Restore the initial tuple explicitly; later replacement keeps identical
    // origin/profile/loaded IDs but is a distinct connection generation.
    const resetStart = requests.length;
    await page.evaluate(() => globalThis.wingE2EHermesConnect());
    await expect.poll(state).toEqual(initial);
    expect(requests.slice(resetStart)).toEqual(bootstrap);
    phases.push({ phase: 'explicit fixture reconnect setup', requests: requests.slice(resetStart) });
    for (const mode of ['collapse', 'compact', 'identical-owner']) {
      const start = requests.length;
      await pending();
      expect(requests.slice(start)).toEqual([exactRead]);
      if (mode === 'identical-owner') {
        const reconnectStart = requests.length;
        await page.evaluate(() => globalThis.wingE2EHermesConnect());
        await expect.poll(state).toEqual(initial);
        expect(requests.slice(reconnectStart)).toEqual(bootstrap);
        phases.push({ phase: 'explicit identical-tuple connection replacement', requests: requests.slice(reconnectStart) });
      } else {
        await hideReturn(mode);
        expect(requests.slice(start)).toEqual([exactRead]);
      }
      await finishPending();
      const settled = requests.length;
      await restoreFocus(`pending-${mode}-return`);
      expect(requests.slice(settled)).toEqual([]);
      expect(requests.slice(start)).toEqual(mode === 'identical-owner' ? [exactRead, ...bootstrap] : [exactRead]);
      phases.push({ phase: `pending ${mode} invalidation and late response`, requests: requests.slice(start) });
    }
    const explicitStart = requests.length;
    await actor.press('Space');
    await expect(page).toHaveURL(/#\/hermes$/);
    await expect.poll(state).toEqual({ ...initial, session: id });
    expect(requests.slice(explicitStart)).toEqual([exactRead]);
    expect(requests.filter(r => r.path === history)).toEqual(Array(6).fill(exactRead));
    expect(requests.filter(r => r.method !== 'GET')).toEqual([]);
    expect(errors).toEqual([]);
    await testInfo.attach('wide-return.png', { body: await page.screenshot({ animations: 'disabled' }), contentType: 'image/png' });
  } finally {
    release?.();
    await testInfo.attach('grouped-recents-recovery-receipt.json', { contentType: 'application/json', body: JSON.stringify({ trace, phases, requests, errors, final: await state(), qualification: 'fresh compiled deterministic Chromium; not native/live/screen-reader' }, null, 2) });
    await testInfo.attach('grouped-recents-recovery-semantics.txt', { contentType: 'text/plain', body: await page.locator('body').ariaSnapshot() });
  }
});
