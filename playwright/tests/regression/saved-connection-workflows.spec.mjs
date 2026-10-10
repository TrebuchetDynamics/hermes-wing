import { test, expect } from '@playwright/test';
import { writeFile } from 'node:fs/promises';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

test.describe.configure({ retries: 0 });
test.setTimeout(120000);
const CONTROL = `${APP}e2e/hermes/session-restoration`;
const SESSION = 'synthetic-restoration-000';

async function ready(page) {
  await page.waitForFunction(() => typeof globalThis.wingE2EReduceMotion === 'function');
  await page.evaluate(() => globalThis.wingE2EReduceMotion());
  await enableFlutterAccessibility(page, { delay: 0 });
}

async function fill(page, name, value) {
  await page.getByRole('textbox', { name, exact: true }).click();
  const input = page.locator('input:focus, textarea:focus');
  await expect(input).toHaveCount(1);
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.type(value);
  await expect(input).toHaveValue(value);
}

async function selection(page) {
  return page.evaluate(() => {
    let value = localStorage.getItem('flutter.wing.hermes.gateway_contact_selection.v1');
    for (let i = 0; i < 2 && typeof value === 'string'; i++) value = JSON.parse(value);
    return value;
  });
}

for (const width of [390, 1280]) {
  test(`saved rename, cancel and remove distinguish saved from connected at ${width}px`, async ({ page, request }, testInfo) => {
    expect((await request.post(CONTROL)).ok()).toBeTruthy();
    const errors = [];
    const mutations = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('request', request => {
      const path = new URL(request.url()).pathname;
      if (path.startsWith('/api/') && request.method() !== 'GET') mutations.push(`${request.method()} ${path}`);
    });
    await page.setViewportSize({ width, height: 1100 });
    await page.goto(`${APP}#/hermes/add`);
    await ready(page);
    await fill(page, 'Hermes Agent URL', new URL(APP).origin);
    await fill(page, 'Connection name (optional)', 'Synthetic saved host');
    await page.getByRole('button', { name: 'Add Hermes', exact: true }).click();
    const host = page.getByLabel(/Synthetic saved host.*online/);
    await expect(host).toBeVisible();
    // A persisted, healthy saved host is not a selected conversation.
    expect((await selection(page))?.sessionId ?? null).toBeNull();
    const history = page.getByRole('group', { name: new RegExp(`Canonical history for ${SESSION}\\.$`) });
    await expect(history).toHaveCount(0);
    await host.click();
    await expect(history).toBeVisible();
    await expect.poll(async () => (await selection(page))?.sessionId).toBe(SESSION);
    const owner = await selection(page);
    await page.evaluate(() => { location.hash = '#/hermes'; });
    await expect(history).toBeVisible();
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    await page.evaluate(() => { location.hash = '#/hermes/add'; });
    await expect(page.getByRole('button', { name: 'Rename Hermes profile', exact: true })).toBeVisible();
    await page.getByRole('button', { name: 'Rename Hermes profile', exact: true }).click();
    await fill(page, 'Profile label', 'Synthetic renamed host');
    await page.getByRole('button', { name: 'Save', exact: true }).click();
    const savedChip = page.getByRole('checkbox', { name: /Synthetic renamed host$/ });
    await expect(savedChip).toBeVisible();
    expect(await selection(page)).toEqual(owner);
    await page.screenshot({ path: testInfo.outputPath(`saved-renamed-${width}.png`) });
    // Cancellation leaves the saved host and owner intact.
    await page.getByRole('button', { name: 'Delete', exact: true }).click();
    await expect(page.getByText(/Remove .* from this device/)).toBeVisible();
    await page.getByRole('button', { name: 'Cancel', exact: true }).click();
    await expect(savedChip).toBeVisible();
    expect(await selection(page)).toEqual(owner);
    await page.getByRole('button', { name: 'Delete', exact: true }).click();
    await expect(page.getByRole('alertdialog')).toBeVisible();
    await expect(page.getByText(/Remove .* from this device/)).toBeVisible();
    await page.screenshot({ path: testInfo.outputPath(`saved-remove-${width}.png`) });
    await page.getByRole('button', { name: 'Remove', exact: true }).click();
    await expect(page.getByRole('button', { name: 'Rename Hermes profile', exact: true })).toHaveCount(0);
    await expect(savedChip).toHaveCount(0);
    const response = await request.get(CONTROL);
    expect(response.ok()).toBeTruthy();
    const fixture = await response.json();
    expect(fixture.counters.mutations).toBe(0);
    expect(mutations).toEqual([]);
    expect(errors).toEqual([]);
    const receipt = testInfo.outputPath('saved-connection-workflows-receipt.json');
    await writeFile(receipt, JSON.stringify({ platform: 'fresh compiled Flutter deterministic Chromium', width, owner, savedWithoutSession: true, explicitSelectionConnected: true, renameRetainedOwner: true, removeCancellationRetainedOwner: true, removedSavedHost: true, mutations, errors, nativeSetup: 'NOT_CHECKED', liveAuthentication: 'NOT_CHECKED', remoteOAuth: 'NOT_CHECKED; no new authority' }, null, 2));
    await testInfo.attach('saved-connection-workflows-receipt.json', { path: receipt, contentType: 'application/json' });
  });
}
