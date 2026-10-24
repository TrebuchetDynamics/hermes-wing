import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

for (const width of [390, 1280]) {
  test(`Settings search selects and cancels without Agent mutation at ${width}px`, async ({ page }) => {
    await page.setViewportSize({ width, height: 1000 });
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => {
      if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(message.text())) errors.push(message.text());
    });
    await page.goto(`${APP}#/settings?tab=config:appearance`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function', null, { timeout: 30000 });
    await enableFlutterAccessibility(page);
    const mutations = [];
    page.on('request', request => {
      if (!['GET', 'HEAD', 'OPTIONS'].includes(request.method())) mutations.push(request.method());
    });
    await page.getByRole('button', { name: 'Search settings', exact: true }).click();
    const search = page.getByRole('searchbox', { name: 'Search settings', exact: true });
    await search.fill('no.match.[literal]');
    await expect(page.getByText('No matching settings', { exact: true })).toBeVisible();
    await search.fill('VOICE');
    await page.getByRole('button', { name: 'Voice', exact: true }).click();
    await expect(page).toHaveURL(/tab=config(?::|%3A)voice/);
    await page.getByRole('button', { name: 'Search settings', exact: true }).click();
    await search.fill('dark theme');
    await expect(page.getByRole('button', { name: 'Appearance', exact: true })).toBeVisible();
    await page.getByRole('button', { name: 'Back', exact: true }).click();
    await expect(page).toHaveURL(/tab=config(?::|%3A)voice/);
    await page.getByRole('button', { name: 'Search settings', exact: true }).click();
    await search.fill('Chat text size');
    await page.getByRole('button', { name: /Chat text size/ }).click();
    await expect(page).toHaveURL(/page=typography/);
    await expect(page).toHaveURL(/setting=chat-text-scale/);
    await expect(page.getByRole('checkbox', { name: '100%', exact: true })).toBeChecked();
    await page.getByRole('checkbox', { name: '150%', exact: true }).click();
    await page.reload();
    await enableFlutterAccessibility(page);
    await expect(page.getByRole('checkbox', { name: '150%', exact: true })).toBeChecked();
    const breadcrumb = page.getByRole('heading', { name: 'Typography', exact: true });
    await expect(breadcrumb).toBeVisible();
    await page.getByRole('button', { name: 'Appearance', exact: true }).last().click();
    await expect(page).toHaveURL(/page=theme/);
    await expect(page).not.toHaveURL(/setting=chat-text-scale/);
    await expect(page.getByRole('heading', { name: 'Theme', exact: true })).toBeVisible();
    if (width < 820) {
      const navigation = page.getByRole('button', { name: 'Settings Theme', exact: true });
      await expect(navigation).toHaveCount(1);
      await navigation.click();
      await page.getByRole('menuitem', { name: 'Typography', exact: true }).click();
      await expect(page).toHaveURL(/page=typography/);
      await expect(page.getByRole('checkbox', { name: '150%', exact: true })).toBeChecked();
    }
    await page.screenshot({ path: test.info().outputPath(`settings-search-${width}.png`) });
    expect(mutations).toEqual([]);
    expect(errors).toEqual([]);
  });
}
