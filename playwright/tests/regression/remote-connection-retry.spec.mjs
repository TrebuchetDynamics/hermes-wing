import { test, expect } from '@playwright/test';
import { writeFile } from 'node:fs/promises';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

test.describe.configure({ retries: 0 });
test.setTimeout(120000);
const CONTROL = `${APP}e2e/hermes/session-restoration`;
const SESSION = 'synthetic-restoration-000';
const NOTICE = 'Connected to Hermes, but saving this connection could not be confirmed. Keep this form open and retry Add Hermes to connect and save again.';
const originA = new URL(APP).origin;
const originB = originA.replace('127.0.0.1', 'localhost');

async function fill(page, name, value) {
  await page.getByRole('textbox', { name, exact: true }).click();
  const input = page.locator('input:focus, textarea:focus');
  await expect(input).toHaveCount(1);
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.type(value);
  await expect(input).toHaveValue(value);
}

async function ready(page, width) {
  await page.setViewportSize({ width, height: 1100 });
  await page.goto(`${APP}#/hermes/add`);
  await page.waitForFunction(() => typeof globalThis.wingE2EEndpointSaveControl === 'function');
  await page.evaluate(() => globalThis.wingE2EReduceMotion());
  await enableFlutterAccessibility(page, { delay: 0 });
  await expect(page.getByRole('checkbox', { name: 'Remote', exact: true })).toBeVisible();
}
const save = (page, action = 'read') => page.evaluate(action => JSON.parse(globalThis.wingE2EEndpointSaveControl(action)), action);
const state = page => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()));
const add = page => page.getByRole('button', { name: 'Add Hermes', exact: true }).click();

