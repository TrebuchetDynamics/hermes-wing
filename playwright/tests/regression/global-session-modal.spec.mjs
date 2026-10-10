import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor, focusedNode, scopedInventory } from '../../support/inventory_keyboard.mjs';

test.describe.configure({ retries: 0 });

test('keyboard New retries only acknowledged history after partial success', async ({ page, request }, testInfo) => {
  const writes = [], reads = [];
  const actor = keyboardActor(page, testInfo, []);
  expect((await request.post(`${APP}e2e/hermes/reset`)).ok()).toBe(true);
  await scopedInventory(page, ['sessions', 'session_create', 'session_messages']);
  await page.goto(`${APP}#/tools`);
  await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
  await enableFlutterAccessibility(page, { delay: 0 });
  await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
  await page.waitForFunction(() => JSON.parse(globalThis.wingE2EHermesStateSummary()).status === 'connected');
  page.on('request', r => {
    const path = new URL(r.url()).pathname;
    if (r.method() === 'POST' && path === '/api/sessions') writes.push(r.postDataJSON());
    if (r.method() === 'GET' && path.endsWith('/messages')) reads.push(path);
  });
  let fail = true;
  await page.route('**/api/sessions/*/messages?*', route => fail
    ? route.fulfill({ status: 503, contentType: 'application/json', body: '{"error":"synthetic history failure"}' })
    : route.continue());
  await actor.reach('button', 'Sessions');
  await page.keyboard.press('Control+k');
  await actor.reach('button', 'New');
  await actor.press('Space');
  const retry = page.getByRole('button', { name: 'Retry', exact: true });
  await expect(retry).toHaveCount(1);
  expect(writes).toHaveLength(1);
  const id = writes[0].id;
  await expect.poll(() => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()).active_session_id)).toBe(id);
  await expect(page).toHaveURL(/#\/tools$/);
  fail = false;
  await actor.reach('button', 'Retry');
  await actor.press('Space');
  await expect(page).toHaveURL(/#\/hermes$/);
  await expect(page.getByRole('dialog')).toHaveCount(0);
  expect(writes).toHaveLength(1);
  expect(reads).toEqual([`/api/sessions/${id}/messages`, `/api/sessions/${id}/messages`]);
  await testInfo.attach('new-history-retry-receipt.json', {
    contentType: 'application/json', body: JSON.stringify({ writes, reads, qualification: 'compiled deterministic Chromium' }),
  });
});

