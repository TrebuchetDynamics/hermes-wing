import { test, expect } from '@playwright/test';
import { writeFile } from 'node:fs/promises';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

// These journeys exercise saved contact activation, not the standalone connect hook.
// No provider inference, lifecycle transitions, or seeded local selection is used.
test.describe.configure({ retries: 0 });
const CONTROL = `${APP}e2e/hermes/session-restoration`;
const OLDER = 'synthetic-restoration-050';
const OTHER = 'synthetic-restoration-001';
const idFor = index => `synthetic-restoration-${String(index).padStart(3, '0')}`;
const titleFor = id => `Synthetic conversation ${id.slice(-3)}`;

const canonicalLabel = id => new RegExp(`(?:^| )Canonical history for ${id}\\.$`);

async function receipt(request) {
  const response = await request.get(CONTROL);
  expect(response.ok()).toBeTruthy();
  return response.json();
}

async function control(request, action, requestId) {
  const response = await request.post(`${CONTROL}/metadata`, {
    data: { action, ...(requestId === undefined ? {} : { request_id: requestId }) },
  });
  expect(response.ok()).toBeTruthy();
  return response.json();
}

async function savedSelection(page) {
  // Read only the non-secret pointer written by the real GatewayContactCache.
  return page.evaluate(() => {
    let value = localStorage.getItem('flutter.wing.hermes.gateway_contact_selection.v1');
    for (let i = 0; i < 2 && typeof value === 'string'; i += 1) value = JSON.parse(value);
    return value;
  });
}

async function expectSelection(page, id, owner) {
  await expect.poll(() => savedSelection(page)).toEqual({
    gatewayId: owner.gatewayId, profileId: owner.profileId, sessionId: id,
  });
}

async function ready(page) {
  await page.waitForFunction(() => typeof globalThis.wingE2EReduceMotion === 'function');
  await page.evaluate(() => globalThis.wingE2EReduceMotion());
  await enableFlutterAccessibility(page, { delay: 0 });
}

async function expectConversation(page, id) {
  // The paired-contact header names the profile, not the session (especially
  // on mobile). Canonical session-specific history and stored ID prove ownership.
  await expect(page.getByRole('banner')).toBeVisible();
  await expect(page.getByRole('group', { name: canonicalLabel(id) })).toBeVisible();
}

async function fillFlutter(page, locator, value) {
  await locator.click();
  // Flutter changes a URL field's accessible name to include its hint when
  // focused. Target the inspected native focused input, not the old semantics.
  const input = page.locator('input:focus, textarea:focus');
  await expect(input).toHaveCount(1);
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.type(value);
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  await expect(input).toHaveValue(value);
}

async function openSessions(page, width) {
  if (width < 600) {
    await page.getByRole('button', { name: 'More actions', exact: true }).click();
    await page.getByRole('menuitem', { name: 'Sessions', exact: true }).click();
  } else {
    await page.getByRole('button', { name: 'Sessions', exact: true }).click();
  }
  await expect(page.getByRole('textbox', { name: 'Search sessions', exact: true }).last()).toBeVisible();
}

async function chooseFromPicker(page, id) {
  const search = page.getByRole('textbox', { name: 'Search sessions', exact: true }).last();
  await fillFlutter(page, search, titleFor(id));
  await page.getByRole('button', { name: new RegExp(`^${titleFor(id)} `) }).last().click();
  await expectConversation(page, id);
}

