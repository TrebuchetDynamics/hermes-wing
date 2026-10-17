import { test, expect } from '@playwright/test';
import { writeFile } from 'node:fs/promises';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

test.describe.configure({ retries: 0 });
const CONTROL = `${APP}e2e/hermes/lifecycle`;
const SESSION = 'e2e-hermes-session';
const prompts = ['Synthetic approved prompt', 'Synthetic denied prompt',
  'Synthetic stopped prompt', 'Synthetic transport failure prompt', 'Synthetic subsequent prompt'];

function turn(page, text) {
  const escaped = text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return page.getByRole('group', { name: new RegExp(`(?:^| )${escaped}$`) });
}

async function receipt(request) {
  const response = await request.get(CONTROL);
  expect(response.ok()).toBeTruthy();
  return response.json();
}

async function savedSelection(page) {
  return page.evaluate(() => {
    let value = localStorage.getItem('flutter.wing.hermes.gateway_contact_selection.v1');
    for (let i = 0; i < 2 && typeof value === 'string'; i += 1) value = JSON.parse(value);
    return value;
  });
}

function mutationReceipt(value) {
  return { submits: value.submits, approvals: value.approvals, stops: value.stops,
    unexpected: value.unexpected_mutations };
}

async function fillFlutter(page, field, text, { reactivate = false } = {}) {
  await expect(field).toBeEnabled();
  await field.click();
  // Focus through the semantic bridge, then activate the settled native
  // editor. These are UI actions only, never controller or submission hooks.
  await page.waitForTimeout(100);
  const input = page.locator('input:focus, textarea:focus');
  if (await input.count() === 0) {
    await field.click();
    await page.waitForTimeout(100);
  }
  await expect(input).toHaveCount(1);
  if (reactivate) {
    // Re-enter the actual composer editor with user keyboard/pointer actions.
    // A still-focused semantic bridge may have lost its Flutter input handlers
    // during approval. Its accessible name also changes when focused.
    const editor = await input.elementHandle();
    await page.keyboard.press('Tab');
    await editor.click();
    await page.waitForTimeout(100);
    await expect(input).toHaveCount(1);
  }
  // Wait for the focused Flutter editor to settle before typing. Filling the
  // transient semantic input can change its DOM value without updating Dart.
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.type(text);
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  await expect(input).toHaveValue(text);
}

async function selectSession(page, width, title) {
  if (width < 600) {
    await page.getByRole('button', { name: 'More actions', exact: true }).click();
    await page.getByRole('menuitem', { name: 'Sessions', exact: true }).click();
  } else {
    // Chat's header action precedes the shell's Loaded sessions shortcut.
    await page.getByRole('button', { name: 'Sessions', exact: true }).first().click();
  }
  await fillFlutter(page, page.getByRole('textbox', { name: 'Search sessions', exact: true }).last(), title);
  await page.getByRole('button', { name: new RegExp(`^${title} `) }).last().click();
}

async function send(page, text) {
  const composer = page.getByRole('textbox', { name: 'Message Endpoint contact…', exact: true });
  await fillFlutter(page, composer, text, { reactivate: true });
  await page.getByRole('button', { name: 'Send', exact: true }).click();
  await expect(turn(page, text)).toBeVisible();
}

async function reconnect(page) {
  await page.getByRole('button', { name: 'Reconnect', exact: true }).click();
}

