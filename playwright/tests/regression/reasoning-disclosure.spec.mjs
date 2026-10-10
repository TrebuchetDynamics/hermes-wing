import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor } from '../../support/inventory_keyboard.mjs';

test.describe.configure({ retries: 0 });
test('reasoning keyboard status, focus and exact session replacement', async ({ page, request }, testInfo) => {
  const trace = [], requests = [], errors = [];
  const actor = keyboardActor(page, testInfo, trace);
  page.on('pageerror', error => errors.push(error.message));
  page.on('request', req => {
    const path = new URL(req.url()).pathname;
    if (path.startsWith('/api/') || path.startsWith('/v1/')) requests.push({ method: req.method(), path });
  });
  const complete = async () => expect((await request.post(`${APP}e2e/hermes/reasoning-disclosure/complete`)).ok()).toBe(true);
  const summary = name => page.getByRole('button', { name, exact: true });
  try {
    expect((await request.post(`${APP}e2e/hermes/reasoning-disclosure`)).ok()).toBe(true);
    await page.goto(`${APP}#/hermes`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
    await enableFlutterAccessibility(page, { delay: 0 });
    await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
    await expect(page.getByRole('button', { name: 'Send', exact: true })).toBeVisible();
    const send = async text => {
      await actor.reach('textbox', 'Message Hermes…');
      await actor.type('Message Hermes…', text);
      await actor.reach('button', 'Send');
      await actor.press('Enter');
      await expect(summary('Thinking…')).toBeVisible();
    };
    await send('Synthetic first request');
    await expect(page.getByRole('group', { name: 'Synthetic old reasoning at [redacted-path]', exact: true })).toHaveCount(0);
    const beforeDisclosure = requests.length;
    await actor.reach('button', 'Thinking…', 'Shift+Tab');
    await actor.visibleFocus('button', 'Thinking…', 'reasoning-summary');
    await actor.press('Enter');
    await expect(page.getByRole('group', { name: 'Synthetic old reasoning at [redacted-path]', exact: true })).toBeVisible();
    await expect(summary('Thinking…')).toHaveAttribute('aria-expanded', 'true');
    // Existing active-run reconciliation polls independently of disclosure.
    expect(requests.slice(beforeDisclosure).filter(r =>
      r.method !== 'GET' || r.path !== '/v1/runs/run_1')).toEqual([]);
    await complete();
    await expect(summary('Thought')).toBeVisible();
    await actor.assertFocus('button', 'Thought');
    await actor.press('Space');
    await expect(page.getByRole('group', { name: 'Synthetic old reasoning at [redacted-path]', exact: true })).toHaveCount(0);
    await expect(summary('Thought')).toHaveAttribute('aria-expanded', 'false');
    await actor.assertFocus('button', 'Thought');
    expect(requests.slice(beforeDisclosure).filter(r => r.method !== 'GET')).toEqual([]);
    await actor.press('Enter');
    await expect(page.getByRole('group', { name: 'Synthetic old reasoning at [redacted-path]', exact: true })).toBeVisible();
    const beforeOwner = requests.length;
    await actor.reach('button', 'Open Synthetic reasoning other', 'Shift+Tab');
    await actor.press('Enter');
    await expect.poll(() => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()).active_session_id)).toBe('synthetic-reasoning-other');
    await expect(summary('Thought')).toHaveCount(0);
    await expect(page.getByRole('group', { name: 'Synthetic old reasoning at [redacted-path]', exact: true })).toHaveCount(0);
    expect(requests.slice(beforeOwner)).toEqual([{ method: 'GET', path: '/api/sessions/synthetic-reasoning-other/messages' }]);
    await send('Synthetic fresh request');
    await expect(page.getByRole('group', { name: 'Synthetic fresh reasoning at [redacted-path]', exact: true })).toHaveCount(0);
    await actor.reach('button', 'Thinking…', 'Shift+Tab');
    await actor.press('Space');
    await expect(page.getByRole('group', { name: 'Synthetic fresh reasoning at [redacted-path]', exact: true })).toBeVisible();
    await expect(page.getByRole('group', { name: 'Synthetic old reasoning at [redacted-path]', exact: true })).toHaveCount(0);
    await complete();
    await actor.assertFocus('button', 'Thought');
    await actor.press('Enter');
    await expect(page.getByRole('group', { name: 'Synthetic fresh reasoning at [redacted-path]', exact: true })).toHaveCount(0);
    await page.keyboard.press('Escape');
    await actor.assertFocus('button', 'Thought');
    expect(requests.filter(r => r.method !== 'GET')).toEqual([
      { method: 'POST', path: '/v1/runs' }, { method: 'POST', path: '/v1/runs' },
    ]);
    expect(errors).toEqual([]);
    await testInfo.attach('reasoning-completed.png', { body: await page.screenshot(), contentType: 'image/png' });
  } finally {
    await testInfo.attach('reasoning-receipt.json', { body: JSON.stringify({ trace, requests, errors }), contentType: 'application/json' });
    await testInfo.attach('reasoning-semantics.txt', { body: await page.locator('body').ariaSnapshot(), contentType: 'text/plain' });
  }
});
