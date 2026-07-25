import { test, expect } from '@playwright/test';
import {
  APP_URL as APP,
  enableFlutterAccessibility as a11y,
} from '../../support/flutter_semantics.mjs';

function semanticLabel(page, text) {
  const escaped = text.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
  return page.locator(`flt-semantics[aria-label*="${escaped}"]`).first();
}

test.beforeEach(async ({ request }) => {
  const response = await request.post(`${APP}e2e/hermes/reset`);
  expect(response.ok()).toBeTruthy();
});

async function openConnectedHermes(page) {
  await page.goto(`${APP}#/hermes`, { timeout: 15000 });
  await page.waitForFunction(
    () => typeof globalThis.wingE2EHermesConnect === 'function',
    null,
    { timeout: 30000 },
  );
  await a11y(page, { delay: 500 });
  await page.evaluate(() => globalThis.wingE2EHermesConnect());
  await expect(page.getByRole('button', { name: 'Sessions' })).toBeVisible();
}

test('a user can stop a slow Hermes run and the client sends the stop request', async ({ page, request }) => {
  await openConnectedHermes(page);
  const stopCountUrl = `${APP}e2e/hermes/stop-count`;
  const before = await (await request.get(stopCountUrl)).json();

  await page.evaluate(() => globalThis.wingE2EHermesSendText('slow lifecycle browser turn'));
  await expect(page.getByText('slow lifecycle browser turn').first()).toBeVisible();
  await expect(semanticLabel(page, 'Approve e2e browser run')).toBeVisible();
  await page.getByRole('checkbox', { name: 'Stop' }).click();

  await expect
    .poll(async () => (await (await request.get(stopCountUrl)).json()).stopCount)
    .toBeGreaterThan(before.stopCount);
  await expect(page.getByRole('checkbox', { name: 'Stop' })).not.toBeVisible();
});

test('session search and bulk selection can be explored without deleting data', async ({ page }) => {
  await openConnectedHermes(page);
  await page.getByRole('button', { name: 'Sessions' }).click();

  const search = page.getByRole('textbox', { name: /Search sessions/ });
  await expect(search).toBeVisible();
  await search.click();
  await search.pressSequentially('qa_no_match', { delay: 100 });
  await expect(page.getByRole('button', { name: 'Clear search' })).toBeVisible();
  await expect(page.getByText(/No Hermes sessions match/)).toBeVisible();
  await page.getByRole('button', { name: 'Clear search' }).click();

  await page.getByRole('button', { name: 'Select' }).click();
  await expect(page.getByText('0 selected', { exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'Select all' }).click();
  await expect(page.getByText(/^[1-9][0-9]* selected$/)).toBeVisible();
  await expect(page.getByRole('button', { name: /^Delete [1-9][0-9]*$/ })).toBeVisible();
  await page.getByRole('button', { name: 'Cancel' }).click();
  await expect(page.getByRole('textbox', { name: /Search sessions/ })).toBeVisible();
});
