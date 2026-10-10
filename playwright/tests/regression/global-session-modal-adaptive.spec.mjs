import { mkdir, writeFile, rm } from 'node:fs/promises';
import path from 'node:path';
import { test, expect, chromium } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor, focusedNode, scopedInventory } from '../../support/inventory_keyboard.mjs';

test.describe.configure({ retries: 0 });
for (const initial of [390, 1280]) {
  test(`200% zoom global panel keyboard resize and delayed route replacement from ${initial}`, async ({ request }, testInfo) => {
    test.setTimeout(120000);
    const profile = testInfo.outputPath('zoom-profile');
    await mkdir(path.join(profile, 'Default'), { recursive: true });
    await writeFile(path.join(profile, 'Default', 'Preferences'), JSON.stringify({
      partition: { default_zoom_level: { x: Math.log(2) / Math.log(1.2) } },
    }));
    const context = await chromium.launchPersistentContext(profile, {
      executablePath: process.env.CHROME_EXECUTABLE, headless: true,
      viewport: { width: initial * 2, height: 1400 }, reducedMotion: 'reduce',
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });
    const page = context.pages()[0];
    const trace = [], requests = [], errors = [], renders = [];
    const actor = keyboardActor(page, testInfo, trace);
    const dialog = page.getByRole('dialog');
    const search = page.getByRole('textbox', { name: 'Search sessions', exact: true });
    const state = () => page.evaluate(() => {
      const s = JSON.parse(globalThis.wingE2EHermesStateSummary());
      return { profile: s.selected_profile_id, session: s.active_session_id, status: s.status };
    });
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => {
      if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(message.text())) errors.push(message.text());
    });
    page.on('request', r => {
      const url = new URL(r.url());
      if (/^\/(api|v1|health)(\/|$)/.test(url.pathname)) requests.push({
        method: r.method(), path: url.pathname, query: Object.fromEntries(url.searchParams), body: r.postDataJSON(),
      });
    });
    let release;
    const inViewport = async locator => {
      const bounds = await locator.boundingBox();
      const metrics = await page.evaluate(() => ({ width: innerWidth, height: innerHeight }));
      expect(bounds.x).toBeGreaterThanOrEqual(0);
      expect(bounds.y).toBeGreaterThanOrEqual(0);
      expect(bounds.x + bounds.width).toBeLessThanOrEqual(metrics.width);
      expect(bounds.y + bounds.height).toBeLessThanOrEqual(metrics.height);
    };
    const render = async slug => {
      const metrics = await page.evaluate(() => ({ width: innerWidth, height: innerHeight,
        dpr: devicePixelRatio, reducedMotion: matchMedia('(prefers-reduced-motion: reduce)').matches }));
      expect(metrics.dpr).toBe(2);
      expect(metrics.reducedMotion).toBe(true);
      const bounds = await dialog.boundingBox();
      expect(bounds.x).toBeGreaterThanOrEqual(0);
      expect(bounds.y).toBeGreaterThanOrEqual(0);
      expect(bounds.x + bounds.width).toBeLessThanOrEqual(metrics.width);
      expect(bounds.y + bounds.height).toBeLessThanOrEqual(metrics.height);
      renders.push({ slug, metrics, bounds, focused: await focusedNode(page) });
      await testInfo.attach(`${slug}.png`, { body: await page.screenshot({ animations: 'disabled' }), contentType: 'image/png' });
    };
    try {
      expect((await request.post(`${APP}e2e/hermes/reset`)).ok()).toBe(true);
      const seed = await request.post(`${APP}api/sessions`, { data: { id: 'synthetic-adaptive-other' } });
      expect(seed.ok()).toBe(true);
      const title = (await seed.json()).session.title;
      const row = page.getByRole('button', { name: new RegExp(title) });
      const reachRow = async () => {
        for (let i = 0; i < 32; i++) {
          if (await row.count() && await row.evaluate(node => node === document.activeElement || node.contains(document.activeElement))) {
            const bounds = await row.boundingBox();
            const metrics = await page.evaluate(() => ({ width: innerWidth, height: innerHeight }));
            expect(bounds.x).toBeGreaterThanOrEqual(0);
            expect(bounds.y).toBeGreaterThanOrEqual(0);
            expect(bounds.x + bounds.width).toBeLessThanOrEqual(metrics.width);
            expect(bounds.y + bounds.height).toBeLessThanOrEqual(metrics.height);
            return;
          }
          await actor.press('Tab');
        }
        throw new Error('Filtered row unreachable by real Tab');
      };
      await scopedInventory(page, ['sessions', 'session_create', 'session_messages']);
      await page.goto(`${APP}#/tools`);
      await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
      await enableFlutterAccessibility(page, { delay: 0 });
      await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
      await expect.poll(state).toEqual({ profile: 'default', session: 'e2e-hermes-session', status: 'connected' });
      const baseline = requests.length;
      const openerRole = initial === 390 ? 'tab' : 'button';
      const openerName = initial === 390 ? 'More' : 'Sessions';
      await actor.reach(openerRole, openerName);
      await page.keyboard.press('Control+k');
      await expect(search).toBeFocused();
      for (const [width, height] of [[1280, 700], [390, 700], [390, 480], [initial, 700]]) {
        await page.setViewportSize({ width: width * 2, height: height * 2 });
        // Flutter's dialog semantics spans the modal route; the search bounds
        // measure the actual 720px panel (or compact inset-constrained panel).
        await expect.poll(async () => (await search.boundingBox())?.width).toBe(width === 390 ? 286 : 696);
        await expect(search).toBeFocused();
        await inViewport(search);
        await actor.reach('button', 'New', 'Shift+Tab');
        await inViewport(page.getByRole('button', { name: 'New', exact: true }));
        await actor.reach('button', 'Close', 'Shift+Tab');
        await inViewport(page.getByRole('button', { name: 'Close', exact: true }));
        await actor.reach('textbox', 'Search sessions');
        await render(`panel-${width}-${height}`);
        for (const key of ['Tab', 'Shift+Tab']) {
          for (let i = 0; i < 10; i++) {
            await actor.press(key);
            expect(await dialog.evaluate(node => node.contains(document.activeElement))).toBe(true);
          }
        }
        await actor.reach('textbox', 'Search sessions');
      }
      await page.keyboard.press('Escape');
      await expect(dialog).toHaveCount(0);
      // Crossing shell breakpoints disposes the sidebar/bottom-tab opener.
      // The remounted control must remain keyboard-reachable; restoration is
      // asserted only for a surviving opener in the next open/close cycle.
      await actor.reach(openerRole, openerName);
      expect(requests.slice(baseline)).toEqual([]);
      await page.keyboard.press('Control+k');
      await expect(search).toBeFocused();
      await page.keyboard.press('Escape');
      await expect(dialog).toHaveCount(0);
      await actor.assertFocus(openerRole, openerName);
      await page.keyboard.press('Control+k');
      await expect(search).toBeFocused();
      await actor.reach('button', 'Close', 'Shift+Tab');
      await actor.press('Space');
      await expect(dialog).toHaveCount(0);
      await actor.assertFocus(openerRole, openerName);
      await page.keyboard.press('Control+k');
      await expect(search).toBeFocused();
      await page.keyboard.type(title);
      await expect(search).toHaveValue(title);
      await reachRow();
      await render('filtered-row');
      const gate = new Promise(resolve => { release = resolve; });
      await page.route('**/api/sessions/synthetic-adaptive-other/messages?*', async route => { await gate; await route.continue(); });
      await actor.press('Enter');
      await expect.poll(() => requests.slice(baseline).length).toBe(1);
      await expect(page).toHaveURL(/#\/tools$/);
      await page.keyboard.press('Escape');
      await expect(dialog).toHaveCount(0);
      await page.setViewportSize({ width: 2560, height: 1400 });
      await actor.reach('button', 'Settings');
      await actor.press('Enter');
      await expect(page).toHaveURL(/#\/settings$/);
      const response = page.waitForResponse(r => new URL(r.url()).pathname === '/api/sessions/synthetic-adaptive-other/messages');
      release();
      await response;
      await expect.poll(state).toEqual({ profile: 'default', session: 'e2e-hermes-session', status: 'connected' });
      await expect(page).toHaveURL(/#\/settings$/);
      await page.unroute('**/api/sessions/synthetic-adaptive-other/messages?*');
      await page.keyboard.press('Control+k');
      await expect(search).toBeFocused();
      await page.keyboard.type(title);
      await reachRow();
      await actor.press('Space');
      await expect(page).toHaveURL(/#\/hermes$/);
      await expect(dialog).toHaveCount(0);
      await expect.poll(state).toEqual({ profile: 'default', session: 'synthetic-adaptive-other', status: 'connected' });
      const exactRead = { method: 'GET', path: '/api/sessions/synthetic-adaptive-other/messages', query: { profile: 'default', limit: '500', offset: '0', order: 'latest' }, body: null };
      expect(requests.slice(baseline)).toEqual([exactRead, exactRead]);
      await actor.reach('button', 'Tools', 'Shift+Tab');
      await actor.press('Enter');
      const beforeNew = requests.length;
      await page.keyboard.press('Control+k');
      await expect(search).toBeFocused();
      await page.setViewportSize({ width: 780, height: 1400 });
      await expect.poll(async () => (await search.boundingBox())?.width).toBe(286);
      await actor.reach('button', 'New', 'Shift+Tab');
      await render('compact-new-focused');
      await actor.press('Space');
      await expect(dialog).toHaveCount(0);
      await expect(page).toHaveURL(/#\/hermes$/);
      const created = await state();
      expect(created.session).not.toBe('synthetic-adaptive-other');
      expect(requests.slice(beforeNew)).toEqual([
        { method: 'POST', path: '/api/sessions', query: { profile: 'default' }, body: { id: created.session } },
        { method: 'GET', path: `/api/sessions/${created.session}/messages`, query: { profile: 'default', limit: '500', offset: '0', order: 'latest' }, body: null },
      ]);
      expect(requests.slice(baseline).filter(r => r.method !== 'GET')).toHaveLength(1);
      expect(errors).toEqual([]);
    } finally {
      release?.();
      await testInfo.attach('adaptive-receipt.json', { body: JSON.stringify({ initial, trace, requests, renders, errors,
        qualification: 'compiled deterministic Chromium at native 200% zoom; Flutter 200% textScaler separately widget-tested' }, null, 2), contentType: 'application/json' });
      await testInfo.attach('adaptive-semantics.txt', { body: await page.locator('body').ariaSnapshot(), contentType: 'text/plain' });
      await context.close();
      await rm(profile, { recursive: true, force: true });
    }
  });
}
