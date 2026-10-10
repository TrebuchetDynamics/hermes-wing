import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor } from '../../support/inventory_keyboard.mjs';

test.describe.configure({ retries: 0 });
for (const recovery of ['eviction', 'reconnect']) {
  test(`reasoning exact-owner ${recovery} is keyboard reachable and read-only`, async ({ page, request }, testInfo) => {
    const trace = [], requests = [], errors = [];
    const actor = keyboardActor(page, testInfo, trace);
    const button = name => page.getByRole('button', { name, exact: true });
    const body = page.getByRole('group', { name: 'Synthetic old reasoning at [redacted-path]', exact: true });
    const projection = () => page.evaluate(() => JSON.parse(globalThis.wingE2ETranscriptProjection()));
    page.on('pageerror', error => errors.push(error.message));
    page.on('request', req => {
      const url = new URL(req.url());
      if (url.pathname.startsWith('/api/') || url.pathname.startsWith('/v1/')) requests.push({ method: req.method(), path: url.pathname });
    });
    try {
      expect((await request.post(`${APP}e2e/hermes/reasoning-disclosure-recovery`)).ok()).toBe(true);
      await page.goto(`${APP}#/hermes`);
      await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
      await enableFlutterAccessibility(page, { delay: 0 });
      await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
      await expect(button('Send')).toBeVisible();
      await actor.reach('textbox', 'Message Hermes…');
      await actor.type('Message Hermes…', 'Synthetic recovery request');
      await actor.reach('button', 'Send');
      await actor.press('Enter');
      await expect(button('Thinking…')).toBeVisible();
      await actor.reach('button', 'Thinking…', 'Shift+Tab');
      await actor.press('Enter');
      await expect(body).toBeVisible();
      if (recovery === 'eviction') {
        expect((await request.post(`${APP}e2e/hermes/reasoning-disclosure/complete`)).ok()).toBe(true);
        await expect.poll(async () => (await projection()).loaded).toBe(104);
        // Tool coalescing yields two rendered rows (100 calls plus answer).
        await expect.poll(async () => (await projection()).allocated_rows).toBe(2);
        trace.push({ assertion: 'bounded eviction', projection: await projection() });
        await expect(button('Thought')).toHaveCount(0);
        await expect(body).toHaveCount(0);
        await actor.reach('button', 'Show up to 100 earlier loaded turns (3 remaining)');
        await actor.press('Enter');
        await expect.poll(async () => (await projection()).allocated_rows).toBe(5);
        trace.push({ assertion: 'deliberate reveal', projection: await projection() });
        await actor.reach('button', 'Thought', 'Shift+Tab');
        await actor.visibleFocus('button', 'Thought', 'recovered-summary');
        await expect(button('Thought')).toHaveAttribute('aria-expanded', 'false');
        await expect(body).toHaveCount(0);
        await actor.press('Space');
        await expect(body).toBeVisible();
        await actor.press('Enter');
        await expect(body).toHaveCount(0);
        await actor.assertFocus('button', 'Thought');
      } else {
        expect((await request.post(`${APP}e2e/hermes/reasoning-disclosure-recovery/interrupt`)).ok()).toBe(true);
        await expect(button('Reconnect')).toBeVisible();
        await actor.reach('button', 'Reconnect');
        const before = requests.length;
        await actor.visibleFocus('button', 'Reconnect', 'read-only-reconnect');
        await actor.press('Enter');
        await expect(page.getByRole('textbox', { name: 'Message Hermes…', exact: true })).toBeEnabled();
        await expect(button('Reconnect')).toHaveCount(0);
        await expect(button('Thought')).toHaveCount(0);
        await expect(button('Thinking…')).toHaveCount(0);
        await expect(body).toHaveCount(0);
        expect(requests.slice(before).every(r => r.method === 'GET')).toBe(true);
        expect(requests.slice(before).some(r => r.path === '/api/sessions/e2e-hermes-session/messages')).toBe(true);
        await actor.reach('textbox', 'Message Hermes…');
        await actor.assertFocus('textbox', 'Message Hermes…');
        await testInfo.attach('canonical-refresh.png', { body: await page.screenshot(), contentType: 'image/png' });
        await actor.reach('button', 'Open Synthetic reasoning other', 'Shift+Tab');
        await actor.press('Enter');
        await expect.poll(() => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()).active_session_id)).toBe('synthetic-reasoning-other');
        await expect(body).toHaveCount(0);
      }
      expect(requests.filter(r => r.method !== 'GET')).toEqual([{ method: 'POST', path: '/v1/runs' }]);
      expect(errors).toEqual([]);
      await testInfo.attach('recovery-render.png', { body: await page.screenshot(), contentType: 'image/png' });
    } finally {
      await testInfo.attach('recovery-receipt.json', { body: JSON.stringify({ recovery, trace, requests, errors }), contentType: 'application/json' });
      await testInfo.attach('recovery-semantics.txt', { body: await page.locator('body').ariaSnapshot(), contentType: 'text/plain' });
    }
  });
}
