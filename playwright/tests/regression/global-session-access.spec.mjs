import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor, scopedInventory } from '../../support/inventory_keyboard.mjs';

test.describe.configure({ retries: 0 });

test('global loaded sessions open exact identity from Tools, create once and recover compact navigation', async ({ page, request }, testInfo) => {
  const trace = [], requests = [], errors = [];
  const actor = keyboardActor(page, testInfo, trace);
  page.on('pageerror', error => errors.push(error.message));
  page.on('request', request => {
    const url = new URL(request.url());
    if (/^\/(api|v1|health)(\/|$)/.test(url.pathname)) {
      requests.push({ method: request.method(), path: url.pathname, query: Object.fromEntries(url.searchParams), body: request.postDataJSON() });
    }
  });
  const state = () => page.evaluate(() => {
    const state = JSON.parse(globalThis.wingE2EHermesStateSummary());
    return { profile: state.selected_profile_id, session: state.active_session_id, status: state.status };
  });
  try {
    // Setup is confined to this test and the existing deterministic API fixture.
    expect((await request.post(`${APP}e2e/hermes/reset`)).ok()).toBe(true);
    const seed = await request.post(`${APP}api/sessions`, { data: { id: 'synthetic-global-other', title: 'Synthetic global other' } });
    expect(seed.ok()).toBe(true);
    const seeded = (await seed.json()).session;
    expect(seeded.id).toBe('synthetic-global-other');
    const openOther = `Open ${seeded.title}`;
    await scopedInventory(page, ['sessions', 'session_create', 'session_messages']);
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.goto(`${APP}#/tools`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
    await enableFlutterAccessibility(page, { delay: 0 });
    await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
    await expect.poll(state).toEqual({ profile: 'default', session: 'e2e-hermes-session', status: 'connected' });
    await expect(page.getByRole('group', { name: 'Loaded sessions', exact: true })).toHaveCount(1);
    const baseline = requests.length;
    await actor.reach('button', openOther);
    await actor.visibleFocus('button', openOther, 'global-open');
    expect(requests.slice(baseline)).toEqual([]);
    await actor.press('Enter');
    await expect(page).toHaveURL(/#\/hermes$/);
    await expect.poll(state).toEqual({ profile: 'default', session: 'synthetic-global-other', status: 'connected' });
    const opened = requests.slice(baseline);
    expect(opened).toEqual([{ method: 'GET', path: '/api/sessions/synthetic-global-other/messages', query: { profile: 'default', limit: '500', offset: '0', order: 'latest' }, body: null }]);
    await actor.reach('button', 'Tools'); await actor.press('Space');
    await expect(page).toHaveURL(/#\/tools$/);
    expect(requests.slice(baseline)).toEqual(opened);
    const beforeCreate = requests.length;
    await actor.reach('button', 'New Session', 'Shift+Tab');
    await actor.visibleFocus('button', 'New Session', 'global-new');
    await actor.press('Space');
    await expect(page).toHaveURL(/#\/hermes$/);
    const created = await state();
    expect(created.profile).toBe('default'); expect(created.status).toBe('connected');
    expect(created.session).not.toBe('synthetic-global-other'); expect(created.session).not.toBe('e2e-hermes-session');
    const createRequests = requests.slice(beforeCreate);
    expect(createRequests).toHaveLength(2);
    expect(createRequests[0]).toEqual({ method: 'POST', path: '/api/sessions', query: { profile: 'default' }, body: { id: created.session } });
    expect(createRequests[1]).toEqual({ method: 'GET', path: `/api/sessions/${created.session}/messages`, query: { profile: 'default', limit: '500', offset: '0', order: 'latest' }, body: null });
    const beforeLayout = requests.length;
    await actor.reach('button', 'Tools', 'Shift+Tab'); await actor.press('Enter');
    await actor.reach('button', 'Collapse'); await actor.press('Space');
    await expect(actor.control('button', 'New Session')).toHaveCount(0);
    await expect(actor.control('button', openOther)).toHaveCount(0);
    await actor.reach('button', 'Expand'); await actor.press('Enter');
    await expect(actor.control('button', openOther)).toHaveCount(1);
    await page.setViewportSize({ width: 390, height: 844 });
    await expect(actor.control('button', 'New Session')).toHaveCount(0);
    await actor.reach('tab', 'More'); await actor.press('Enter');
    await actor.reach('button', 'Settings'); await actor.press('Space');
    await expect(page.getByRole('heading', { name: 'Settings', exact: true })).toBeVisible();
    await actor.reach('tab', 'Chat'); await actor.press('Enter');
    await expect(page).toHaveURL(/#\/hermes$/);
    await page.setViewportSize({ width: 1280, height: 900 });
    await expect(actor.control('button', 'New Session')).toHaveCount(1);
    expect(await state()).toEqual(created);
    expect(requests.slice(beforeLayout)).toEqual([]);
    expect(errors).toEqual([]);
    expect(requests.filter(r => r.method !== 'GET')).toEqual([createRequests[0]]);
  } finally {
    await testInfo.attach('global-session-receipt.json', { contentType: 'application/json', body: JSON.stringify({ trace, requests, errors, target: 'compiled deterministic Chromium only; no native/live qualification' }) });
    await testInfo.attach('global-session-semantics.txt', { contentType: 'text/plain', body: await page.locator('body').ariaSnapshot() });
  }
});
