import { test, expect } from '@playwright/test';
import { writeFile } from 'node:fs/promises';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

test.describe.configure({ retries: 0 });
test.setTimeout(180000);
async function focus(page, control) {
  await expect(control).toBeVisible();
  const count = await page.locator('[role="button"], [role="checkbox"], [role="textbox"], [role="tab"]').count();
  // Route replacement can retain a DOM focus ID without Flutter focus ownership.
  await page.keyboard.press('Tab');
  for (let i = 0; i < count * 2 + 12; i++) {
    if (await control.evaluate(el => el === document.activeElement || el.contains(document.activeElement))) return;
    await page.keyboard.press('Tab');
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  }
  throw new Error('Keyboard failed to reach public control');
}
async function activate(page, name) {
  const control = page.getByRole('button', {name, exact: true}).last();
  await page.waitForTimeout(250); // Settled route before keyboard focus transfer.
  await focus(page, control);
  await page.keyboard.press('Space');
}
async function fill(page, name, value) {
  await focus(page, page.getByRole('textbox', {name, exact: true}));
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.type(value);
  await expect(page.locator('input:focus, textarea:focus')).toHaveValue(value);
}
for (const width of [390, 1280]) {
  for (const scale of [1, 2]) {
    test(`welcome keyboard cancel retry saved-owner ${width}px text ${scale}`, async ({page, request}, info) => {
      expect((await request.post(`${APP}e2e/hermes/session-restoration`)).ok()).toBeTruthy();
      const reads = [], mutations = [], management = [], errors = [];
      page.on('pageerror', e => errors.push(e.message));
      page.on('request', r => {
        const p = new URL(r.url()).pathname;
        if (/^\/(health|v1\/capabilities|api\/)/.test(p)) (r.method() === 'GET' ? reads : mutations).push(`${r.method()} ${p}`);
        if (/^\/v1\/(enroll|pair|devices|host|profiles)/.test(p)) management.push(`${r.method()} ${p}`);
      });
      let reject = true, attempts = 0;
      await page.route('**/v1/capabilities', async route => {
        attempts++;
        if (reject) await route.fulfill({status: 401, contentType:'application/json', body:'{"error":"private-auth-response-must-not-render"}'});
        else await route.continue();
      });
      await page.setViewportSize({width, height:1100});
      await page.goto(`${APP}?e2eTextScale=${scale}#/hermes`);
      await page.waitForFunction(() => typeof globalThis.wingE2EReduceMotion === 'function');
      await page.evaluate(() => globalThis.wingE2EReduceMotion());
      await enableFlutterAccessibility(page, {delay:0});
      await expect(page.getByRole('heading', {name:'Welcome to Hermes Wing', exact:true})).toBeVisible();
      await page.mouse.move(1,1);
      await page.screenshot({path:info.outputPath(`welcome-${width}-${scale}.png`)});
      expect(reads).toEqual([]);
      for (const [entry, mode] of [['Get Started','Local'], ['Connect via SSH','SSH'], ['Connect to Remote Hermes','Remote']]) {
        await activate(page, entry);
        await expect(page.getByRole('checkbox', {name:mode, exact:true})).toBeChecked();
        await page.waitForTimeout(250); // Wait for the root route's 200ms focus transition.
        if (mode === 'SSH') await expect(page.getByText(/Wing never runs arbitrary SSH commands or stores SSH keys/)).toBeVisible();
        await activate(page, 'Back');
        await expect(page.getByRole('heading', {name:'Welcome to Hermes Wing', exact:true})).toBeVisible();
      }
      expect(reads).toEqual([]);
      expect(await page.evaluate(() => JSON.parse(globalThis.wingE2EEndpointSaveControl('read')))).toMatchObject({attempts:0, completed:0});
      await activate(page, 'Connect to Remote Hermes');
      await fill(page, /^Hermes Agent URL/, new URL(APP).origin);
      await fill(page, /^Connection name \(optional\)/, 'Synthetic welcome host');
      await activate(page, 'Add Hermes');
      await expect(page.getByRole('group', {name:/Hermes API rejected the API key\./})).toBeVisible();
      await expect(page.getByText('private-auth-response-must-not-render', {exact:true})).toHaveCount(0);
      expect(attempts).toBe(1);
      reject = false;
      await page.waitForTimeout(500);
      expect(attempts).toBe(1);
      await activate(page, 'Add Hermes');
      await expect(page).toHaveURL(/#\/hermes$/);
      await expect(page.getByLabel(/Synthetic welcome host.*online/)).toBeVisible();
      await page.getByLabel(/Synthetic welcome host.*online/).click();
      await expect(page.getByRole('group', {name:/Canonical history for synthetic-restoration-000\.$/})).toBeVisible();
      await expect(page.getByRole('heading', {name:'Welcome to Hermes Wing', exact:true})).toHaveCount(0);
      await page.reload();
      await enableFlutterAccessibility(page, {delay:0});
      await expect(page.getByRole('group', {name:/Canonical history for synthetic-restoration-000\.$/})).toBeVisible();
      await expect(page.getByRole('heading', {name:'Welcome to Hermes Wing', exact:true})).toHaveCount(0);
      expect(await page.evaluate(() => JSON.parse(globalThis.wingE2EEndpointSaveControl('read')))).toMatchObject({attempts:0, completed:0});
      expect(mutations).toEqual([]);
      expect(management).toEqual([]);
      expect(errors).toEqual([]);
      await writeFile(info.outputPath('receipt.json'), JSON.stringify({width,scale,reads,mutations,management,attempts,errors,qualification:'Linux Chromium, deterministic Agent-only fixture; no native or live provider'}, null, 2));
    });
  }
}
