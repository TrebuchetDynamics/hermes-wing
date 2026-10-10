import { test, expect, chromium } from '@playwright/test';
import { mkdir, writeFile, rm } from 'node:fs/promises';
import path from 'node:path';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor } from '../../support/inventory_keyboard.mjs';

test.describe.configure({ retries: 0 });
test('200% Chromium zoom and reduced-motion composer keyboard journey', async ({ request }, testInfo) => {
  test.setTimeout(120000);
  const profile = testInfo.outputPath('zoom-profile');
  await mkdir(path.join(profile, 'Default'), { recursive: true });
  // Chromium's native zoom for the default (empty-path "x") partition.
  // Fail on observed metrics if a Chromium preference schema changes.
  await writeFile(path.join(profile, 'Default', 'Preferences'), JSON.stringify({
    partition: { default_zoom_level: { x: Math.log(2) / Math.log(1.2) } },
  }));
  const context = await chromium.launchPersistentContext(profile, {
    executablePath: process.env.CHROME_EXECUTABLE,
    headless: true, viewport: { width: 2880, height: 1800 },
    reducedMotion: 'reduce', args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  const page = context.pages()[0];
  const trace = [], requests = [], errors = [], runPayloads = [];
  const actor = keyboardActor(page, testInfo, trace);
  const button = name => page.getByRole('button', { name, exact: true });
  const state = () => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()));
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(m.text())) errors.push(m.text()); });
  page.on('request', r => {
    const url = new URL(r.url());
    if (/^\/(api|v1)\//.test(url.pathname)) requests.push({ method: r.method(), path: url.pathname, query: url.search });
    if (r.method() === 'POST' && url.pathname === '/v1/runs') runPayloads.push(r.postDataJSON());
  });
  const mutations = () => requests.filter(r => r.method !== 'GET');
  let owner, fixtureCounts;
  try {
    expect((await request.post(`${APP}e2e/hermes/model-picker`)).ok()).toBe(true);
    await page.goto(`${APP}#/hermes`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
    await enableFlutterAccessibility(page, { delay: 0 });
    await page.evaluate(() => globalThis.wingE2EHermesConnect());
    const metrics = () => page.evaluate(() => ({ innerWidth, innerHeight, dpr: devicePixelRatio,
      reducedMotion: matchMedia('(prefers-reduced-motion: reduce)').matches }));
    const wide = await metrics();
    trace.push({ zoom: wide });
    expect(wide.innerWidth).toBe(1440); expect(wide.dpr).toBe(2); expect(wide.reducedMotion).toBe(true);
    const visibleFocus = async (role, name, slug) => {
      const node = await actor.assertFocus(role, name);
      const bounds = await node.boundingBox();
      const current = await metrics();
      expect(bounds.x + bounds.width).toBeLessThanOrEqual(current.innerWidth);
      expect(bounds.y + bounds.height).toBeLessThanOrEqual(current.innerHeight);
      // Native zoom uses CSS bounds for semantics but DIP screenshot clipping.
      const clip = { x: (bounds.x - 4) * current.dpr, y: (bounds.y - 4) * current.dpr,
        width: (bounds.width + 8) * current.dpr, height: (bounds.height + 8) * current.dpr };
      const focused = await page.screenshot({ clip, animations: 'disabled' });
      await actor.press('Tab');
      const unfocused = await page.screenshot({ clip, animations: 'disabled' });
      await testInfo.attach(`${slug}-focused.png`, { body: focused, contentType: 'image/png' });
      await testInfo.attach(`${slug}-unfocused.png`, { body: unfocused, contentType: 'image/png' });
      expect(focused.equals(unfocused), `${name} rendered keyboard focus`).toBe(false);
      await actor.press('Shift+Tab'); await actor.assertFocus(role, name);
      trace.push({ assertion: 'zoom-aware rendered focus differs; inverse return', role, name, bounds });
    };
    const composer = page.locator('textarea[data-semantics-role="text-field"]');
    await expect(composer).toBeVisible();
    const reachEditor = async () => {
      for (let i = 0; i < 40 && !(await composer.evaluate(n => n === document.activeElement)); i++) await actor.press('Tab');
      await expect(composer).toBeFocused();
    };
    await reachEditor();
    await page.keyboard.type('Synthetic enlarged composer draft');
    owner = await state();
    const order = [['button', 'Attach image or text file'], ['button', 'Dictate a draft'],
      ['checkbox', 'hermes-agent'], ['switch', 'Continuous voice — device STT to Hermes text'],
      ['button', 'Hands-free voice'], ['button', 'Send']];
    const traverse = async slug => {
      await reachEditor();
      for (const [role, name] of order) { await actor.press('Tab'); await actor.assertFocus(role, name); }
      for (const [role, name] of order.slice(0, -1).reverse()) { await actor.press('Shift+Tab'); await actor.assertFocus(role, name); }
      await actor.press('Shift+Tab'); await expect(composer).toBeFocused();
      await testInfo.attach(`${slug}.png`, { body: await page.screenshot(), contentType: 'image/png' });
    };
    await traverse('wide-200-percent');
    for (const key of ['Enter', 'Space']) {
      await actor.reach('button', 'Dictate a draft');
      await visibleFocus('button', 'Dictate a draft', `draft-${key}`);
      await actor.press(key);
      await expect(button('Continue in text')).toBeVisible();
      await actor.reach('button', 'Continue in text', 'Shift+Tab'); await actor.press('Enter');
      await expect(button('Continue in text')).toHaveCount(0);
      await expect(composer).toHaveValue('Synthetic enlarged composer draft');
    }
    await actor.reach('checkbox', 'hermes-agent'); await actor.press('Space');
    await expect(page.getByRole('textbox', { name: /Search models/ })).toBeVisible();
    await page.keyboard.press('Escape');
    await page.setViewportSize({ width: 1200, height: 1800 });
    expect((await metrics()).innerWidth).toBe(600);
    await expect(button('Chat menu')).toBeVisible();
    await expect(button('Dictate a draft')).toHaveCount(0);
    await reachEditor();
    for (const name of ['Attach image or text file', 'Send']) { await actor.press('Tab'); await actor.assertFocus('button', name); }
    await visibleFocus('button', 'Send', 'compact-send');
    await actor.press('Shift+Tab'); await actor.assertFocus('button', 'Attach image or text file');
    await actor.press('Shift+Tab'); await expect(composer).toBeFocused();
    await testInfo.attach('compact-200-percent.png', { body: await page.screenshot(), contentType: 'image/png' });
    await page.setViewportSize({ width: 2880, height: 1800 });
    await expect(button('Dictate a draft')).toBeVisible();
    await expect(button('Chat menu')).toHaveCount(0);
    await traverse('wide-return-200-percent');
    await expect(composer).toHaveValue('Synthetic enlarged composer draft');
    const retained = await state();
    expect(retained.active_session_id).toBe(owner.active_session_id);
    expect(retained.selected_profile_id).toBe(owner.selected_profile_id);
    expect(mutations()).toEqual([]);
    await actor.reach('button', 'Send'); await visibleFocus('button', 'Send', 'wide-send'); await actor.press('Enter');
    await expect(button('Approve once')).toBeVisible();
    await actor.reach('checkbox', 'Stop', 'Shift+Tab'); await visibleFocus('checkbox', 'Stop', 'stop'); await actor.press('Space');
    await expect(page.getByRole('checkbox', { name: 'Stop', exact: true })).toHaveCount(0);
    expect(mutations().map(r => [r.method, r.path])).toEqual([['POST', '/v1/runs'], ['POST', '/v1/runs/run_1/stop']]);
    expect(runPayloads).toHaveLength(1); expect(runPayloads[0].session_id).toBe(owner.active_session_id);
    fixtureCounts = {
      stop: await (await request.get(`${APP}e2e/hermes/stop-count`)).json(),
      runs: await (await request.get(`${APP}e2e/hermes/run-count`)).json(),
      decisions: await (await request.get(`${APP}e2e/hermes/decisions`)).json(),
      model: await (await request.get(`${APP}e2e/hermes/model-picker`)).json(),
      run: await (await request.get(`${APP}v1/runs/run_1`)).json(),
    };
    expect(fixtureCounts.stop.stopCount).toBe(1); expect(fixtureCounts.runs.runCount).toBe(1);
    expect(fixtureCounts.decisions.decisions).toEqual([]); expect(fixtureCounts.model.locks).toEqual([]);
    expect(fixtureCounts.run.session_id).toBe(owner.active_session_id); expect(errors).toEqual([]);
  } finally {
    await testInfo.attach('composer-accessibility-receipt.json', { body: JSON.stringify({ trace, requests, runPayloads, owner, fixtureCounts, errors }, null, 2), contentType: 'application/json' });
    await testInfo.attach('composer-semantics.txt', { body: await page.locator('body').ariaSnapshot(), contentType: 'text/plain' });
    await context.close(); await rm(profile, { recursive: true, force: true });
  }
});