test('global full panel is contained, cancellable and acknowledges exact keyboard intent', async ({ page, request }, testInfo) => {
  const trace = [], requests = [], errors = [];
  const actor = keyboardActor(page, testInfo, trace);
  page.on('pageerror', e => errors.push(e.message));
  page.on('request', r => {
    const url = new URL(r.url());
    if (/^\/(api|v1|health)(\/|$)/.test(url.pathname)) requests.push({ method: r.method(), path: url.pathname, query: Object.fromEntries(url.searchParams), body: r.postDataJSON() });
  });
  const state = () => page.evaluate(() => {
    const s = JSON.parse(globalThis.wingE2EHermesStateSummary());
    return { profile: s.selected_profile_id, session: s.active_session_id, status: s.status };
  });
  const search = page.getByRole('textbox', { name: 'Search sessions', exact: true });
  const dialog = page.getByRole('dialog');
  const focusedInside = () => dialog.evaluate(node => {
    let active = document.activeElement;
    while (active?.shadowRoot?.activeElement) active = active.shadowRoot.activeElement;
    return node.contains(active);
  });
  let seedTitle;
  let row;
  const reachRow = async () => {
    await expect(row).toHaveCount(1);
    for (let i = 0; i < 32; i++) {
      if (await row.evaluate(node => node === document.activeElement || node.contains(document.activeElement))) return;
      await actor.press('Tab');
    }
    throw new Error('row unreachable by Tab');
  };
  try {
    expect((await request.post(`${APP}e2e/hermes/reset`)).ok()).toBe(true);
    const seed = await request.post(`${APP}api/sessions`, { data: { id: 'synthetic-modal-other' } });
    expect(seed.ok()).toBe(true);
    const seeded = (await seed.json()).session;
    expect(seeded.id).toBe('synthetic-modal-other');
    seedTitle = seeded.title;
    row = page.getByRole('button', { name: new RegExp(seedTitle) });
    await scopedInventory(page, ['sessions', 'session_create', 'session_messages']);
    await page.goto(`${APP}#/tools`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
    await enableFlutterAccessibility(page, { delay: 0 });
    await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
    await expect.poll(state).toEqual({ profile: 'default', session: 'e2e-hermes-session', status: 'connected' });
    const baseline = requests.length;
    await actor.reach('button', 'Sessions');
    await actor.visibleFocus('button', 'Sessions', 'modal-opener');
    await actor.press('Enter');
    await expect(dialog).toHaveCount(1);
    await expect(search).toBeFocused();
    await expect(page).toHaveURL(/#\/tools$/);
    for (const key of ['Tab', 'Shift+Tab']) {
      if (key === 'Tab') await testInfo.attach('global-session-panel.png', { body: await page.screenshot({ animations: 'disabled' }), contentType: 'image/png' });
      for (let i = 0; i < 16; i++) {
        await actor.press(key);
        expect(await focusedInside()).toBe(true);
      }
    }
    await page.keyboard.press('Escape');
    await expect(dialog).toHaveCount(0);
    await actor.assertFocus('button', 'Sessions');
    await page.keyboard.down('Enter');
    await expect(dialog).toHaveCount(1);
    await page.keyboard.press('Escape');
    await expect(dialog).toHaveCount(0);
    await page.keyboard.down('Enter'); // real repeated keydown while held
    await expect(dialog).toHaveCount(0);
    await page.keyboard.up('Enter');
    await actor.assertFocus('button', 'Sessions');
    expect(requests.slice(baseline)).toEqual([]);
    await page.keyboard.press('Meta+k');
    await expect(dialog).toHaveCount(1);
    await expect(search).toBeFocused();
    await actor.reach('button', 'Close', 'Shift+Tab');
    await actor.press('Space');
    await expect(dialog).toHaveCount(0);
    await actor.assertFocus('button', 'Sessions');
    await page.keyboard.press('Control+k');
    await expect(dialog).toHaveCount(1);
    await expect(search).toBeFocused();
    await page.keyboard.type(seedTitle);
    await expect(search).toHaveValue(seedTitle);
    await reachRow();
    const bounds = await row.boundingBox();
    const focused = await page.screenshot({ clip: bounds, animations: 'disabled' });
    await actor.press('Tab');
    const unfocused = await page.screenshot({ clip: bounds, animations: 'disabled' });
    expect(focused.equals(unfocused)).toBe(false);
    await testInfo.attach('modal-row-focused.png', { body: focused, contentType: 'image/png' });
    await actor.press('Shift+Tab');
    // Delay the real fixture response to prove cancellation and acknowledgement.
    let release;
    const gate = new Promise(resolve => { release = resolve; });
    await page.route('**/api/sessions/synthetic-modal-other/messages?*', async route => { await gate; await route.continue(); });
    await actor.press('Enter');
    await expect.poll(() => requests.slice(baseline).length).toBe(1);
    await expect(page).toHaveURL(/#\/tools$/);
    await page.keyboard.press('Escape');
    await expect(dialog).toHaveCount(0);
    release();
    await page.waitForResponse(r => new URL(r.url()).pathname === '/api/sessions/synthetic-modal-other/messages');
    await expect.poll(state).toEqual({ profile: 'default', session: 'e2e-hermes-session', status: 'connected' });
    await expect(page).toHaveURL(/#\/tools$/);
    await page.unroute('**/api/sessions/synthetic-modal-other/messages?*');
    await page.keyboard.press('Control+k');
    await expect(search).toBeFocused();
    await page.keyboard.type(seedTitle);
    await reachRow();
    await actor.press('Space');
    await expect(page).toHaveURL(/#\/hermes$/);
    await expect(dialog).toHaveCount(0);
    await expect.poll(state).toEqual({ profile: 'default', session: 'synthetic-modal-other', status: 'connected' });
    const exactRead = { method: 'GET', path: '/api/sessions/synthetic-modal-other/messages', query: { profile: 'default', limit: '500', offset: '0', order: 'latest' }, body: null };
    expect(requests.slice(baseline)).toEqual([exactRead, exactRead]);
    expect(errors).toEqual([]);
    await testInfo.attach('global-session-modal.png', { body: await page.screenshot({ animations: 'disabled' }), contentType: 'image/png' });
  } finally {
    await page.screenshot({ path: 'build/global-session-modal-current.png', animations: 'disabled' });
    await testInfo.attach('global-session-modal-receipt.json', { contentType: 'application/json', body: JSON.stringify({ trace, requests, errors, focus: await focusedNode(page), qualification: 'compiled deterministic Chromium only' }) });
    await testInfo.attach('global-session-modal-semantics.txt', { contentType: 'text/plain', body: await page.locator('body').ariaSnapshot() });
  }
});
