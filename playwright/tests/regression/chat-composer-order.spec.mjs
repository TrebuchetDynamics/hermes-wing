import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor } from '../../support/inventory_keyboard.mjs';

test.describe.configure({ retries: 0 });
test('wide composer supported order, keyboard recovery and exact Stop requests', async ({ page, request }, testInfo) => {
  const trace = [], requests = [], errors = [];
  const actor = keyboardActor(page, testInfo, trace);
  const button = name => page.getByRole('button', { name, exact: true });
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => {
    if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(message.text())) errors.push(message.text());
  });
  page.on('request', req => {
    const path = new URL(req.url()).pathname;
    if (path.startsWith('/api/') || path.startsWith('/v1/')) requests.push({ method: req.method(), path });
  });
  const mutations = () => requests.filter(r => r.method !== 'GET');
  try {
    expect((await request.post(`${APP}e2e/hermes/model-picker`)).ok()).toBe(true);
    await page.setViewportSize({ width: 1440, height: 900 });
    await page.goto(`${APP}#/hermes`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
    await enableFlutterAccessibility(page, { delay: 0 });
    await page.evaluate(() => globalThis.wingE2EHermesConnect());
    const composer = page.locator('textarea[data-semantics-role="text-field"]');
    await expect(composer).toBeVisible();
    for (let i = 0; i < 32 && !(await composer.evaluate(node => node === document.activeElement)); i++) await actor.press('Tab');
    await expect(composer).toBeFocused();
    await expect(button('Send')).toHaveAttribute('aria-disabled', 'true');
    await page.keyboard.type('Synthetic composer order draft');
    await expect(composer).toHaveValue('Synthetic composer order draft');
    const order = [
      ['button', 'Attach image or text file'], ['button', 'Dictate a draft'],
      ['checkbox', 'hermes-agent'], ['switch', 'Continuous voice — device STT to Hermes text'],
      ['button', 'Hands-free voice'], ['button', 'Send'],
    ];
    const boxes = [];
    for (const [role, name] of order) {
      await actor.press('Tab');
      const control = await actor.assertFocus(role, name);
      boxes.push(await control.boundingBox());
    }
    for (let i = 1; i < boxes.length; i++) expect(boxes[i].x).toBeGreaterThan(boxes[i - 1].x);
    for (const [role, name] of order.slice(0, -1).reverse()) {
      await actor.press('Shift+Tab');
      await actor.assertFocus(role, name);
    }
    await actor.press('Shift+Tab');
    await expect(composer).toBeFocused();
    expect(mutations()).toEqual([]);

    // No browser capture service: both keyboard activators must explain that
    // state, preserve the draft and recover without Agent/audio writes.
    for (const key of ['Enter', 'Space']) {
      await actor.reach('button', 'Dictate a draft');
      await actor.visibleFocus('button', 'Dictate a draft', `draft-${key}`);
      await actor.press(key);
      await expect(button('Continue in text')).toBeVisible();
      await actor.reach('button', 'Continue in text', 'Shift+Tab');
      await actor.press('Enter');
      await expect(button('Continue in text')).toHaveCount(0);
      await expect(composer).toHaveValue('Synthetic composer order draft');
      expect(mutations()).toEqual([]);
    }

    await actor.reach('checkbox', 'hermes-agent');
    await actor.visibleFocus('checkbox', 'hermes-agent', 'model');
    await actor.press('Space');
    await expect(page.getByRole('textbox', { name: /Search models/ })).toBeVisible();
    await page.keyboard.press('Escape');
    await expect(page.getByRole('textbox', { name: /Search models/ })).toHaveCount(0);
    expect(mutations()).toEqual([]);
    expect((await (await request.get(`${APP}e2e/hermes/model-picker`)).json()).locks).toEqual([]);

    await actor.reach('button', 'Send');
    await actor.visibleFocus('button', 'Send', 'send');
    await actor.press('Enter');
    await expect(button('Approve once')).toBeVisible();
    const stop = page.getByRole('checkbox', { name: 'Stop', exact: true });
    await expect(stop).toBeVisible();
    await expect(page.getByRole('checkbox', { name: 'hermes-agent', exact: true })).toHaveAttribute('aria-disabled', 'true');
    await expect(button('Send')).toHaveAttribute('aria-disabled', 'true');
    await actor.reach('checkbox', 'Stop', 'Shift+Tab');
    await actor.visibleFocus('checkbox', 'Stop', 'stop');
    // A disabled model does not take the intervening focus position.
    await actor.press('Tab');
    await actor.assertFocus('switch', 'Continuous voice — device STT to Hermes text');
    await actor.press('Shift+Tab');
    await actor.assertFocus('checkbox', 'Stop');
    expect(mutations()).toEqual([{ method: 'POST', path: '/v1/runs' }]);
    await actor.press('Space');
    await expect(stop).toHaveCount(0);
    await expect(button('Approve once')).toHaveCount(0);
    const runCreates = mutations().filter(r => r.path === '/v1/runs');
    const stops = mutations().filter(r => /^\/v1\/runs\/[^/]+\/stop$/.test(r.path));
    expect(runCreates).toHaveLength(1);
    expect(stops).toHaveLength(1);
    expect(mutations()).toHaveLength(2);
    expect((await (await request.get(`${APP}e2e/hermes/stop-count`)).json()).stopCount).toBe(1);
    expect((await (await request.get(`${APP}e2e/hermes/run-count`)).json()).runCount).toBe(1);
    expect((await (await request.get(`${APP}e2e/hermes/decisions`)).json()).decisions).toEqual([]);
    expect(errors).toEqual([]);
    await testInfo.attach('wide-composer.png', { body: await page.screenshot(), contentType: 'image/png' });
  } finally {
    const counts = Object.fromEntries([...new Set(requests.map(r => `${r.method} ${r.path}`))]
      .map(key => [key, requests.filter(r => `${r.method} ${r.path}` === key).length]));
    await testInfo.attach('composer-receipt.json', { body: JSON.stringify({ trace, requests, counts, errors }, null, 2), contentType: 'application/json' });
    await testInfo.attach('composer-semantics.txt', { body: await page.locator('body').ariaSnapshot(), contentType: 'text/plain' });
  }
});
