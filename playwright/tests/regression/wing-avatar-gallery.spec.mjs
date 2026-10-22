import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

for (const width of [390, 1280]) {
  test(`local avatar families remain selectable after reload at ${width}`, async ({ page }) => {
    await page.setViewportSize({ width, height: 1000 });
    const open = async () => {
      await page.goto(`${APP}#/settings?tab=config:appearance`);
      await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function', null, { timeout: 30000 });
      await enableFlutterAccessibility(page);
    };
    await open();
    await page.mouse.move(width / 2, 700);
    await page.mouse.wheel(0, 1500);
    const family = page.getByRole('button', { name: /Avatar family 6/ });
    await family.scrollIntoViewIfNeeded();
    await family.click();
    await expect.poll(() => page.evaluate(() => localStorage.getItem('flutter.wing.appearance.avatar_variation.v1'))).toBe('5');
    await page.screenshot({ path: test.info().outputPath(`wing-avatars-${width}.png`) });
    await page.reload();
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function', null, { timeout: 30000 });
    await enableFlutterAccessibility(page);
    await page.mouse.move(width / 2, 700);
    await page.mouse.wheel(0, 1500);
    await page.getByRole('button', { name: /Avatar family 6/ }).scrollIntoViewIfNeeded();
    await expect.poll(() => page.evaluate(() => localStorage.getItem('flutter.wing.appearance.avatar_variation.v1'))).toBe('5');
  });
}
