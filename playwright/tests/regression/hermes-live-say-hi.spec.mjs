import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility as a11y } from '../../support/flutter_semantics.mjs';

const liveUrl = process.env.NAVIVOX_LIVE_HERMES_URL;
const liveKey = process.env.NAVIVOX_LIVE_HERMES_API_KEY;

const prompt = "Reply with the uppercase two-letter English greeting that rhymes with 'my'. No punctuation and no other words.";
const expected = /^hi$/i;

function semanticLabel(page, text) {
  const escaped = text.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
  return page.locator(`flt-semantics[aria-label*="${escaped}"]`).first();
}

test.skip(!liveUrl, 'Set NAVIVOX_LIVE_HERMES_URL to run live Hermes say-hi smoke');

test('Navivox sends a say-hi turn through the live Hermes Agent', async ({ page }) => {
  test.setTimeout(180000);
  await page.goto(`${APP}#/hermes`, { timeout: 15000 });
  await page.waitForTimeout(2000);
  await a11y(page);

  await page.evaluate(
    ({ baseUrl, apiKey }) => globalThis.navivoxE2EHermesConnect(baseUrl, apiKey),
    { baseUrl: liveUrl, apiKey: liveKey || null },
  );

  await expect(page.getByRole('button', { name: 'Sessions' })).toBeVisible({ timeout: 30000 });
  const title = `Navivox says hi ${Date.now()}`;
  await page.evaluate((sessionTitle) => globalThis.navivoxE2EHermesCreateSession(sessionTitle), title);
  await expect(page.getByRole('heading', { name: title })).toBeVisible({ timeout: 30000 });

  await page.evaluate((text) => globalThis.navivoxE2EHermesSendText(text), prompt);
  await expect(page.getByText(prompt).first()).toBeVisible({ timeout: 30000 });
  await expect(page.getByText(expected).first()).toBeVisible({ timeout: 120000 });
  await expect(semanticLabel(page, 'Hermes could not finish')).not.toBeVisible();
});
