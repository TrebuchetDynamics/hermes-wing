import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor } from '../../support/inventory_keyboard.mjs';

test.describe.configure({ retries: 0 });
for (const recovery of ['reconnect', 'reload']) {
  test(`canonical transcript ${recovery} and viewport remount never replay`, async ({ page, request }, testInfo) => {
    test.setTimeout(120000);
    const trace = [], requests = [], errors = [], orders = [], receipts = [];
    const actor = keyboardActor(page, testInfo, trace);
    const button = name => page.getByRole('button', { name, exact: true });
    const group = name => page.getByRole('group', { name, exact: true });
    const state = () => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()));
    page.on('pageerror', e => errors.push(e.message));
    page.on('console', m => { if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(m.text())) errors.push(m.text()); });
    page.on('request', r => {
      const path = new URL(r.url()).pathname;
      if (path.startsWith('/api/') || path.startsWith('/v1/')) requests.push({ method: r.method(), path });
    });
    const receipt = async label => {
      const value = await (await request.get(`${APP}e2e/hermes/transcript-reconnect/receipt`)).json();
      receipts.push({ label, ...value });
      expect(value.prompts).toBe(1); expect(value.stops).toBe(0); expect(value.decisions).toEqual([]);
      expect(value.mutations).toEqual([{ method: 'POST', path: '/v1/runs', session_id: 'synthetic-reconnect', message: 'Synthetic reconnect request' }]);
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
      for (const locator of [group('Synthetic reconnect request'), page.getByRole('group', { name: /^(?:D )?Synthetic reconnect commentary$/ }), group('Hermes host activity · 2 steps'), group('Synthetic canonical answer')]) {
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
      expect((await request.post(`${APP}e2e/hermes/transcript-reconnect/reset`)).ok()).toBe(true);
      await page.setViewportSize({ width: 1280, height: 1100 });
      await page.goto(`${APP}#/hermes`); await connect();
      await actor.reach('textbox', 'Message Hermes…');
      await actor.type('Message Hermes…', 'Synthetic reconnect request');
      await actor.reach('button', 'Send'); await actor.press('Enter');
      await expect(button('Approve once')).toBeVisible();
      await expect(group('Hermes host activity · 2 steps')).toHaveCount(1);
      await actor.reach('button', 'Approve once', 'Shift+Tab'); await actor.assertFocus('button', 'Approve once');
      await receipt('pending-setup');
      expect((await request.post(`${APP}e2e/hermes/transcript-reconnect/recover`)).ok()).toBe(true);
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
        await page.setViewportSize({ width, height: 1100 });
        await expect.poll(async () => (await group('Hermes host activity · 2 steps').boundingBox())?.width).toBe(width === 390 ? 370 : 560);
        await ordered(`remount-${width}`);
        await receipt(`remount-${width}`);
      }
      await actor.reach('group', 'Hermes host activity · 2 steps', 'Shift+Tab');
      await actor.visibleFocus('group', 'Hermes host activity · 2 steps', `${recovery}-recovered-tool-focus`);
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
      expect(errors).toEqual([]);
      await testInfo.attach('final.png', { body: await page.screenshot(), contentType: 'image/png' });
    } finally {
      await testInfo.attach('reconnect-receipt.json', { body: JSON.stringify({ recovery, trace, requests, receipts, orders, errors }, null, 2), contentType: 'application/json' });
      await testInfo.attach('semantics.txt', { body: await page.locator('body').ariaSnapshot(), contentType: 'text/plain' });
    }
  });
}
