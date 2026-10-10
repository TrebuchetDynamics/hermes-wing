import { test, expect } from '@playwright/test';
import { writeFile } from 'node:fs/promises';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

test.describe.configure({ retries: 0 });
test.setTimeout(180000);
const CONTROL = `${APP}e2e/hermes/session-restoration`;

async function focus(page, control) {
  const count = await page.locator('[role="button"], [role="checkbox"], [role="textbox"], [role="tab"]').count();
  for (let i = 0; i < count * 2 + 10; i++) {
    if (await control.evaluate(el => el === document.activeElement || el.contains(document.activeElement))) return;
    await page.keyboard.press('Tab');
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  }
  throw new Error(`Keyboard failed to reach ${await control.getAttribute('aria-label')}`);
}
async function activate(page, role, name) {
  const control = page.getByRole(role, { name, exact: true }).last();
  await focus(page, control);
  await page.keyboard.press('Space');
}
async function fill(page, name, text) {
  await focus(page, page.getByRole('textbox', { name, exact: true }));
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.type(text);
  await expect(page.locator('input:focus, textarea:focus')).toHaveValue(text);
}

for (const width of [390, 1280]) {
  for (const mode of ['Local', 'SSH', 'Remote']) {
    test(`fresh public ${mode} Agent-only auth retry at ${width}px`, async ({ page, request }, info) => {
      expect((await request.post(CONTROL)).ok()).toBeTruthy();
      const reads = [], mutations = [], management = [], errors = [];
      page.on('pageerror', e => errors.push(e.message));
      page.on('request', r => {
        const p = new URL(r.url()).pathname;
        if (/^\/(health|v1\/capabilities|api\/)/.test(p)) {
          (r.method() === 'GET' ? reads : mutations).push(`${r.method()} ${p}`);
        }
        if (/^\/v1\/(enroll|pair|devices|host|profiles)/.test(p)) management.push(`${r.method()} ${p}`);
      });
      let reject = true, attempts = 0;
      await page.route('**/v1/capabilities', async route => {
        attempts++;
        if (reject) await route.fulfill({ status: 401, contentType: 'application/json', body: '{"error":"private-auth-response-must-not-render"}' });
        else await route.continue();
      });
      await page.setViewportSize({ width, height: 1100 });
      await page.goto(`${APP}#/hermes`);
      await page.waitForFunction(() => typeof globalThis.wingE2EReduceMotion === 'function');
      await page.evaluate(() => globalThis.wingE2EReduceMotion());
      await enableFlutterAccessibility(page, { delay: 0 });
      await expect(page.getByRole('button', { name: 'Add Hermes', exact: true }).last()).toBeVisible();
      await activate(page, 'button', 'Add Hermes');
      await expect(page.getByRole('checkbox', { name: 'Local', exact: true })).toBeVisible();
      expect(reads).toEqual([]);
      expect(management).toEqual([]);
      await activate(page, 'checkbox', mode);
      await expect(page.getByRole('checkbox', { name: mode, exact: true })).toBeChecked();
      if (mode === 'SSH') await expect(page.getByText(/Wing never runs arbitrary SSH commands or stores SSH keys/)).toBeVisible();
      if (mode === 'Remote') {
        await activate(page, 'checkbox', 'VPN / NetBird / Tailscale');
        await expect(page.getByRole('checkbox', { name: 'Remote', exact: true })).toBeChecked();
      }
      await page.mouse.move(1, 1);
      await page.waitForTimeout(500); // Let the chip's focus/ink transition settle.
      await page.screenshot({ path: info.outputPath(`direct-${mode}-${width}.png`) });
      await fill(page, /^Hermes Agent URL/, new URL(APP).origin);
      await fill(page, /^Connection name \(optional\)/, 'Synthetic direct host');
      await activate(page, 'button', 'Add Hermes');
      await expect(page.getByRole('group', { name: /Hermes API rejected the API key\./ })).toBeVisible();
      await expect(page.getByText('private-auth-response-must-not-render', { exact: true })).toHaveCount(0);
      expect(attempts).toBe(1);
      reject = false;
      await page.waitForTimeout(500);
      expect(attempts).toBe(1); // No automatic retry after failure.
      await activate(page, 'button', 'Add Hermes');
      await expect(page.getByLabel(/Synthetic direct host.*online/)).toBeVisible();
      await page.getByLabel(/Synthetic direct host.*online/).click();
      await expect(page.getByRole('group', { name: /Canonical history for synthetic-restoration-000\.$/ })).toBeVisible();
      expect(management).toEqual([]);
      expect(mutations).toEqual([]);
      // Public enrollment route is also direct-first; pairing remains separate.
      await page.evaluate(() => { location.hash = '#/enroll'; });
      await expect(page.getByText('Optional setup and pairing', { exact: true })).toBeVisible();
      await activate(page, 'button', /^Add Hermes/);
      await expect(page.getByRole('checkbox', { name: 'SSH', exact: true })).toBeVisible();
      const optional = page.getByRole('button', { name: 'Optional setup and pairing', exact: true });
      await focus(page, optional);
      await page.mouse.move(1, 1);
      await page.waitForTimeout(500);
      expect(await optional.evaluate(el => el === document.activeElement || el.contains(document.activeElement))).toBeTruthy();
      await page.screenshot({ path: info.outputPath(`optional-${mode}-${width}.png`) });
      await activate(page, 'button', 'Optional setup and pairing');
      await activate(page, 'button', /^I have a QR code or pairing link/);
      await expect(page.getByRole('button', { name: 'Enter connection string instead', exact: true })).toBeVisible();
      expect(errors).toEqual([]);
      await writeFile(info.outputPath('receipt.json'), JSON.stringify({ width, mode, reads, mutations, management, attempts, errors, managedSsh: 'not implemented', liveAgent: 'NOT_CHECKED', native: 'NOT_CHECKED' }, null, 2));
    });
  }
}
