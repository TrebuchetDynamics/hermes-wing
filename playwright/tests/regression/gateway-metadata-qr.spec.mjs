import { test, expect } from '@playwright/test';
import { APP_URL, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

for (const width of [390, 1280]) {
  test(`direct connection choices omit QR setup at ${width}`, async ({ page }) => {
    await page.setViewportSize({ width, height: 1000 });
    await page.goto(`${APP_URL}#/enroll`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function', null, { timeout: 30000 });
    await enableFlutterAccessibility(page);
    await expect(page.getByRole('button', { name: 'Show connection QR', exact: true })).toHaveCount(0);
    await expect(page.getByRole('button', { name: /Scan.*QR/i })).toHaveCount(0);
    await expect(page.getByRole('button', { name: /Connect via SSH/i })).toBeVisible();
    await page.screenshot({ path: test.info().outputPath(`direct-entry-${width}.png`) });
  });
}
