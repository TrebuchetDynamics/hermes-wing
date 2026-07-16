import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility as a11y } from '../../support/flutter_semantics.mjs';

const liveUrl = process.env.WING_LIVE_HERMES_URL;
const liveKey = process.env.WING_LIVE_HERMES_API_KEY;

function semanticLabel(page, text) {
  const escaped = text.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
  return page.locator(`flt-semantics[aria-label*="${escaped}"]`).first();
}

test.skip(!liveUrl, 'Set WING_LIVE_HERMES_URL to run against a real Hermes Agent API server');

test('Hermes route connects to a live installed Hermes Agent API server', async ({ page }) => {
  await page.goto(`${APP}#/hermes`, { timeout: 15000 });
  await page.waitForTimeout(2000);
  await a11y(page);

  await page.evaluate(
    ({ baseUrl, apiKey }) => globalThis.wingE2EHermesConnect(baseUrl, apiKey),
    { baseUrl: liveUrl, apiKey: liveKey || null },
  );

  await expect(page.getByRole('button', { name: 'Sessions' })).toBeVisible();
  const title = `Hermes Wing live API ${Date.now()}`;
  await page.evaluate((sessionTitle) => globalThis.wingE2EHermesCreateSession(sessionTitle), title);
  await expect(page.getByRole('heading', { name: title })).toBeVisible({ timeout: 30000 });
  await expect(page.getByText('How can Hermes help today?').first()).toBeVisible();
  await expect(page.locator('[aria-label="Voice ready"]').first()).toBeVisible();
  await expect(page.locator('[aria-label="Ready"]').first()).toBeVisible();
  await page.getByRole('button', { name: 'Sessions' }).click();
  await expect(page.getByRole('group', { name: 'Hermes sessions' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'New' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Session actions' }).first()).toBeVisible();
});
