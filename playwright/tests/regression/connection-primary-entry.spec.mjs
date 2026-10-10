import { test, expect } from '@playwright/test';
import { writeFile } from 'node:fs/promises';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

// Run the fresh compiled production UI against the existing deterministic server.
// Only transport is synthetic; no connect/restore hook or seeded client owner.
test.describe.configure({ retries: 0 });
// Keyboard journeys traverse the restored wide shell's loaded-session list.
test.setTimeout(180000);
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
async function state(request) {
  const response = await request.get(CONTROL);
  expect(response.ok()).toBeTruthy();
  return response.json();
}
async function paths(page) {
  const choices = page.getByRole('checkbox', { name: /^(Local|SSH|Remote|Remote HTTPS|VPN \/ NetBird \/ Tailscale)$/ });
  await expect(choices).toHaveCount(5);
  await expect(choices.nth(0)).toHaveAccessibleName('Local');
  await expect(choices.nth(1)).toHaveAccessibleName('SSH');
  await expect(choices.nth(2)).toHaveAccessibleName('Remote');
  await expect(choices.nth(3)).toHaveAccessibleName('Remote HTTPS');
  await expect(choices.nth(4)).toHaveAccessibleName('VPN / NetBird / Tailscale');
  for (const name of ['Local', 'SSH', 'Remote', 'Remote HTTPS', 'VPN / NetBird / Tailscale']) {
    await expect(page.getByRole('checkbox', { name, exact: true })).toHaveCount(1);
  }
  await keyboardActivate(page, 'VPN / NetBird / Tailscale');
  await expect(choices.nth(4)).toBeChecked();
  await expect(choices.nth(2)).toBeChecked();
  await expect(page.getByText(/Wing does not treat network location as authorization/)).toBeVisible();
  await keyboardActivate(page, 'Remote');
  await expect(choices.nth(4)).toBeChecked();
  await keyboardActivate(page, 'Remote HTTPS');
  await expect(choices.nth(3)).toBeChecked();
  await keyboardActivate(page, 'SSH');
  await expect(choices).toHaveCount(3);
  await expect(page.getByText(/Wing never runs arbitrary SSH commands or stores SSH keys/)).toBeVisible();
  await expect(page.getByText('Start the fixed tunnel outside Wing, then enter the local Agent URL it exposes.', { exact: true })).toBeVisible();
  await keyboardActivate(page, 'Local');
  await expect(choices.nth(0)).toBeChecked();
  await expect(page.getByText('Use a local Agent URL, or install Hermes on this device when local setup is available.', { exact: true })).toBeVisible();
  // Browser builds must not imply privileged native local setup exists.
  await expect(page.getByRole('button', { name: 'Set up Hermes on this computer', exact: true })).toHaveCount(0);
  await keyboardActivate(page, 'Remote');
  await expect(choices).toHaveCount(5);
}

async function keyboardActivate(page, name) {
  const control = page.getByRole('checkbox', { name, exact: true });
  // A restored wide shell also includes 50 loaded-session controls. Bound a
  // complete traversal by the current rendered controls, not the empty form.
  const controls = await page.locator('[role="button"], [role="checkbox"], [role="textbox"], [role="tab"]').count();
  for (let i = 0; i < controls * 2 + 10; i++) {
    if (await control.evaluate(el => el === document.activeElement || el.contains(document.activeElement))) {
      await page.keyboard.press('Space');
      await expect(control).toBeChecked();
      return;
    }
    await page.keyboard.press('Tab');
    // Flutter publishes its focus tree to DOM semantics on the next frame.
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  }
  throw new Error(`Keyboard traversal did not reach ${name}`);
}

for (const [width, mode] of [[390, 'Local'], [1280, 'SSH'], [390, 'VPN / NetBird / Tailscale'], [1280, 'Remote HTTPS']]) {
  test(`three primary paths, ${mode} connect and cancel/back retain owner at ${width}px`, async ({ page, request }, testInfo) => {
    expect((await request.post(CONTROL)).ok()).toBeTruthy();
    const mutations = [];
    page.on('request', r => {
      const path = new URL(r.url()).pathname;
      if (path.startsWith('/api/') && r.method() !== 'GET') mutations.push(`${r.method()} ${path}`);
    });
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));
    await page.setViewportSize({ width, height: 1000 });
    await page.goto(`${APP}#/hermes/add`);
    await ready(page);
    await paths(page);
    await page.getByRole('checkbox', { name: mode, exact: true }).first().click();
    await fill(page, 'Hermes Agent URL', new URL(APP).origin);
    await fill(page, 'Connection name (optional)', 'Synthetic connection entry host');
    await page.getByRole('button', { name: 'Add Hermes', exact: true }).click();
    await page.getByLabel(/Synthetic connection entry host.*online/).click();
    const history = page.getByRole('group', { name: new RegExp(`Canonical history for ${SESSION}\\.$`) });
    await expect(history).toBeVisible();
    await expect.poll(async () => (await selection(page))?.sessionId).toBe(SESSION);
    const owner = await selection(page);
    expect(owner.profileId).toBe('default');
    // Public browser route navigation, never private ownership helpers.
    await page.evaluate(() => { location.hash = '#/hermes'; });
    await expect(page.getByRole('checkbox', { name: 'Local', exact: true })).toHaveCount(0);
    await expect(history).toBeVisible();
    const before = await state(request);
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    await page.evaluate(() => { location.hash = '#/hermes/add'; });
    await expect(page.getByRole('checkbox', { name: 'Local', exact: true })).toBeVisible();
    await paths(page);
    // Cancel the existing rename dialog without saving a new endpoint or owner.
    await page.getByRole('button', { name: 'Rename Hermes profile', exact: true }).click();
    await page.getByRole('button', { name: 'Cancel', exact: true }).click();
    await fill(page, 'Hermes Agent URL', 'https://other.example.invalid');
    await page.goBack();
    await expect(history).toBeVisible();
    expect(await selection(page)).toEqual(owner);
    const after = await state(request);
    expect(after.counters.mutations).toBe(0);
    expect(after.mutations).toEqual([]);
    expect(mutations).toEqual([]);
    expect(errors).toEqual([]);
    expect(after.session_ids).toEqual(before.session_ids);
    expect(after.metadata_reads.every(r => r.session_id === SESSION)).toBeTruthy();
    const receipt = testInfo.outputPath('connection-primary-entry-receipt.json');
    await writeFile(receipt, JSON.stringify({ platform: 'fresh compiled Flutter deterministic Chromium', width, selectedConnectionMode: mode, primary: ['local', 'ssh', 'remote'], remote: ['https', 'vpn'], owner, counters: after.counters, mutations, nativeSetup: 'not offered on web', managedSsh: 'not implemented' }, null, 2));
    await testInfo.attach('connection-primary-entry-receipt.json', { path: receipt, contentType: 'application/json' });
  });
}
