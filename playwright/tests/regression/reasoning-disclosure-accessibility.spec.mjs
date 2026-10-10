import { mkdir, writeFile, rm } from 'node:fs/promises';
import path from 'node:path';
import { test, expect, chromium } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor } from '../../support/inventory_keyboard.mjs';

test.describe.configure({ retries: 0 });
test('200-percent zoom reasoning keyboard adaptive return and owner replacement under reduced motion', async ({ request }, testInfo) => {
  test.setTimeout(120000);
  const profile = testInfo.outputPath('zoom-profile');
  await mkdir(path.join(profile, 'Default'), { recursive: true });
  await writeFile(path.join(profile, 'Default', 'Preferences'), JSON.stringify({
    partition: { default_zoom_level: { x: Math.log(2) / Math.log(1.2) } },
  }));
  const context = await chromium.launchPersistentContext(profile, {
    executablePath: process.env.CHROME_EXECUTABLE,
    headless: true, viewport: { width: 780, height: 1800 }, reducedMotion: 'reduce',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  const page = context.pages()[0];
  const metrics = () => page.evaluate(() => ({ width: innerWidth, height: innerHeight,
    dpr: devicePixelRatio, reducedMotion: matchMedia('(prefers-reduced-motion: reduce)').matches }));
  const trace = [], requests = [], errors = [], renders = [];
  const actor = keyboardActor(page, testInfo, trace);
  const button = name => page.getByRole('button', { name, exact: true });
  const body = page.getByRole('group', { name: 'Synthetic old reasoning at [redacted-path]', exact: true });
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => {
    if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(message.text())) errors.push(message.text());
  });
  page.on('request', req => {
    const path = new URL(req.url()).pathname;
    if (path.startsWith('/api/') || path.startsWith('/v1/')) requests.push({ method: req.method(), path });
  });
  const render = async (slug, label, expanded) => {
    await expect(button(label)).toHaveAttribute('aria-expanded', String(expanded));
    if (expanded) await expect(body).toBeVisible();
    else await expect(body).toHaveCount(0);
    const viewport = await metrics();
    expect(viewport.dpr).toBe(2);
    expect(viewport.reducedMotion).toBe(true);
    const bounds = await button(label).boundingBox();
    expect(bounds.x).toBeGreaterThanOrEqual(0);
    expect(bounds.y).toBeGreaterThanOrEqual(0);
    expect(bounds.x + bounds.width).toBeLessThanOrEqual(viewport.width);
    expect(bounds.y + bounds.height).toBeLessThanOrEqual(viewport.height);
    if (expanded) {
      const content = await body.boundingBox();
      expect(content.x).toBeGreaterThanOrEqual(0);
      expect(content.x + content.width).toBeLessThanOrEqual(viewport.width);
      expect(content.y + content.height).toBeLessThanOrEqual(viewport.height);
    }
    const overflow = await page.evaluate(() => ({
      width: document.documentElement.scrollWidth,
      height: document.documentElement.scrollHeight,
      viewportWidth: innerWidth, viewportHeight: innerHeight,
    }));
    expect(overflow.width).toBeLessThanOrEqual(overflow.viewportWidth);
    expect(overflow.height).toBeLessThanOrEqual(overflow.viewportHeight);
    renders.push({ slug, viewport, label, expanded, bounds, overflow });
    await testInfo.attach(`${slug}.png`, { body: await page.screenshot(), contentType: 'image/png' });
  };
  try {
    expect((await request.post(`${APP}e2e/hermes/reasoning-disclosure`)).ok()).toBe(true);
    await page.setViewportSize({ width: 780, height: 1800 });
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto(`${APP}#/hermes`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
    await enableFlutterAccessibility(page, { delay: 0 });
    // Existing bootstrap hooks only; all disclosure and send actions use keys.
    await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
    expect(await page.evaluate(() => matchMedia('(prefers-reduced-motion: reduce)').matches)).toBe(true);
    const composer = page.getByRole('textbox');
    await expect(composer).toBeVisible();
    // Compact Flutter's native editor drops its hint name on keyboard focus.
    // Reach the unique editor with Tab rather than a disappearing hint locator.
    for (let step = 0; step < 32 && !(await composer.evaluate(node => node === document.activeElement)); step++) {
      await actor.press('Tab');
    }
    await expect(composer).toBeFocused();
    await page.keyboard.type('Synthetic adaptive request');
    await expect(composer).toHaveValue('Synthetic adaptive request');
    await actor.reach('button', 'Send');
    await actor.press('Enter');
    await expect(button('Thinking…')).toBeVisible();
    await actor.reach('button', 'Thinking…', 'Shift+Tab');
    await actor.assertFocus('button', 'Thinking…');
    await actor.press('Enter');
    await render('compact-open', 'Thinking…', true);
    const beforeAdaptive = requests.length;
    for (const [slug, width] of [['wide-return', 1280], ['compact-return', 390]]) {
      await page.setViewportSize({ width: width * 2, height: 1800 });
      // Wait for Flutter's adaptive rebuild, not just the browser viewport resize.
      await expect.poll(async () => (await button('Thinking…').boundingBox())?.width)
        .toBe(width === 1280 ? 560 : 370);
      // Exact-owner expansion survives; remounted focus must be reachable again.
      await render(`${slug}-open`, 'Thinking…', true);
      await actor.reach('button', 'Thinking…', 'Shift+Tab');
      await actor.assertFocus('button', 'Thinking…');
      await actor.press('Space');
      await render(`${slug}-collapsed`, 'Thinking…', false);
      await actor.assertFocus('button', 'Thinking…');
      await actor.press('Enter');
      await render(`${slug}-reopened`, 'Thinking…', true);
    }
    expect((await request.post(`${APP}e2e/hermes/reasoning-disclosure/complete`)).ok()).toBe(true);
    await expect(button('Thought')).toBeVisible();
    await expect(button('Thinking…')).toHaveCount(0);
    await actor.assertFocus('button', 'Thought');
    await actor.assertFocus('button', 'Thought');
    await render('compact-completed-open', 'Thought', true);
    await actor.press('Space');
    await render('compact-completed-collapsed', 'Thought', false);
    await actor.assertFocus('button', 'Thought');
    await actor.press('Tab');
    await actor.press('Shift+Tab');
    await actor.assertFocus('button', 'Thought');
    await page.setViewportSize({ width: 2560, height: 1800 });
    await expect.poll(async () => (await button('Thought').boundingBox())?.width).toBe(560);
    await actor.reach('button', 'Thought', 'Shift+Tab');
    await actor.press('Enter');
    await render('wide-completed-reopened', 'Thought', true);
    await actor.reach('button', 'Open Synthetic reasoning other', 'Shift+Tab');
    await actor.press('Enter');
    await expect.poll(() => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()).active_session_id)).toBe('synthetic-reasoning-other');
    await expect(button('Thought')).toHaveCount(0);
    await expect(body).toHaveCount(0);
    await actor.press('Tab');
    await actor.press('Shift+Tab');
    await expect(button('Thought')).toHaveCount(0);
    await testInfo.attach('replacement-owner.png', { body: await page.screenshot(), contentType: 'image/png' });
    expect(requests.slice(beforeAdaptive).filter(r => r.method !== 'GET')).toEqual([]);
    expect(requests.filter(r => r.method !== 'GET')).toEqual([{ method: 'POST', path: '/v1/runs' }]);
    expect(errors).toEqual([]);
  } finally {
    const counts = Object.fromEntries([...new Set(requests.map(r => `${r.method} ${r.path}`))]
      .map(key => [key, requests.filter(r => `${r.method} ${r.path}` === key).length]));
    await testInfo.attach('accessibility-receipt.json', { body: JSON.stringify({ trace, renders, requests, counts, errors }, null, 2), contentType: 'application/json' });
    await testInfo.attach('accessibility-semantics.txt', { body: await page.locator('body').ariaSnapshot(), contentType: 'text/plain' });
    await context.close();
    await rm(profile, { recursive: true, force: true });
  }
});
