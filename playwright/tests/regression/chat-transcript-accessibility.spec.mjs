import { mkdir, writeFile, rm } from 'node:fs/promises';
import path from 'node:path';
import { test, expect, chromium } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor } from '../../support/inventory_keyboard.mjs';

test.describe.configure({ retries: 0 });
for (const recovery of ['reconnect', 'reload']) {
  test(`canonical transcript ${recovery} and viewport remount never replay`, async ({ request }, testInfo) => {
    test.setTimeout(180000);
    const profile = testInfo.outputPath('zoom-profile');
    await mkdir(path.join(profile, 'Default'), { recursive: true });
    await writeFile(path.join(profile, 'Default', 'Preferences'), JSON.stringify({
      partition: { default_zoom_level: { x: Math.log(2) / Math.log(1.2) } },
    }));
    const context = await chromium.launchPersistentContext(profile, {
      executablePath: process.env.CHROME_EXECUTABLE, headless: true,
      viewport: { width: 2560, height: 2200 }, reducedMotion: 'reduce',
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });
    const page = context.pages()[0];
    const trace = [], requests = [], errors = [], orders = [], receipts = [];
    const actor = keyboardActor(page, testInfo, trace);
    const visibleZoomFocus = async (role, name, slug) => {
      const locator = await actor.assertFocus(role, name);
      const bounds = await locator.boundingBox();
      // Chromium's screenshot clip uses pre-zoom viewport coordinates, unlike
      // the semantic DOM's CSS-pixel bounding boxes at browser zoom.
      const zoom = page.viewportSize().width / await page.evaluate(() => innerWidth);
      const clip = { x: (bounds.x - 4) * zoom, y: (bounds.y - 4) * zoom,
        width: (bounds.width + 8) * zoom, height: (bounds.height + 8) * zoom };
      const focused = await page.screenshot({ clip, animations: 'disabled' });
      let steps = 0;
      do {
        await actor.press('Tab');
        steps++;
      } while (await locator.evaluate(n => n === document.activeElement || n.contains(document.activeElement)) && steps < 4);
      const unfocused = await page.screenshot({ clip, animations: 'disabled' });
      expect(focused.equals(unfocused), `${name} needs a rendered focus change at 200% zoom`).toBe(false);
      await writeFile(testInfo.outputPath(`${slug}-focused.png`), focused);
      await writeFile(testInfo.outputPath(`${slug}-unfocused.png`), unfocused);
      for (let step = 0; step < steps; step++) await actor.press('Shift+Tab');
      await actor.assertFocus(role, name);
      trace.push({ assertion: 'zoomed rendered focus differs and keyboard returns', role, name, clip, zoom, steps });
    };
    const button = name => page.getByRole('button', { name, exact: true });
    const group = name => page.getByRole('group', { name, exact: true });
    const resize = async width => {
      await page.setViewportSize({ width: width * 2, height: 2200 });
      await expect.poll(() => page.evaluate(() => devicePixelRatio)).toBe(2);
      await expect.poll(() => page.evaluate(() => innerWidth)).toBe(width);
      await expect.poll(async () => (await group('Hermes host activity · 2 steps').boundingBox())?.width).toBe(width === 390 ? 370 : 560);
      await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    };
    const state = () => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()));
    page.on('pageerror', e => errors.push(e.message));
    page.on('console', m => { if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(m.text())) errors.push(m.text()); });
    page.on('request', r => {
      const path = new URL(r.url()).pathname;
      if (path.startsWith('/api/') || path.startsWith('/v1/')) requests.push({ method: r.method(), path });
    });
    const receipt = async label => {
      const value = await (await request.get(`${APP}e2e/hermes/transcript-accessibility/receipt`)).json();
      receipts.push({ label, ...value });
      expect(value.prompts).toBe(1); expect(value.stops).toBe(0); expect(value.decisions).toEqual([]);
      expect(value.mutations).toEqual([{ method: 'POST', path: '/v1/runs', session_id: 'synthetic-accessibility', message: 'Synthetic accessibility request' }]);
      return value;
    };
    const connect = async () => {
      await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
      await enableFlutterAccessibility(page, { delay: 0 });
      await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
      await expect.poll(async () => (await state()).status).toBe('connected');
    };
    const ordered = async label => {
      const boxes = [];
      for (const locator of [group('Synthetic accessibility request'), page.getByRole('group', { name: /^(?:D )?Synthetic accessibility commentary$/ }), group('Hermes host activity · 2 steps'), group('Synthetic canonical answer')]) {
        await expect(locator).toHaveCount(1); await expect(locator).toBeVisible();
        boxes.push(await locator.boundingBox());
      }
      for (let i = 1; i < boxes.length; i++) expect(boxes[i].y).toBeGreaterThan(boxes[i - 1].y);
      orders.push({ label, viewport: page.viewportSize(), boxes });
      await expect(button('Approve once')).toHaveCount(0);
      await expect(page.getByRole('checkbox', { name: 'Stop', exact: true })).toHaveCount(0);
      expect(await page.locator('body').ariaSnapshot()).not.toContain('Synthetic hidden model context');
      expect(await page.locator('body').ariaSnapshot()).not.toContain('/tmp/synthetic-only');
    };
    try {
      expect((await request.post(`${APP}e2e/hermes/transcript-accessibility/reset`)).ok()).toBe(true);
      await page.setViewportSize({ width: 2560, height: 2200 });
      await page.goto(`${APP}#/hermes`); await connect();
      await actor.reach('textbox', 'Message Hermes…');
      await actor.type('Message Hermes…', 'Synthetic accessibility request');
      await actor.reach('button', 'Send'); await actor.press('Enter');
      await expect(button('Approve once')).toBeVisible();
      await expect(group('Hermes host activity · 2 steps')).toHaveCount(1);
      for (const width of [390, 1280]) {
        await resize(width);
        await actor.reach('button', 'Thought', 'Shift+Tab');
        await actor.press('Enter');
        await expect(group('Synthetic readable reasoning')).toBeVisible();
        await actor.press('Space');
        await actor.reach('group', 'Hermes host activity · 2 steps');
        await actor.press('Enter');
        await expect(page.getByText('File activity Completed on Hermes host', { exact: true })).toBeVisible();
        await actor.press('Space');
        await actor.reach('button', 'Review');
        await actor.reach('button', 'Deny');
        await actor.reach('button', 'Approve once');
        await receipt(`streamed-${width}`);
      }
      await actor.reach('button', 'Approve once', 'Shift+Tab'); await actor.assertFocus('button', 'Approve once');
      await receipt('pending-setup');
      expect((await request.post(`${APP}e2e/hermes/transcript-accessibility/recover`)).ok()).toBe(true);
      if (recovery === 'reload') await page.reload();
      await connect();
      await expect(group('Synthetic canonical answer')).toBeVisible();
      await ordered('recovered');
      // Navigation destroys the Chat screen, then authoritative reads remount it.
      await page.goto(`${APP}#/settings`);
      await expect(group('Synthetic canonical answer')).toHaveCount(0);
      await page.goto(`${APP}#/hermes`);
      await expect(group('Synthetic canonical answer')).toBeVisible();
      for (const width of [390, 1280]) {
        await resize(width);
        await ordered(`remount-${width}`);
        await receipt(`remount-${width}`);
      }
      await actor.reach('group', 'Hermes host activity · 2 steps');
      await visibleZoomFocus('group', 'Hermes host activity · 2 steps', `${recovery}-recovered-tool-focus`);
      await actor.press('Enter');
      const file = page.getByText('File activity Completed on Hermes host', { exact: true });
      const web = page.getByText('Web activity Completed on Hermes host', { exact: true });
      await expect(file).toHaveCount(1); await expect(web).toHaveCount(1);
      expect((await file.boundingBox()).y).toBeLessThan((await web.boundingBox()).y);
      await actor.press('Space');
      await actor.reach('textbox', 'Message Hermes…'); await actor.press('Enter');
      await expect(button('Approve once')).toHaveCount(0);
      const final = await receipt('final');
      expect(final.history_ids).toEqual(['canonical-user', 'canonical-commentary', 'canonical-read', 'canonical-web', 'canonical-answer']);
      expect(final.reads.filter(r => r.canonical).length).toBeGreaterThanOrEqual(1);
      expect(requests.filter(r => r.method !== 'GET')).toEqual([{ method: 'POST', path: '/v1/runs' }]);
      // A fresh connection replaces the retired owner. Only explicit keyboard
      // submission and current run_2 decision can add mutations.
      expect((await request.post(`${APP}e2e/hermes/transcript-accessibility/reset-current`)).ok()).toBe(true);
      await connect();
      const composer = page.getByRole('textbox', { name: 'Message Hermes…', exact: true });
      for (let step = 0; step < 32 && !(await composer.evaluate(n => n === document.activeElement)); step++) await actor.press('Tab');
      await expect(composer).toBeFocused();
      await page.keyboard.type('Synthetic current request');
      await actor.reach('button', 'Send'); await actor.press('Enter');
      await expect(button('Approve once')).toBeVisible();
      for (const width of [390, 1280]) {
        await resize(width);
        await actor.reach('button', 'Approve once', 'Shift+Tab');
        await actor.assertFocus('button', 'Approve once');
      }
      await visibleZoomFocus('button', 'Approve once', `${recovery}-current-approval`);
      await actor.press('Enter');
      await expect(button('Approve once')).toHaveCount(0);
      const current = await (await request.get(`${APP}e2e/hermes/transcript-accessibility/receipt`)).json();
      receipts.push({ label: 'explicit-current-owner', ...current });
      expect(current.prompts).toBe(2); expect(current.stops).toBe(0);
      expect(current.decisions).toEqual(['once']);
      expect(current.mutations.map(r => r.path)).toEqual(['/v1/runs', '/v1/runs', '/v1/runs/run_2/approval']);
      expect(requests.filter(r => r.method !== 'GET').map(r => r.path)).toEqual(['/v1/runs', '/v1/runs', '/v1/runs/run_2/approval']);
      expect(errors).toEqual([]);
      await testInfo.attach('final.png', { body: await page.screenshot(), contentType: 'image/png' });
    } finally {
      const receiptPath = testInfo.outputPath('receipt.json');
      await writeFile(receiptPath, JSON.stringify({ recovery, trace, requests, receipts, orders, errors }, null, 2));
      await testInfo.attach('reconnect-receipt.json', { path: receiptPath, contentType: 'application/json' });
      await testInfo.attach('semantics.txt', { body: await page.locator('body').ariaSnapshot(), contentType: 'text/plain' });
      await context.close();
      await rm(profile, { recursive: true, force: true });
    }
  });
}
