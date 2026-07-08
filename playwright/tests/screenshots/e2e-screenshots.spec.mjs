import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility as a11y } from '../../support/flutter_semantics.mjs';

async function open(page, route) {
  await page.goto(APP + route, { timeout: 15000 });
  await page.waitForTimeout(1500);
  await a11y(page, { delay: 1000 });
}

test('Hermes connect screen screenshot', async ({ page }) => {
  await open(page, '#/hermes');
  await expect(page.getByText('Connect to Hermes Agent').first()).toBeVisible();
  await page.screenshot({ path: 'playwright/screenshots/hermes-connect.png', fullPage: true });
});

test('settings screen screenshot', async ({ page }) => {
  await open(page, '#/settings');
  await expect(page.getByText('Hermes Agent dashboard').first()).toBeVisible();
  await page.screenshot({ path: 'playwright/screenshots/settings.png', fullPage: true });
});
