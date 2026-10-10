import { test, expect, chromium } from '@playwright/test';
import { writeFile, rm } from 'node:fs/promises';
import { enableFlutterAccessibility, APP_URL } from '../../support/flutter_semantics.mjs';
import { activate, fill, counts, control, observeMatrixPage, recordMatrixBoundary, verifyMatrixNegativeControl } from '../../support/connection_production_matrix_fixture.mjs';
// Re-execute existing public recovery workflows against this exact WingApp build,
// rather than copying tests or borrowing receipts from a different composition.
import './remote-connection-retry.spec.mjs';
import './saved-endpoint-edit.spec.mjs';

const observations = new WeakMap();
test('matrix detects management on a persistent saved-editor page', async ({}, info) => {
  const context = await chromium.launchPersistentContext(info.outputPath('negative-profile'), {
    executablePath: process.env.CHROME_EXECUTABLE ?? '/usr/bin/chromium',
    headless: true, args: ['--no-sandbox'],
  });
  try {
    const actualPage = context.pages()[0];
    const observed = await observeMatrixPage(actualPage);
    await actualPage.goto(APP_URL);
    await actualPage.waitForFunction(() => typeof globalThis.wingConnectionMatrixControl === 'function');
    const state = await control(actualPage);
    expect([state.inspect, state.setup, state.cancel]).toEqual([0, 0, 0]);
    await verifyMatrixNegativeControl(actualPage, observed, info);
  } finally {
    await context.close();
    await rm(info.outputPath('negative-profile'), { recursive: true, force: true });
  }
});
const ownsPersistentPage = info => /^(saved endpoint keyboard|matrix detects management)/.test(info.title);
test.beforeEach(async ({ page }, info) => {
  if (!ownsPersistentPage(info)) observations.set(page, await observeMatrixPage(page));
});
test.afterEach(async ({ page }, info) => {
  if (!ownsPersistentPage(info)) await recordMatrixBoundary(page, observations.get(page), info);
});

for (const width of [390, 1280]) for (const installed of [false, true]) {
  test(`production optional Local ${width}px 200% ${installed ? 'existing' : 'missing'} to direct Remote`, async ({ page, request }, info) => {
    await request.post(`${APP_URL}e2e/hermes/session-restoration`);
    await page.setViewportSize({ width, height: 1100 });
    await page.goto('/?e2eTextScale=2');
    await page.waitForFunction(() => typeof globalThis.wingConnectionMatrixControl === 'function');
    await enableFlutterAccessibility(page, { delay: 0 });
    await control(page, installed ? 'installed' : 'missing');
    // All navigation uses the actual public welcome, setup and direct form.
    const optional = page.getByText('Optional setup and pairing', { exact: true });
    await optional.scrollIntoViewIfNeeded();
    await optional.click();
    await activate(page, /^Set up Hermes on this computer /);
    const action = installed ? 'Adopt this installation' : 'Install Hermes Agent here';
    await counts(page, 1, 0, 0);
    await activate(page, action);
    await expect(page.getByText('Allow local Hermes setup?', { exact: true })).toBeVisible();
    await page.screenshot({ path: info.outputPath('consent.png') });
    await activate(page, 'Cancel');
    await counts(page, 1, 0, 0);
    await activate(page, action);
    await activate(page, 'Run setup');
    await counts(page, 1, 1, 0);
    await activate(page, 'Stop setup');
    await counts(page, 1, 1, 1);
    await control(page, 'success');
    await expect(page.getByRole('group', { name: /^Setup stopped/ })).toBeVisible();
    await counts(page, 1, 1, 1);
    await activate(page, 'Check again');
    await counts(page, 2, 1, 1);
    await activate(page, 'Adopt this installation');
    await activate(page, 'Run setup');
    await control(page, 'failure');
    await expect(page.getByRole('group', { name: /^Setup needs attention/ })).toBeVisible();
    await page.screenshot({ path: info.outputPath('failure.png') });
    await counts(page, 2, 2, 1);
    await activate(page, 'Check again');
    await counts(page, 3, 2, 1);
    await activate(page, 'Adopt this installation');
    await activate(page, 'Run setup');
    // Public Back disposes setup; late success must not select pairing.
    await activate(page, 'Back');
    await counts(page, 3, 3, 2);
    await activate(page, 'Get Started');
    await expect(page.getByRole('checkbox', { name: 'Local', exact: true })).toBeChecked();
    await counts(page, 3, 3, 2);
    await page.getByRole('checkbox', { name: 'Remote', exact: true }).click();
    await control(page, 'success');
    await expect(page.getByRole('textbox', { name: 'Hermes Agent URL', exact: true })).toBeVisible();
    await counts(page, 3, 3, 2);
    await expect(page.getByRole('group', { name: /^Hermes gateway is ready/ })).toHaveCount(0);
    // Flutter exports the labeled noninteractive explanation as static text,
    // not a group. Assert the actual accessible text, not an invented role.
    const explanation = page.getByText(/Browser OAuth sign-in is not supported in Wing/);
    await expect(explanation).toBeVisible();
    await explanation.scrollIntoViewIfNeeded();
    await page.mouse.move(width / 2, 900);
    await page.mouse.wheel(0, 650);
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    await page.screenshot({ path: info.outputPath('auth-explanation.png') });
    await fill(page, 'Hermes Agent URL', new URL(APP_URL).origin);
    await fill(page, 'Connection name (optional)', 'Synthetic direct after setup');
    await activate(page, 'Add Hermes');
    await expect(page.getByLabel(/Synthetic direct after setup.*online/)).toBeVisible();
    await counts(page, 3, 3, 2);
    expect((await control(page)).save.completed).toBe(1);
    await page.screenshot({ path: info.outputPath('direct-ready.png') });
  });
}