for (const width of [390, 1280]) {
  test(`production Chat work approval stop transport recovery at ${width}px`, async ({ page, request }, testInfo) => {
    test.setTimeout(120000);
    const seed = await request.post(CONTROL);
    expect(seed.ok()).toBeTruthy();
    const stages = [];
    const errors = [];
    page.on('pageerror', error => errors.push(error.name));
    const mutations = [];
    page.on('request', req => {
      const url = new URL(req.url());
      if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method())) {
        mutations.push({ method: req.method(), route: url.pathname });
      }
    });
    await page.setViewportSize({ width, height: 1100 });
    await page.goto(`${APP}#/hermes/add`);
    await page.waitForFunction(() => typeof globalThis.wingE2EReduceMotion === 'function');
    await page.evaluate(() => globalThis.wingE2EReduceMotion());
    await enableFlutterAccessibility(page, { delay: 0 });
    await fillFlutter(page, page.getByRole('textbox', { name: 'Hermes Agent URL', exact: true }), new URL(APP).origin);
    await fillFlutter(page, page.getByRole('textbox', { name: 'Connection name (optional)', exact: true }), 'Synthetic journey host');
    await page.getByRole('button', { name: 'Add Hermes', exact: true }).click();
    // Explicit saved host/profile contact; no connect, send, select, or reconnect hooks.
    await page.getByLabel(/Synthetic journey host.*online/).click();
    await expect(turn(page, 'E2E Hermes is ready.')).toBeVisible();
    await selectSession(page, width, 'Synthetic untouched session');
    await expect(turn(page, 'Synthetic isolated history.')).toBeVisible();
    await selectSession(page, width, 'E2E Hermes Session');
    await expect(turn(page, 'E2E Hermes is ready.')).toBeVisible();
    await expect.poll(async () => (await savedSelection(page))?.sessionId).toBe(SESSION);
    const owner = await savedSelection(page);
    expect(owner).toEqual({ gatewayId: expect.any(String), profileId: 'default', sessionId: SESSION });
    stages.push({ stage: 'explicit-owner', owner, receipt: await receipt(request) });

    await send(page, prompts[0]);
    await expect(turn(page, 'Synthetic streamed prelude.')).toBeVisible();
    await expect(page.getByRole('group', { name: 'Code activity', exact: true })).toBeVisible();
    const pendingApproval = (await receipt(request)).runs[0];
    expect(pendingApproval).toMatchObject({
      run_id: 'run_1', session_id: SESSION, status: 'waiting_for_approval', request_id: 'approval_run_1',
    });
    await page.getByRole('button', { name: 'Approve once', exact: true }).click();
    await expect.poll(async () => (await receipt(request)).runs[0]?.status).toBe('completed');
    await expect(page.getByRole('group', { name: /Deterministic fixture reply 1\.$/ })).toBeVisible();
    await expect(page.getByRole('checkbox', { name: 'Stop', exact: true })).not.toBeVisible();
    if (width < 600) {
      await page.getByRole('button', { name: 'Dismiss tip', exact: true }).click();
    }
    stages.push({ stage: 'approved', pending_approval: pendingApproval, receipt: await receipt(request) });

    await send(page, prompts[1]);
    await page.getByRole('button', { name: 'Deny', exact: true }).click();
    await expect.poll(async () => (await receipt(request)).runs[1]?.status).toBe('cancelled');
    // Denial is not generation success. The next explicit intent stays usable.
    await expect(page.getByRole('checkbox', { name: 'Stop', exact: true })).not.toBeVisible();
    stages.push({ stage: 'denied', receipt: await receipt(request) });

    await send(page, prompts[2]);
    await expect(page.getByRole('button', { name: 'Approve once', exact: true })).toBeVisible();
    await page.getByRole('checkbox', { name: 'Stop', exact: true }).click();
    await expect(page.getByRole('button', { name: 'Reconnect', exact: true })).toBeVisible();
    const acknowledged = await receipt(request);
    expect(acknowledged.runs[2]).toMatchObject({ run_id: 'run_3', session_id: SESSION, status: 'stopping' });
    expect(acknowledged.stops).toEqual([{ run_id: 'run_3', session_id: SESSION, profile_id: 'default', status: 'stopping' }]);
    await expect(page.getByRole('textbox', { name: 'Reconnect to reconcile the active run…', exact: true })).toBeDisabled();
    if (width < 600) {
      await expect(page.getByRole('button', { name: 'Send', exact: true })).not.toBeVisible();
      await expect(page.getByRole('button', { name: 'Hands-free voice', exact: true })).toHaveCount(1);
      await expect(page.getByRole('button', { name: 'Hands-free voice', exact: true })).toBeDisabled();
    } else {
      await expect(page.getByRole('button', { name: 'Send', exact: true })).toBeDisabled();
    }
    expect((await receipt(request)).submits).toHaveLength(3);
    stages.push({ stage: 'acknowledged-not-terminal', receipt: acknowledged });
    const stopRequestCount = mutations.length;
    // Test-only terminal gate models Agent interruption finishing AFTER acknowledgment.
    const terminal = await request.post(`${CONTROL}/terminal`, { data: { run_id: 'run_3' } });
    expect(terminal.ok()).toBeTruthy();
    await reconnect(page);
    await expect(turn(page, 'Synthetic canonical stopped outcome.')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Reconnect', exact: true })).not.toBeVisible();
    await expect.poll(() => savedSelection(page)).toEqual(owner);
    const stopRecovery = await receipt(request);
    expect(mutationReceipt(stopRecovery)).toEqual(mutationReceipt(acknowledged));
    expect(mutations).toHaveLength(stopRequestCount);
    stages.push({ stage: 'terminal-stop-reconciled', owner: await savedSelection(page), recovery_mutations: mutations.length - stopRequestCount, receipt: stopRecovery });

    await send(page, prompts[3]);
    await expect(page.getByRole('button', { name: 'Reconnect', exact: true })).toBeVisible();
    const failed = await receipt(request);
    expect(failed.transport_failures).toEqual([{ run_id: 'run_4', session_id: SESSION, profile_id: 'default', status: 'failed' }]);
    stages.push({ stage: 'transport-eof', receipt: failed });
    const failedRequestCount = mutations.length;
    const restored = await request.post(`${CONTROL}/recover`);
    expect(restored.ok()).toBeTruthy();
    await reconnect(page);
    await expect(turn(page, 'Synthetic recovered canonical history.')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Approve once', exact: true })).not.toBeVisible();
    await expect(page.getByRole('button', { name: 'Reconnect', exact: true })).not.toBeVisible();
    await expect.poll(() => savedSelection(page)).toEqual(owner);
    const canonicalRecovery = await receipt(request);
    expect(mutationReceipt(canonicalRecovery)).toEqual(mutationReceipt(failed));
    expect(mutations).toHaveLength(failedRequestCount);
    stages.push({ stage: 'canonical-recovery', owner: await savedSelection(page), recovery_mutations: mutations.length - failedRequestCount, receipt: canonicalRecovery });

    await send(page, prompts[4]);
    await page.getByRole('button', { name: 'Approve once', exact: true }).click();
    await expect(page.getByRole('group', { name: /Deterministic fixture reply 5\.$/ })).toBeVisible();
    const final = await receipt(request);
    expect(final.submits.map(s => s.message)).toEqual(prompts);
    expect(final.submits.map(s => s.run_id)).toEqual(['run_1', 'run_2', 'run_3', 'run_4', 'run_5']);
    expect(final.submits.every(s => s.session_id === SESSION && s.profile_id === 'default' && s.input_matches_message)).toBeTruthy();
    expect(final.approvals.map(a => [a.run_id, a.request_id, a.choice])).toEqual([
      ['run_1', 'approval_run_1', 'once'], ['run_2', 'approval_run_2', 'deny'], ['run_5', 'approval_run_5', 'once'],
    ]);
    expect(final.approvals.every(a => a.session_id === SESSION && a.profile_id === 'default')).toBeTruthy();
    expect(final.runs.map(r => r.status)).toEqual(['completed', 'cancelled', 'cancelled', 'failed', 'completed']);
    expect(final.status_reads.some(r => r.run_id === 'run_3' && r.status === 'stopping')).toBeTruthy();
    expect(final.status_reads.some(r => r.run_id === 'run_3' && r.status === 'cancelled')).toBeTruthy();
    expect(final.status_reads.every(r => r.session_id === SESSION && r.profile_id === 'default')).toBeTruthy();
    expect(final.event_reads.map(r => r.run_id)).toEqual(['run_1', 'run_2', 'run_3', 'run_4', 'run_5']);
    expect(final.history_reads.every(r => r.profile_id === 'default')).toBeTruthy();
    expect(final.unexpected_mutations).toEqual([]);
    expect(final.sessions.find(s => s.session_id === 'synthetic-untouched').messages).toEqual([
      { id: 'untouched', role: 'assistant', content: 'Synthetic isolated history.' },
    ]);
    const canonical = final.sessions.find(s => s.session_id === SESSION).messages;
    expect(canonical.filter(m => m.role === 'user').map(m => m.content)).toEqual(prompts);
    expect(final.submits[4].history).toEqual(canonical.slice(0, -2).map(({ role, content }) => ({ role, content })));
    expect(mutations.filter(m => !/^\/v1\/runs(?:\/run_[1-5]\/(?:approval|stop))?$/.test(m.route))).toEqual([]);
    // Count attempted writes too: a rejected duplicate approval is absent from
    // the fixture's accepted receipts. Five Sends, three answers, one Stop.
    expect(mutations).toHaveLength(9);
    expect(errors).toEqual([]);
    stages.push({ stage: 'usable-subsequent-prompt', receipt: final });
    const artifact = testInfo.outputPath(`production-chat-journey-${width}.json`);
    await writeFile(artifact, JSON.stringify({ qualification: 'deterministic compiled JS-release Chromium; no inference', width, stages, mutations }, null, 2));
    await testInfo.attach('synthetic journey receipts', { path: artifact, contentType: 'application/json' });
  });
}
