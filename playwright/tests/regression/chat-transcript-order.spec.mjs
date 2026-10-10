import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor } from '../../support/inventory_keyboard.mjs';

test.describe.configure({ retries: 0 });
for (const journey of ['complete', 'replace pending owner']) {
  test(`streamed transcript order: ${journey}`, async ({ page, request }, testInfo) => {
    test.setTimeout(120000);
    const trace = [], requests = [], payloads = [], errors = [], orders = [];
    const actor = keyboardActor(page, testInfo, trace);
    const button = name => page.getByRole('button', { name, exact: true });
    const group = name => page.getByRole('group', { name, exact: true });
    const state = () => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()));
    page.on('pageerror', e => errors.push(e.message));
    page.on('console', m => { if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(m.text())) errors.push(m.text()); });
    page.on('request', req => {
      const path = new URL(req.url()).pathname;
      if (path.startsWith('/api/') || path.startsWith('/v1/')) requests.push({ method: req.method(), path });
      if (req.method() === 'POST' && path === '/v1/runs') payloads.push(req.postDataJSON());
    });
    const expectedMutations = [{ method: 'POST', path: '/v1/runs' }];
    const mutations = () => requests.filter(r => r.method !== 'GET');
    const counters = async (decisions = []) => {
      expect(mutations()).toEqual(expectedMutations);
      expect((await (await request.get(`${APP}e2e/hermes/run-count`)).json()).runCount).toBe(1);
      expect((await (await request.get(`${APP}e2e/hermes/stop-count`)).json()).stopCount).toBe(0);
      expect((await (await request.get(`${APP}e2e/hermes/decisions`)).json()).decisions).toEqual(decisions);
      expect(payloads).toHaveLength(1);
      expect(payloads[0].session_id).toBe('e2e-hermes-session');
      expect(payloads[0].message).toBe('Synthetic ordered request');
    };
    const ordered = async (label, tail) => {
      const locators = [group('Synthetic ordered request'), button('Thought'),
        group('Synthetic ordered commentary'), group('Hermes host activity · 2 steps'), tail];
      const boxes = [];
      for (const locator of locators) {
        await expect(locator).toHaveCount(1);
        await expect(locator).toBeVisible();
        boxes.push(await locator.boundingBox());
      }
      for (let i = 1; i < boxes.length; i++) expect(boxes[i].y).toBeGreaterThan(boxes[i - 1].y);
      orders.push({ label, viewport: page.viewportSize(), boxes });
    };
    try {
      expect((await request.post(`${APP}e2e/hermes/transcript-order`)).ok()).toBe(true);
      await page.setViewportSize({ width: 1280, height: 1100 });
      await page.goto(`${APP}#/hermes`);
      await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
      await enableFlutterAccessibility(page, { delay: 0 });
      await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
      await actor.reach('textbox', 'Message Hermes…');
      await actor.type('Message Hermes…', 'Synthetic ordered request');
      await actor.reach('button', 'Send');
      await actor.press('Enter');
      await expect(button('Approve once')).toBeVisible();
      await ordered('pending', button('Approve once'));
      await counters();
      await actor.reach('button', 'Thought', 'Shift+Tab');
      await actor.press('Enter');
      await expect(group('Synthetic ordered reasoning')).toBeVisible();
      for (const width of [390, 1280]) {
        await page.setViewportSize({ width, height: 1100 });
        await expect.poll(async () => (await button('Thought').boundingBox())?.width).toBe(width === 390 ? 370 : 560);
        await expect(group('Synthetic ordered reasoning')).toBeVisible();
        await actor.reach('button', 'Thought', 'Shift+Tab');
        await actor.visibleFocus('button', 'Thought', `${journey}-${width}-thought`);
        await actor.press('Space');
        await expect(group('Synthetic ordered reasoning')).toHaveCount(0);
        await actor.press('Enter');
        await expect(group('Synthetic ordered reasoning')).toBeVisible();
        await counters();
        await expect(button('Approve once')).toHaveCount(1);
      }
      await ordered('wide-return-pending', button('Approve once'));
      if (journey === 'complete') {
        await actor.reach('button', 'Approve once');
        await actor.press('Enter');
        expectedMutations.push({ method: 'POST', path: '/v1/runs/run_1/approval' });
        await expect(button('Approve once')).toHaveCount(0);
        await expect.poll(async () => (await state()).last_turn_status).toBe('completed');
        await ordered('completed', group('Hermes echo: Synthetic ordered request'));
        await actor.reach('group', 'Hermes host activity · 2 steps', 'Shift+Tab');
        await actor.press('Space');
        const files = page.getByText('File activity Completed on Hermes host', { exact: true });
        const web = page.getByText('Web activity Completed on Hermes host', { exact: true });
        await expect(files).toHaveCount(1); await expect(web).toHaveCount(1);
        expect((await files.boundingBox()).y).toBeLessThan((await web.boundingBox()).y);
        await counters(['once']);
      } else {
        await actor.reach('button', 'Approve once');
        await actor.assertFocus('button', 'Approve once');
        await actor.reach('button', 'Open Synthetic order other', 'Shift+Tab');
        await actor.press('Enter');
        await expect.poll(async () => (await state()).active_session_id).toBe('synthetic-order-other');
        await expect(button('Approve once')).toHaveCount(0);
        await expect(button('Thought')).toHaveCount(0);
        await expect(group('Synthetic ordered reasoning')).toHaveCount(0);
        await expect(page.getByRole('checkbox', { name: 'Stop', exact: true })).toHaveCount(0);
        // Explicit traversal on the replacement owner cannot activate an old approval.
        await actor.reach('textbox', 'Message Hermes…');
        await actor.press('Enter');
        await actor.press('Space');
        await expect(button('Approve once')).toHaveCount(0);
        await counters();
        const oldRun = await (await request.get(`${APP}v1/runs/run_1`)).json();
        expect(oldRun.session_id).toBe('e2e-hermes-session');
        expect(oldRun.status).toBe('running');
      }
      expect(errors).toEqual([]);
      await testInfo.attach('final.png', { body: await page.screenshot(), contentType: 'image/png' });
    } finally {
      await testInfo.attach('order-receipt.json', { body: JSON.stringify({ journey, trace, requests, payloads, orders, errors }, null, 2), contentType: 'application/json' });
      await testInfo.attach('semantics.txt', { body: await page.locator('body').ariaSnapshot(), contentType: 'text/plain' });
    }
  });
}