for (const width of [390, 1280]) {
  test(`production two saved owners reject delayed old discovery ${width}px`, async ({ page, request }, info) => {
    await request.post(`${APP_URL}e2e/hermes/session-restoration`);
    await page.setViewportSize({ width, height: 1100 });
    const originA = new URL(APP_URL).origin;
    const originB = originA.replace('127.0.0.1', 'localhost');
    for (const [origin, label] of [[originA, 'Synthetic owner A'], [originB, 'Synthetic owner B']]) {
      await page.goto(`${APP_URL}#/hermes/add`);
      await page.waitForFunction(() => typeof globalThis.wingConnectionMatrixControl === 'function');
      await enableFlutterAccessibility(page, { delay: 0 });
      await fill(page, 'Hermes Agent URL', origin);
      await fill(page, 'Connection name (optional)', label);
      await activate(page, 'Add Hermes');
      await expect(page.getByLabel(new RegExp(`${label}.*online`))).toBeVisible();
      await page.goto('about:blank');
    }
    await page.goto(`${APP_URL}#/hermes`);
    await page.waitForFunction(() => typeof globalThis.wingConnectionMatrixControl === 'function');
    await enableFlutterAccessibility(page, { delay: 0 });
    await page.getByLabel(/Synthetic owner A.*online/).click();
    await expect.poll(async () => (await control(page)).owner.session).toBe('synthetic-restoration-000');
    const ownerA = (await control(page)).owner;
    await page.getByRole('button', { name: 'All chats', exact: true }).click();
    let release;
    const parked = new Promise(resolve => { release = resolve; });
    let oldReads = 0;
    let settled = 0;
    await page.route(`${originA}/v1/capabilities`, async route => {
      oldReads++;
      await parked;
      await route.fulfill({ status: 200, json: { object: 'hermes.api_server.capabilities', platform: 'hermes-agent', schema_version: 1 } });
      settled++;
    });
    await page.getByLabel(/Synthetic owner A.*online/).click();
    await expect.poll(() => oldReads).toBeGreaterThan(0);
    // Both saved hosts are real production store entries. The replacement
    // connection is an authoritative event through the existing channel seam.
    await page.evaluate(origin => globalThis.wingE2EHermesConnect(origin), originB);
    await expect.poll(async () => (await control(page)).owner.origin).toBe(originB);
    await expect.poll(async () => (await control(page)).owner.session).toBe(ownerA.session);
    const ownerB = (await control(page)).owner;
    expect(ownerB.profile).toBe(ownerA.profile);
    release();
    await expect.poll(() => settled).toBe(oldReads);
    expect((await control(page)).owner).toEqual(ownerB);
    await page.getByRole('button', { name: 'All chats', exact: true }).click();
    await expect(page.getByLabel(/Synthetic owner A.*online/)).toBeVisible();
    await expect(page.getByLabel(/Synthetic owner B.*online/)).toBeVisible();
    await page.screenshot({ path: info.outputPath('two-saved-owners.png') });
    expect((await (await request.get(`${APP_URL}e2e/hermes/session-restoration`)).json()).counters.mutations).toBe(0);
    await writeFile(info.outputPath('two-owner.json'), JSON.stringify({ ownerA, ownerB, oldReads, settled, staleOwnerMutations: 0 }, null, 2));
  });
}
