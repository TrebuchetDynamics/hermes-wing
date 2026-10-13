import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

for (const width of [390, 1280]) {
  test(`read-only discovery recovery at ${width}px`, async ({ page, request }) => {
    await request.post(`${APP}e2e/hermes/session-restoration`);
    await page.setViewportSize({ width, height: 1100 });
    let outcome = 'network';
    let reads = 0;
    const writes = [];
    page.on('request', r => {
      if (r.url().includes('/v1/capabilities')) reads++;
      if (r.method() !== 'GET' && !new URL(r.url()).pathname.startsWith('/e2e/')) writes.push(r.method());
    });
    await page.route('**/v1/capabilities', async route => {
      if (outcome === 'network') await route.abort('failed');
      else if (outcome === 'denied') await route.fulfill({ status: 401, contentType: 'application/json', body: '{}' });
      else await route.continue();
    });
    await page.goto(`${APP}#/hermes/add?mode=local&welcome=1`);
    await page.waitForFunction(() => typeof globalThis.wingE2EReduceMotion === 'function');
    await page.evaluate(() => globalThis.wingE2EReduceMotion());
    await enableFlutterAccessibility(page, { delay: 0 });
    await expect(page.getByText(`Wing browser origin: ${new URL(APP).origin}`, { exact: false })).toBeVisible();
    const url = page.getByRole('textbox', { name: /^Hermes Agent URL/ });
    await url.click();
    await page.keyboard.press('ControlOrMeta+A');
    await page.keyboard.type(new URL(APP).origin);
    expect(reads).toBe(0);
    const check = page.getByRole('button', { name: 'Test connection', exact: true });
    async function testConnection() {
      await check.focus();
      await page.keyboard.press('Enter');
    }
    await testConnection();
    await expect(page.getByText(/The browser could not verify discovery/)).toBeVisible();
    outcome = 'denied'; await testConnection();
    await expect(page.getByText(/Authentication rejected\. Use the Agent API token/)).toBeVisible();
    outcome = 'success'; await testConnection();
    await expect(page.getByText(/Discovery verified\. Choose Add Hermes/)).toBeVisible();
    expect(reads).toBe(3); expect(writes).toEqual([]);
    await url.click();
    await page.keyboard.press('ControlOrMeta+A');
    await page.keyboard.type('https://changed.example.invalid');
    await expect(page.getByText(/Discovery verified\. Choose Add Hermes/)).toHaveCount(0);
  });
}
