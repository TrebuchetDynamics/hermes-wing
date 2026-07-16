import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility as a11y } from '../../support/flutter_semantics.mjs';

const providerUrl = process.env.WING_PROVIDER_HERMES_URL;
const providerKey = process.env.WING_PROVIDER_HERMES_API_KEY;
const textPrompt = process.env.WING_PROVIDER_TEXT_PROMPT ||
  'Construct this exact identifier by joining WING, PROVIDER, SMOKE, OK with underscores. Reply with only that identifier.';
const textExpected = process.env.WING_PROVIDER_TEXT_EXPECTED || 'WING_PROVIDER_SMOKE_OK';
const voicePrompt = process.env.WING_PROVIDER_VOICE_PROMPT ||
  'Construct this exact identifier by joining WING, PROVIDER, VOICE, OK with underscores. Reply with only that identifier.';
const voiceExpected = process.env.WING_PROVIDER_VOICE_EXPECTED || 'WING_PROVIDER_VOICE_OK';

function semanticLabel(page, text) {
  const escaped = text.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
  return page.locator(`flt-semantics[aria-label*="${escaped}"]`).first();
}

test.skip(
  !providerUrl,
  'Set WING_PROVIDER_HERMES_URL to run provider-backed Hermes chat/voice smoke',
);

test('Hermes provider-backed text and transcript voice turns produce assistant replies', async ({ page }) => {
  test.setTimeout(180000);
  await page.goto(`${APP}#/hermes`, { timeout: 15000 });
  await page.waitForTimeout(2000);
  await a11y(page);

  await page.evaluate(
    ({ baseUrl, apiKey }) => globalThis.wingE2EHermesConnect(baseUrl, apiKey),
    { baseUrl: providerUrl, apiKey: providerKey || null },
  );

  await expect(page.getByRole('button', { name: 'Sessions' })).toBeVisible({ timeout: 30000 });
  await expect(page.locator('[aria-label="Voice ready"]').first()).toBeVisible({ timeout: 30000 });

  // Match Hermes Desktop's runtime-session model: start each live smoke in a
  // fresh session instead of inheriting the most recent persisted transcript.
  const smokeSessionTitle = `Hermes Wing provider smoke ${Date.now()}`;
  await page.evaluate((title) => globalThis.wingE2EHermesCreateSession(title), smokeSessionTitle);
  await expect(page.getByRole('heading', { name: smokeSessionTitle })).toBeVisible({ timeout: 30000 });

  await page.evaluate((prompt) => globalThis.wingE2EHermesSendText(prompt), textPrompt);
  await expect(page.getByText(textPrompt).first()).toBeVisible({ timeout: 30000 });
  await expect(
    page.getByRole('group', { name: textExpected, exact: true }).first(),
  ).toBeVisible({ timeout: 120000 });

  // This exercises the Hermes Wing device-transcript-to-Hermes-text path without
  // relying on browser/host microphone availability. Android mic capture has a
  // separate device-gated smoke.
  await page.evaluate((prompt) => globalThis.wingE2EHermesSubmitVoice(prompt), voicePrompt);
  await expect(page.getByText(voicePrompt).first()).toBeVisible({ timeout: 30000 });
  await expect(
    page.getByRole('group', { name: voiceExpected, exact: true }).first(),
  ).toBeVisible({ timeout: 120000 });
});
