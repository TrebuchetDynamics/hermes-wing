import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility as a11y } from '../../support/flutter_semantics.mjs';

function semanticLabel(page, text) {
  const escaped = text.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
  return page.locator(`flt-semantics[aria-label*="${escaped}"]`).first();
}

test('Hermes route renders connect form and cross-platform setup hints in a real browser', async ({ page }) => {
  await page.goto(`${APP}#/hermes`, { timeout: 15000 });
  await page.waitForTimeout(2000);
  await a11y(page);

  await expect(page.getByText('Connect to Hermes Agent').first()).toBeVisible();
  await expect(page.getByRole('textbox', { name: 'Hermes API base URL' })).toBeVisible();
  await expect(page.getByRole('checkbox', { name: 'Local Hermes' })).toBeVisible();
  await expect(page.getByRole('checkbox', { name: 'Android emulator' })).toBeVisible();
  await expect(page.getByRole('checkbox', { name: 'Remote/LAN' })).toBeVisible();
  await expect(page.getByText('Android emulator: http://10.0.2.2:8642').first()).toBeVisible();
  await expect(page.getByText('Physical device: LAN/VPN/Tailscale URL').first()).toBeVisible();
});

test('Hermes route renders connected session/capabilities in a real browser e2e build', async ({ page }) => {
  await page.goto(`${APP}#/hermes`, { timeout: 15000 });
  await page.waitForTimeout(2000);
  await a11y(page);

  await page.evaluate(() => globalThis.navivoxE2EHermesConnect());
  await page.waitForTimeout(1000);

  await expect(page.getByText('E2E Hermes is ready.').first()).toBeVisible();
  await expect(page.locator('[aria-label="hermes-agent"]').first()).toBeVisible();
  await expect(page.locator('[aria-label="Voice ready"]').first()).toBeVisible();
  await expect(page.locator('[aria-label="Ready"]').first()).toBeVisible();
  await expect(page.getByText('Sessions').first()).toBeVisible();

  await page.getByRole('button', { name: 'Diagnostics' }).first().click();
  await expect(semanticLabel(page, 'Runs SSE enabled')).toBeVisible();
  await expect(semanticLabel(page, 'Voice: device STT -> Hermes text')).toBeVisible();
  await expect(semanticLabel(page, 'Version: 0.16.0')).toBeVisible();
  await expect(semanticLabel(page, 'Gateway: running')).toBeVisible();
  await expect(semanticLabel(page, 'Models: hermes-agent')).toBeVisible();
  await expect(semanticLabel(page, 'Skills: 2')).toBeVisible();
  await expect(semanticLabel(page, 'Toolsets enabled: 1')).toBeVisible();
  await expect(semanticLabel(page, 'Jobs: 1')).toBeVisible();
  await page.getByRole('button', { name: 'Close' }).click();

  await page.getByRole('button', { name: 'Sessions' }).click();
  await page.getByRole('button', { name: 'Session actions' }).first().click();
  await page.getByRole('menuitem', { name: 'Rename' }).click();
  await page.getByRole('textbox', { name: 'Session title' }).fill('Renamed e2e session');
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(page.getByRole('heading', { name: 'Renamed e2e session' })).toBeVisible();
  await page.getByRole('button', { name: 'Sessions' }).click();
  await page.getByRole('button', { name: 'Session actions' }).first().click();
  await page.getByRole('menuitem', { name: 'Fork' }).click();
  await expect(page.getByRole('heading', { name: 'Renamed e2e session fork' })).toBeVisible();

  await page.evaluate(() => globalThis.navivoxE2EHermesSendText('hello hermes browser'));
  await expect(page.getByText('hello hermes browser').first()).toBeVisible();
  await expect(semanticLabel(page, 'Approve e2e browser run')).toBeVisible();
  await expect(semanticLabel(page, 'Risk: low')).toBeVisible();
  await page.getByRole('button', { name: 'Approve once' }).click();
  await expect(semanticLabel(page, 'Approve e2e browser run')).not.toBeVisible();
  await expect(page.getByText('Hermes echo: hello hermes browser').first()).toBeVisible();

  await page.getByRole('button', { name: 'New session' }).click();
  await page.waitForTimeout(1000);
  await expect(page.getByRole('heading', { name: /E2E Hermes Session \d+/ })).toBeVisible();
  await expect(page.getByText('How can Hermes help today?').first()).toBeVisible();
  await expect(page.getByRole('checkbox', { name: 'Summarize what you can help me do.' })).toBeVisible();
  await page.evaluate(() => globalThis.navivoxE2EHermesSendText('new session browser'));
  await page.waitForTimeout(1000);
  await expect(page.getByText('new session browser').first()).toBeVisible();
  await expect(page.getByText('Hermes echo: new session browser').first()).toBeVisible();

  await page.evaluate(() => globalThis.navivoxE2EHermesSubmitVoice('voice browser turn'));
  await page.waitForTimeout(1000);
  await expect(page.getByText('voice browser turn').first()).toBeVisible();
  await expect(page.getByText('Hermes echo: voice browser turn').first()).toBeVisible();

  await page.getByRole('button', { name: 'Sessions' }).click();
  await page.getByRole('button', { name: 'Session actions' }).first().click();
  await page.getByRole('menuitem', { name: 'Delete' }).click();
  await page.getByRole('button', { name: 'Delete' }).click();
  await expect(page.getByRole('heading', { name: 'Renamed e2e session' })).toBeVisible();

  await page.evaluate(() => globalThis.navivoxE2EHermesSendText('slow browser turn'));
  await expect(page.getByText('slow browser turn').first()).toBeVisible();
  await expect(page.getByText('Hermes echo: slow browser turn').first()).toBeVisible();
});
