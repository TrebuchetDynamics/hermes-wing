import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

for (const width of [390, 1280]) {
  for (const colorScheme of ['light', 'dark']) {
    test(`chat composition ${width} ${colorScheme}`, async ({ page, request }) => {
      await page.setViewportSize({ width, height: 1000 });
      await page.emulateMedia({ colorScheme, reducedMotion: 'reduce' });
      expect((await request.post(`${APP}e2e/hermes/reset`)).ok()).toBe(true);
      const errors = [];
      page.on('pageerror', error => errors.push(error.name));
      page.on('console', message => {
        if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(message.text())) errors.push('render error');
      });
      await page.goto(`${APP}#/hermes`);
      await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function', null, { timeout: 30000 });
      await page.evaluate(() => globalThis.wingE2EReduceMotion());
      await enableFlutterAccessibility(page);
      await page.evaluate(() => globalThis.wingE2EHermesConnect());
      await expect.poll(() => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()).active_session_id)).toBe('e2e-hermes-session');
      const composer = page.getByRole('textbox', { name: /Message.*…|Type a message/ }).last();
      await expect(composer).toBeVisible();
      await composer.click();
      await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
      await page.keyboard.type('Synthetic design review draft');
      await expect(page.getByRole('button', { name: 'Send', exact: true })).toBeEnabled();
      await page.screenshot({ path: test.info().outputPath(`chat-${width}-${colorScheme}.png`) });
      const editor = page.locator('input:focus, textarea:focus');
      await expect(editor).toHaveValue('Synthetic design review draft');
      expect(errors).toEqual([]);
    });
  }
}