async function selectPageTwoThroughUi(page, request, width) {
  const seeded = await request.post(CONTROL);
  expect(seeded.ok()).toBeTruthy();
  const initial = await seeded.json();
  expect(initial.session_ids).toEqual(Array.from({ length: 60 }, (_, i) => idFor(i)));
  expect(initial.counters).toEqual({ lists: 0, metadata: 0, messages: 0, mutations: 0 });
  await page.setViewportSize({ width, height: 900 });
  await page.goto(`${APP}#/hermes/add`);
  await ready(page);
  await fillFlutter(page, page.getByRole('textbox', { name: 'Hermes Agent URL', exact: true }), new URL(APP).origin);
  await fillFlutter(page, page.getByRole('textbox', { name: 'Connection name (optional)', exact: true }), 'Synthetic restoration host');
  // The fixture has no real credential. No Wing Link connection or token is used.
  await page.getByRole('button', { name: 'Add Hermes', exact: true }).click();
  await page.getByLabel(/Synthetic restoration host.*online/).click();
  await expectConversation(page, idFor(0));
  await openSessions(page, width);
  const search = page.getByRole('textbox', { name: 'Search sessions', exact: true }).last();
  await fillFlutter(page, search, titleFor(OLDER));
  await expect(page.getByRole('button', { name: new RegExp(`^${titleFor(OLDER)} `) })).toHaveCount(0);
  const before = await receipt(request);
  expect(before.list_pages.length).toBeGreaterThan(0);
  expect(before.list_pages.every(p => p.offset === 0 && p.limit === 50 && p.ids.length === 50 && !p.ids.includes(OLDER))).toBeTruthy();
  await page.getByRole('button', { name: 'Load more sessions', exact: true }).last().click();
  await expect.poll(async () => (await receipt(request)).list_pages.some(p =>
    p.offset === 50 && p.limit === 50 && p.ids.length === 10 && p.ids.includes(OLDER))).toBeTruthy();
  await chooseFromPicker(page, OLDER);
  await expect.poll(async () => (await savedSelection(page))?.sessionId).toBe(OLDER);
  const owner = await savedSelection(page);
  expect(owner.gatewayId).toBeTruthy();
  expect(owner.profileId).toBe('default');
  expect((await receipt(request)).metadata_reads).toEqual([]);
  // Leave the add route without reloading or calling a connect/restore shortcut.
  await page.evaluate(() => { location.hash = '#/hermes'; });
  await expectConversation(page, OLDER);
  return owner;
}

async function reloadForExactRead(page, request) {
  const before = await receipt(request);
  await page.reload();
  await ready(page);
  await expect.poll(async () => (await receipt(request)).metadata_reads.length).toBe(before.counters.metadata + 1);
  const after = await receipt(request);
  expect(after.metadata_reads.at(-1).session_id).toBe(OLDER);
  expect(after.list_pages.slice(before.counters.lists).length).toBeGreaterThan(0);
  expect(after.list_pages.slice(before.counters.lists).every(p => p.offset === 0 && !p.ids.includes(OLDER))).toBeTruthy();
  return { before, read: after.metadata_reads.at(-1) };
}

async function parked(request, requestId) {
  await expect.poll(async () => (await receipt(request)).pending).toEqual([requestId]);
  expect((await receipt(request)).metadata_reads.find(r => r.request_id === requestId)).toMatchObject({
    session_id: OLDER, status: 'reading',
  });
}

async function releaseRead(page, request, requestId, action = 'release') {
  const responded = page.waitForResponse(response =>
    new URL(response.url()).pathname === `/api/sessions/${OLDER}` && response.request().method() === 'GET');
  await control(request, action, requestId);
  const response = await responded;
  expect(response.status()).toBe(action === 'fail' ? 503 : 200);
  if (action === 'release') {
    expect(await response.json()).toMatchObject({ object: 'hermes.session', session: { id: OLDER } });
  }
  await expect.poll(async () => (await receipt(request)).pending).toEqual([]);
  expect((await receipt(request)).metadata_reads.find(r => r.request_id === requestId).status)
    .toBe(action === 'fail' ? 'failed' : 'completed');
}

async function assertReadOnly(request, testInfo, width) {
  const state = await receipt(request);
  expect(state.session_ids).toEqual(Array.from({ length: 60 }, (_, i) => idFor(i)));
  expect(state.mutations).toEqual([]);
  expect(state.counters.mutations).toBe(0);
  expect(state.counters.metadata).toBe(state.metadata_reads.length);
  expect(state.counters.messages).toBe(state.message_reads.length);
  const receiptPath = testInfo.outputPath('session-restoration-receipt.json');
  await writeFile(receiptPath, JSON.stringify({ platform: 'compiled Flutter deterministic Chromium only', width, ...state }));
  await testInfo.attach('session-restoration-receipt.json', {
    path: receiptPath,
    contentType: 'application/json',
  });
}