for (const width of [390, 1280]) {
  test(`Remote rejected auth, failed save and explicit retry at ${width}px`, async ({ page, request }, testInfo) => {
    expect((await request.post(CONTROL)).ok()).toBeTruthy();
    const errors = [];
    const mutations = [];
    const reads = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('request', request => {
      const path = new URL(request.url()).pathname;
      if (path.startsWith('/api/')) {
        if (request.method() === 'GET') reads.push(path);
        else mutations.push(`${request.method()} ${path}`);
      }
    });
    let reject = true;
    let authCalls = 0;
    await page.route('**/v1/capabilities', async route => {
      authCalls++;
      if (reject) await route.fulfill({ status: 401, contentType: 'application/json', body: JSON.stringify({ error: 'synthetic private rejection' }) });
      else await route.continue();
    });
    await ready(page, width);
    await fill(page, 'Hermes Agent URL', originA);
    await fill(page, 'Connection name (optional)', 'Synthetic Remote A');
    await add(page);
    await expect(page.getByRole('group', { name: /Hermes API rejected the API key\./ })).toBeVisible();
    expect(authCalls).toBe(1);
    expect(await save(page)).toEqual({ attempts: 0, completed: 0, pending: false });
    await page.screenshot({ path: testInfo.outputPath(`remote-auth-${width}.png`) });
    reject = false;
    await save(page, 'fail-next');
    await add(page);
    await expect(page.getByRole('group', { name: new RegExp(NOTICE.replaceAll('.', '\\.')) })).toBeVisible();
    expect((await state(page)).status).toBe('connected');
    expect(authCalls).toBe(2);
    expect(await save(page)).toEqual({ attempts: 1, completed: 0, pending: false });
    await expect(page.getByRole('group', { name: /Saving a connection uses secure device storage\. Connecting alone does not confirm that your token was saved\./ })).toBeVisible();
    await expect(page.getByRole('group', { name: /Your token is stored|never shown after connecting/ })).toHaveCount(0);
    await expect(page.getByText('synthetic storage rejection', { exact: true })).toHaveCount(0);
    await page.getByRole('button', { name: 'Add Hermes', exact: true }).scrollIntoViewIfNeeded();
    if (width === 390) {
      await page.mouse.move(320, 900);
      await page.mouse.wheel(0, 500);
      await page.evaluate(() => new Promise(resolve => setTimeout(resolve, 300)));
    }
    await page.screenshot({ path: testInfo.outputPath(`remote-unsaved-${width}.png`) });
    await add(page);
    const hostA = page.getByLabel(/Synthetic Remote A.*online/);
    await expect(hostA).toBeVisible();
    expect(await save(page)).toEqual({ attempts: 2, completed: 1, pending: false });
    expect((await state(page)).active_session_id).toBeNull();
    const savedAuthCalls = authCalls; // Includes the directory's explicit health/read refresh.
    await hostA.click();
    await expect.poll(async () => (await state(page)).active_session_id).toBe(SESSION);
    const firstOwner = await state(page);
    await expect(page.getByRole('group', { name: new RegExp(`Canonical history for ${SESSION}\\.$`) })).toBeVisible();
    const firstPageSave = await save(page);
    await page.goto('about:blank');
    await ready(page, width); // Fresh route entry; saved host A survives reload.
    await fill(page, 'Hermes Agent URL', originB);
    await fill(page, 'Connection name (optional)', 'Synthetic Remote B');
    await add(page);
    await expect.poll(async () => (await save(page)).completed).toBe(1);
    await page.getByRole('button', { name: 'All chats', exact: true }).click();
    const hostB = page.getByLabel(/Synthetic Remote B.*online/);
    await expect(hostB).toBeVisible();
    expect(await save(page)).toEqual({ attempts: 1, completed: 1, pending: false });
    await hostB.click();
    await expect.poll(async () => (await state(page)).active_session_id).toBe(SESSION);
    expect((await state(page)).selected_profile_id).toBe(firstOwner.selected_profile_id);
    await expect(page.getByRole('group', { name: new RegExp(`Canonical history for ${SESSION}\\.$`) })).toBeVisible();
    const fixture = await (await request.get(CONTROL)).json();
    expect(fixture.counters.mutations).toBe(0);
    expect(mutations).toEqual([]);
    expect(errors).toEqual([]);
    const receipt = testInfo.outputPath('remote-retry-receipt.json');
    await writeFile(receipt, JSON.stringify({ width, authCalls, savedAuthCalls, reads, mutations, errors,
      firstOwner, firstPageSave, save: await save(page), finalOwner: await state(page), twoSyntheticOriginsSameProfileSession: true,
      storage: 'E2E-only injected failure; real browser persistence on successful retry',
      liveAgent: 'NOT_CHECKED', physicalSecureStore: 'NOT_CHECKED', remoteOAuth: 'NOT_CHECKED' }, null, 2));
    await testInfo.attach('remote-retry-receipt', { path: receipt, contentType: 'application/json' });
  });

  test(`Remote late save cannot disconnect a replacement host at ${width}px`, async ({ page, request }, testInfo) => {
    expect((await request.post(CONTROL)).ok()).toBeTruthy();
    const errors = [];
    const mutations = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('request', request => {
      const path = new URL(request.url()).pathname;
      if (path.startsWith('/api/') && request.method() !== 'GET') mutations.push(`${request.method()} ${path}`);
    });
    await ready(page, width);
    await fill(page, 'Hermes Agent URL', originA);
    await fill(page, 'Connection name (optional)', 'Synthetic pending A');
    await save(page, 'park');
    await add(page);
    await expect.poll(async () => (await save(page)).attempts).toBe(1);
    // Replacement originates from an authoritative channel event, not another
    // storage operation. User edits independently supersede the pending form.
    await fill(page, 'Hermes Agent URL', originB);
    await page.evaluate(origin => globalThis.wingE2EHermesConnect(origin), originB);
    await expect.poll(async () => (await state(page)).status).toBe('connected');
    await expect.poll(async () => (await state(page)).active_session_id).toBe(SESSION);
    const owner = await state(page);
    await save(page, 'release');
    await expect.poll(async () => (await save(page)).completed).toBe(1);
    expect(await state(page)).toEqual(owner);
    await expect(page.getByRole('button', { name: 'Add Hermes', exact: true })).toBeEnabled();
    await expect(page.getByRole('group', { name: /Connected to Hermes, but saving/ })).toHaveCount(0);
    await page.screenshot({ path: testInfo.outputPath(`remote-replacement-${width}.png`) });
    expect((await (await request.get(CONTROL)).json()).counters.mutations).toBe(0);
    expect(mutations).toEqual([]);
    expect(errors).toEqual([]);
    const receipt = testInfo.outputPath('remote-stale-save-receipt.json');
    await writeFile(receipt, JSON.stringify({ width, owner, save: await save(page), mutations, errors,
      replacement: 'existing E2E authoritative connect event; public form draft edited to host B',
      staleOwnerDisconnects: 0, storage: 'E2E-only deferred save', liveAgent: 'NOT_CHECKED' }, null, 2));
  });
}
