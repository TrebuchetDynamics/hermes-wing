import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

for (const width of [390, 1280]) {
  test(`theme gallery selects and reloads at ${width}px`, async ({ page }) => {
    await page.setViewportSize({ width, height: 1000 });
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => {
      if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(message.text())) errors.push(message.text());
    });
    await page.goto(`${APP}#/settings?tab=config:appearance`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function', null, { timeout: 30000 });
    await enableFlutterAccessibility(page);
    const forest = page.getByRole('button', { name: 'Forest', exact: true });
    await expect(forest).toBeVisible();
    await forest.click();
    await expect(forest).toHaveAttribute('aria-current', 'true');
    await page.reload();
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function', null, { timeout: 30000 });
    await enableFlutterAccessibility(page);
    await expect(page.getByRole('button', { name: 'Forest', exact: true })).toHaveAttribute('aria-current', 'true');
    await page.screenshot({ path: test.info().outputPath(`theme-gallery-${width}.png`) });
    const mulberry = page.getByRole('button', { name: 'Mulberry', exact: true });
    await mulberry.scrollIntoViewIfNeeded();
    await mulberry.click();
    await expect(mulberry).toHaveAttribute('aria-current', 'true');
    expect(errors).toEqual([]);
  });
}
