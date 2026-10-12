import { test, expect, chromium } from '@playwright/test';
import { writeFile, rm } from 'node:fs/promises';
import { enableFlutterAccessibility, APP_URL } from '../../support/flutter_semantics.mjs';
import { activate, fill, control, observeMatrixPage, recordMatrixBoundary, verifyMatrixNegativeControl } from '../../support/connection_production_matrix_fixture.mjs';
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
    expect((await control(actualPage)).save.completed).toBe(0);
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
