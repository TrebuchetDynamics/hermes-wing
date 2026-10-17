import { test, expect, chromium } from '@playwright/test';
import { writeFile, rm } from 'node:fs/promises';
import { enableFlutterAccessibility, APP_URL } from '../../support/flutter_semantics.mjs';
import { activate, fill, observeMatrixPage, assertNoMatrixTraffic, verifyMatrixNegativeControl } from '../../support/connection_production_matrix_fixture.mjs';
// Re-execute existing public recovery workflows against this exact WingApp build,
// rather than copying tests or borrowing receipts from a different composition.
import './remote-connection-retry.spec.mjs';
import './saved-endpoint-edit.spec.mjs';
import './direct-first-run.spec.mjs';
import './saved-connection-workflows.spec.mjs';

const state = page => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()));
const selection = page => page.evaluate(() => {
  let value = localStorage.getItem('flutter.wing.hermes.gateway_contact_selection.v1');
  for (let i = 0; i < 2 && typeof value === 'string'; i++) value = JSON.parse(value);
  return value;
});
async function ready(page) {
  await page.waitForFunction(() => typeof globalThis.wingE2EEndpointSaveControl === 'function');
  await page.evaluate(() => globalThis.wingE2EReduceMotion());
  await enableFlutterAccessibility(page, { delay: 0 });
}
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
    await ready(actualPage);
    expect(await actualPage.evaluate(() => JSON.parse(globalThis.wingE2EEndpointSaveControl('read')).completed)).toBe(0);
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
  if (!ownsPersistentPage(info)) {
    const observed = observations.get(page);
    assertNoMatrixTraffic(observed);
    await writeFile(info.outputPath('matrix-boundary.json'), JSON.stringify({
      title: info.title, observed, state: await state(page), selection: await selection(page),
      native: 'NOT_CHECKED', liveAuthentication: 'NOT_CHECKED',
    }, null, 2));
  }
});



for (const width of [390, 1280]) {
  test(`production two saved owners reject delayed old discovery ${width}px`, async ({ page, request }, info) => {
    await request.post(`${APP_URL}e2e/hermes/session-restoration`);
    await page.setViewportSize({ width, height: 1100 });
    const originA = new URL(APP_URL).origin;
    const originB = originA.replace('127.0.0.1', 'localhost');
    const scoped = catalog => ({ ...catalog, profile_context: {
      type: 'query', name: 'profile', required: true, default_profile_id: 'default',
    } });
    await page.route('**/v1/capabilities', async route => {
      const response = await route.fetch();
      await route.fulfill({ response, json: scoped(await response.json()) });
    });
    await page.route('**/api/sessions/synthetic-restoration-000/messages?*', async route => {
      const response = await route.fetch();
      const body = await response.json();
      const owner = new URL(route.request().url()).origin === originA ? 'A' : 'B';
      body.data = body.data.map(row => ({ ...row, content: `Canonical ${owner} host history.` }));
      await route.fulfill({ response, json: body });
    });
    const history = owner => page.getByRole('group', { name: new RegExp(`Canonical ${owner} host history\\.$`) });
    for (const [origin, label] of [[originA, 'Synthetic owner A'], [originB, 'Synthetic owner B']]) {
      await page.goto(`${APP_URL}#/hermes/add`);
      await ready(page);
      await fill(page, 'Hermes Agent URL', origin);
      await fill(page, 'Connection name (optional)', label);
      await activate(page, 'Add Hermes');
      await expect(page.getByLabel(new RegExp(`${label}.*online`))).toBeVisible();
      await page.goto('about:blank');
    }
    await page.goto(`${APP_URL}#/hermes`);
    await ready(page);
    await page.getByLabel(/Synthetic owner A.*online/).click();
    await expect.poll(async () => (await selection(page))?.sessionId).toBe('synthetic-restoration-000');
    const ownerA = await selection(page);
    await expect(history('A')).toBeVisible();
    await page.getByRole('button', { name: 'All chats', exact: true }).click();
    let release;
    const parked = new Promise(resolve => { release = resolve; });
    let oldReads = 0;
    let settled = 0;
    await page.route(`${originA}/v1/capabilities`, async route => {
      oldReads++;
      const response = await route.fetch();
      const catalog = scoped(await response.json());
      await parked;
      await route.fulfill({ response, json: catalog });
      settled++;
    });
    await page.getByLabel(/Synthetic owner A.*online/).click();
    await expect.poll(() => oldReads).toBeGreaterThan(0);
    // Cancel pending A and deliberately select saved B through public controls.
    await page.getByRole('button', { name: 'All chats', exact: true }).click();
    await page.getByLabel(/Synthetic owner B.*online/).click();
    await expect.poll(async () => {
      const selected = await selection(page);
      return selected != null && selected.gatewayId !== ownerA.gatewayId && selected.sessionId === ownerA.sessionId;
    }).toBe(true);
    await expect.poll(async () => (await state(page)).active_session_id).toBe(ownerA.sessionId);
    const ownerB = await selection(page);
    expect(ownerB.profileId).toBe(ownerA.profileId);
    expect(ownerB.gatewayId).not.toBe(ownerA.gatewayId);
    await expect(history('B')).toBeVisible();
    await expect(history('A')).toHaveCount(0);
    // The obsolete connect still awaits its session-list read after discovery.
    // Drain that actual response and Flutter's next frames before asserting B;
    // do not disconnect immediately after merely fulfilling discovery.
    const oldList = page.waitForResponse(response => {
      const url = new URL(response.url());
      return url.origin === originA && url.pathname === '/api/sessions';
    });
    release();
    await (await oldList).finished();
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    await expect.poll(() => settled).toBe(oldReads);
    expect(await selection(page)).toEqual(ownerB);
    const current = await state(page);
    expect(current.status).toBe('connected');
    expect(current.selected_profile_id).toBe(ownerB.profileId);
    expect(current.active_session_id).toBe(ownerB.sessionId);
    await expect(history('B')).toBeVisible();
    await expect(history('A')).toHaveCount(0);
    await page.getByRole('button', { name: 'All chats', exact: true }).click();
    await expect(page.getByLabel(/Synthetic owner A.*online/)).toBeVisible();
    await expect(page.getByLabel(/Synthetic owner B.*online/)).toBeVisible();
    await page.screenshot({ path: info.outputPath('two-saved-owners.png') });
    expect((await (await request.get(`${APP_URL}e2e/hermes/session-restoration`)).json()).counters.mutations).toBe(0);
    await writeFile(info.outputPath('two-owner.json'), JSON.stringify({ ownerA, ownerB, oldReads, settled, canonicalHistoryOwner: 'B', replacement: 'public All chats then saved B', oldReadBarrier: 'session-list response finished and two Flutter frames; no internal future hook', staleOwnerMutations: 0 }, null, 2));
  });
}