for (const width of [390, 1280]) {
  test(`page-two UI selection reloads exact canonical session at ${width}px`, async ({ page, request }, testInfo) => {
    const owner = await selectPageTwoThroughUi(page, request, width);
    const { before, read } = await reloadForExactRead(page, request);
    await expectConversation(page, OLDER);
    await expectSelection(page, OLDER, owner);
    expect(read.status).toBe('completed');
    const state = await receipt(request);
    expect(state.message_reads.slice(before.counters.messages).at(-1)).toEqual({
      session_id: OLDER, message_ids: [`${OLDER}-canonical`],
    });
    expect(state.list_pages.filter(p => p.offset === 50)).toHaveLength(1);
    await assertReadOnly(request, testInfo, width);
  });

  test(`parked exact read fails and explicit Retry retains identity at ${width}px`, async ({ page, request }, testInfo) => {
    const owner = await selectPageTwoThroughUi(page, request, width);
    await control(request, 'park');
    const { before, read } = await reloadForExactRead(page, request);
    await parked(request, read.request_id);
    await expect(page.getByRole('heading', { name: 'Restoring your conversation', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Choose session', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Retry', exact: true })).toBeDisabled();
    await expectSelection(page, OLDER, owner);
    // Recovery replaces the composer; no temporary page-one session is writable.
    await expect(page.getByRole('button', { name: 'Send', exact: true })).toHaveCount(0);
    await expect(page.getByRole('heading', { name: titleFor(idFor(0)), exact: true })).toHaveCount(0);
    expect((await receipt(request)).message_reads.slice(before.counters.messages).some(r => r.session_id === OLDER)).toBeFalsy();
    await releaseRead(page, request, read.request_id, 'fail');
    await expect(page.getByRole('heading', { name: 'Conversation not restored', exact: true })).toBeVisible();
    const retry = page.getByRole('button', { name: 'Retry', exact: true });
    await expect(retry).toBeEnabled();
    await expectSelection(page, OLDER, owner);
    await retry.click();
    await expect.poll(async () => (await receipt(request)).metadata_reads.length).toBe(2);
    const retryRead = (await receipt(request)).metadata_reads.at(-1);
    expect(retryRead).toMatchObject({ session_id: OLDER, profile: read.profile });
    await parked(request, retryRead.request_id);
    await expectSelection(page, OLDER, owner);
    await releaseRead(page, request, retryRead.request_id);
    await expectConversation(page, OLDER);
    await expect(page.getByRole('button', { name: 'Choose session', exact: true })).toHaveCount(0);
    await expectSelection(page, OLDER, owner);
    expect((await receipt(request)).message_reads.at(-1)).toEqual({ session_id: OLDER, message_ids: [`${OLDER}-canonical`] });
    await assertReadOnly(request, testInfo, width);
  });

  test(`manual choice supersedes parked restoration; picker cancel retains it at ${width}px`, async ({ page, request }, testInfo) => {
    const owner = await selectPageTwoThroughUi(page, request, width);
    await control(request, 'park');
    const { read } = await reloadForExactRead(page, request);
    await parked(request, read.request_id);
    const choose = page.getByRole('button', { name: 'Choose session', exact: true });
    await choose.click();
    const search = page.getByRole('textbox', { name: 'Search sessions', exact: true }).last();
    await search.focus();
    await page.keyboard.press('Escape');
    await expect(choose).toBeVisible();
    await parked(request, read.request_id);
    await expectSelection(page, OLDER, owner);
    await choose.click();
    await chooseFromPicker(page, OTHER);
    await expectSelection(page, OTHER, owner);
    await parked(request, read.request_id);
    await releaseRead(page, request, read.request_id);
    // A frame fence after the actual response, never a timer as race evidence.
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    await expectConversation(page, OTHER);
    await expectSelection(page, OTHER, owner);
    await expect(page.getByRole('group', { name: canonicalLabel(OLDER) })).toHaveCount(0);
    await expect(choose).toHaveCount(0);
    const state = await receipt(request);
    expect(state.metadata_reads.map(r => r.session_id)).toEqual([OLDER]);
    expect(state.message_reads.at(-1)).toEqual({ session_id: OTHER, message_ids: [`${OTHER}-canonical`] });
    await control(request, 'immediate');
    await page.reload();
    await ready(page);
    await expectConversation(page, OTHER);
    await expectSelection(page, OTHER, owner);
    // OTHER is in page one: no exact lookup is needed, including after the stale response.
    expect((await receipt(request)).metadata_reads.map(r => r.session_id)).toEqual([OLDER]);
    await assertReadOnly(request, testInfo, width);
  });
}
