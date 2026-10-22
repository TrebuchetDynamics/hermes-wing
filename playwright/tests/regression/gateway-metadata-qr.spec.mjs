import { test, expect } from '@playwright/test';
import { APP_URL, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

for (const width of [390, 1280]) {
  test(`gateway QR metadata is generated without network or credential input at ${width}`, async ({ page }) => {
    await page.setViewportSize({ width, height: 1200 });
    await page.goto(`${APP_URL}#/enroll`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function', null, { timeout: 30000 });
    await enableFlutterAccessibility(page);
    const optional = page.getByRole('button', { name: /Optional setup/i });
    if (await optional.count()) { await optional.scrollIntoViewIfNeeded(); await optional.click(); }
    const create = page.getByRole('button', { name: 'Show connection QR', exact: true });
    await create.scrollIntoViewIfNeeded(); await create.click();
    const fields = page.getByRole('textbox');
    await fields.first().click();
    await page.keyboard.type('https://example.invalid');
    await page.getByRole('button', { name: 'Show connection QR', exact: true }).last().click();
    await expect(page.getByText(/This QR contains only the gateway address and profile\./).last()).toBeVisible();
    await expect(page.getByRole('textbox', { name: 'Access token', exact: true })).toHaveCount(0);
    await page.screenshot({ path: test.info().outputPath(`gateway-qr-${width}.png`) });
  });
}
