import { test, expect } from '@playwright/test';
import { writeFile } from 'node:fs/promises';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

test.describe.configure({ retries: 0 });
const CONTROL = `${APP}e2e/hermes/lifecycle`;
const SESSION = 'e2e-hermes-session';
const PAIR = { provider: 'alpha', model: 'alpha/model-99' };
const prompts = ['Synthetic daily approved prompt', 'Synthetic daily stopped prompt', 'Synthetic daily resumed prompt'];

const turn = (page, text) => page.getByRole('group', {
  name: new RegExp(`(?:^| )${text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`),
});

async function receipt(request) {
  const response = await request.get(CONTROL);
  expect(response.ok()).toBeTruthy();
  return response.json();
}

function mutations(state) {
  return Object.fromEntries(['submits', 'approvals', 'stops', 'model_locks', 'unexpected_mutations']
    .map(key => [key, state[key]]));
}

async function savedSelection(page) {
  // Only the non-secret pointer written by the real contact cache is inspected.
  return page.evaluate(() => {
    let value = localStorage.getItem('flutter.wing.hermes.gateway_contact_selection.v1');
    for (let i = 0; i < 2 && typeof value === 'string'; i += 1) value = JSON.parse(value);
    return value;
  });
}

async function ready(page) {
  await page.waitForFunction(() => typeof globalThis.wingE2EReduceMotion === 'function');
  await page.evaluate(() => globalThis.wingE2EReduceMotion());
  await enableFlutterAccessibility(page, { delay: 0 });
}

async function fillFlutter(page, field, text, { reactivate = false } = {}) {
  await expect(field).toBeEnabled();
  await field.click();
  await page.waitForTimeout(100);
  const input = page.locator('input:focus, textarea:focus');
  if (await input.count() === 0) {
    await field.click();
    await page.waitForTimeout(100);
  }
  await expect(input).toHaveCount(1);
  if (reactivate) {
    const editor = await input.elementHandle();
    await page.keyboard.press('Tab');
    await editor.click();
    await page.waitForTimeout(100);
    await expect(input).toHaveCount(1);
  }
  await input.fill(text);
  await expect(input).toHaveValue(text);
}

async function send(page, text) {
  await fillFlutter(page, page.getByRole('textbox', { name: 'Message Endpoint contact…', exact: true }), text, { reactivate: true });
  await page.getByRole('button', { name: 'Send', exact: true }).click();
  await expect(turn(page, text)).toBeVisible();
}

async function expectModel(page) {
  await expect(page.getByRole('checkbox', { name: PAIR.model, exact: true })).toBeVisible();
}

for (const width of [390, 1280]) {
  test(`continuous desktop daily workflow restores exact off-page owner at ${width}px`, async ({ page, request }, testInfo) => {
    test.setTimeout(120000);
    const seeded = await request.post(CONTROL, { data: { scenario: 'desktop-daily' } });
    expect(seeded.ok()).toBeTruthy();
    const stages = [];
    const errors = [];
    const writes = [];
    page.on('pageerror', error => errors.push(error.name));
    page.on('request', req => {
      if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method())) {
        writes.push({ method: req.method(), route: new URL(req.url()).pathname });
      }
    });
    await page.setViewportSize({ width, height: 900 });
    await page.goto(`${APP}#/hermes/add`);
    await ready(page);
    await fillFlutter(page, page.getByRole('textbox', { name: 'Hermes Agent URL', exact: true }), new URL(APP).origin);
    await fillFlutter(page, page.getByRole('textbox', { name: 'Connection name (optional)', exact: true }), 'Synthetic daily host');
    await page.getByRole('button', { name: 'Add Hermes', exact: true }).click();
    // Activate the saved default-profile contact; no connection/selection hooks.
    await page.getByLabel(/Synthetic daily host.*online/).click();
    await expect(turn(page, 'Synthetic isolated history.')).toBeVisible();
    if (width < 600) {
      await page.getByRole('button', { name: 'More actions', exact: true }).click();
      await page.getByRole('menuitem', { name: 'Sessions', exact: true }).click();
    } else {
      await page.getByRole('button', { name: 'Sessions', exact: true }).click();
    }
    await fillFlutter(page, page.getByRole('textbox', { name: 'Search sessions', exact: true }).last(), 'E2E Hermes Session');
    await expect(page.getByRole('button', { name: /^E2E Hermes Session / })).toHaveCount(0);
    const firstPage = await receipt(request);
    expect(firstPage.restoration.inventory_reads.length).toBeGreaterThan(0);
    expect(firstPage.restoration.inventory_reads.every(read => read.offset === 0 && !read.session_ids.includes(SESSION))).toBeTruthy();
    await page.getByRole('button', { name: 'Load more sessions', exact: true }).last().click();
    await page.getByRole('button', { name: /^E2E Hermes Session / }).last().click();
    await expect(turn(page, 'E2E Hermes is ready.')).toBeVisible();
    await expect.poll(async () => (await savedSelection(page))?.sessionId).toBe(SESSION);
    const owner = await savedSelection(page);
    expect(owner.gatewayId).toBeTruthy();
    expect(owner.profileId).toBe('default');
    expect((await receipt(request)).restoration.inventory_reads.some(read => read.offset === 1 && read.session_ids.includes(SESSION))).toBeTruthy();

    const initialModel = page.getByRole('checkbox', { name: 'hermes-agent', exact: true });
    await expect(initialModel).toBeVisible();
    await initialModel.click();
    const dialog = page.getByLabel('Dialog', { exact: true });
    await fillFlutter(page, page.getByRole('textbox', { name: 'Search models or providers' }), 'ALPHA/MODEL-99');
    await page.getByRole('button', { name: 'alpha/model-99 Display alpha (alpha)', exact: true }).click();
    await page.getByRole('button', { name: 'Use for session', exact: true }).click();
    await expect(dialog.getByText('Hermes could not confirm this session model.', { exact: true })).toBeVisible();
    expect((await receipt(request)).model_locks).toEqual([{ profile_id: 'default', session_id: SESSION, ...PAIR, status: 'rejected' }]);
    await page.getByRole('button', { name: 'Use for session', exact: true }).click();
    await expectModel(page);
    expect((await receipt(request)).model_locks).toEqual([
      { profile_id: 'default', session_id: SESSION, ...PAIR, status: 'rejected' },
      { profile_id: 'default', session_id: SESSION, ...PAIR, status: 'accepted' },
    ]);
    stages.push({ stage: 'explicit-owner-model', owner, receipt: await receipt(request) });

    await send(page, prompts[0]);
    await expect(page.getByRole('button', { name: 'Approve once', exact: true })).toBeVisible();
    expect((await receipt(request)).runs[0]).toMatchObject({ run_id: 'run_1', session_id: SESSION, profile_id: 'default', status: 'waiting_for_approval', request_id: 'approval_run_1' });
    await page.getByRole('button', { name: 'Approve once', exact: true }).click();
    await expect(turn(page, 'Deterministic fixture reply 1.')).toBeVisible();
    await expect(page.getByRole('checkbox', { name: 'Stop', exact: true })).not.toBeVisible();
    if (width < 600) await page.getByRole('button', { name: 'Dismiss tip', exact: true }).click();
    stages.push({ stage: 'approved', receipt: await receipt(request) });

    await send(page, prompts[1]);
    await expect(page.getByRole('button', { name: 'Approve once', exact: true })).toBeVisible();
    await page.getByRole('checkbox', { name: 'Stop', exact: true }).click();
    await expect(page.getByRole('button', { name: 'Reconnect', exact: true })).toBeVisible();
    const stopping = await receipt(request);
    expect(stopping.runs[1]).toMatchObject({ run_id: 'run_2', session_id: SESSION, status: 'stopping' });
    expect(stopping.stops).toEqual([{ run_id: 'run_2', session_id: SESSION, profile_id: 'default', status: 'stopping' }]);
    await expect(page.getByRole('textbox', { name: 'Reconnect to reconcile the active run…', exact: true })).toBeDisabled();
    const sendButton = page.getByRole('button', { name: 'Send', exact: true });
    if (width < 600) await expect(sendButton).not.toBeVisible();
    else await expect(sendButton).toBeDisabled();
    expect(stopping.submits).toHaveLength(2);
    stages.push({ stage: 'acknowledged-not-terminal', receipt: stopping });
    const terminal = await request.post(`${CONTROL}/terminal`, { data: { run_id: 'run_2' } });
    expect(terminal.ok()).toBeTruthy();
    await page.getByRole('button', { name: 'Reconnect', exact: true }).click();
    await expect(turn(page, 'Synthetic canonical stopped outcome.')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Reconnect', exact: true })).not.toBeVisible();
    const beforeLeave = await receipt(request);
    expect(beforeLeave.status_reads.some(read => read.run_id === 'run_2' && read.status === 'stopping')).toBeTruthy();
    expect(beforeLeave.status_reads.some(read => read.run_id === 'run_2' && read.status === 'cancelled')).toBeTruthy();
    stages.push({ stage: 'terminal-reconciled', receipt: beforeLeave });

    // Browser route navigation only, not a connection/restoration shortcut.
    await page.evaluate(() => { location.hash = '#/settings'; });
    await expect(turn(page, 'Synthetic canonical stopped outcome.')).not.toBeVisible();
    await page.evaluate(() => { location.hash = '#/hermes'; });
    await expect(turn(page, 'Synthetic canonical stopped outcome.')).toBeVisible();
    await expect.poll(() => savedSelection(page)).toEqual(owner);
    await expectModel(page);
    const beforeReload = await receipt(request);
    expect(mutations(beforeReload)).toEqual(mutations(beforeLeave));
    stages.push({ stage: 'route-return-no-replay', receipt: beforeReload });
    await page.reload();
    await ready(page);
    await expect(turn(page, 'Synthetic canonical stopped outcome.')).toBeVisible();
    await expect(turn(page, 'Deterministic fixture reply 1.')).toBeVisible();
    await expect.poll(() => savedSelection(page)).toEqual(owner);
    await expectModel(page);
    const restored = await receipt(request);
    expect(mutations(restored)).toEqual(mutations(beforeReload));
    const exactReads = restored.restoration.metadata_reads.slice(beforeReload.restoration.metadata_reads.length);
    expect(exactReads.length).toBeGreaterThan(0);
    expect(exactReads.every(read => read.profile_id === 'default' && read.session_id === SESSION && read.returned_session_id === SESSION && read.status === 200)).toBeTruthy();
    const reloadPages = restored.restoration.inventory_reads.slice(beforeReload.restoration.inventory_reads.length);
    expect(reloadPages.length).toBeGreaterThan(0);
    expect(reloadPages.every(read => read.offset === 0 && !read.session_ids.includes(SESSION))).toBeTruthy();
    const restoredMessages = restored.sessions.find(session => session.session_id === SESSION).messages;
    expect(restoredMessages.map(message => message.id)).toEqual(['assistant-welcome', 'user_run_1', 'canonical_run_1', 'user_run_2', 'canonical_run_2']);
    expect(restored.history_reads.slice(beforeReload.history_reads.length).some(read => read.session_id === SESSION && JSON.stringify(read.message_ids) === JSON.stringify(restoredMessages.map(message => message.id)))).toBeTruthy();
    await page.getByRole('checkbox', { name: PAIR.model, exact: true }).click();
    await expect(dialog.getByText('Selected: Display alpha (alpha) — alpha/model-99', { exact: true })).toBeVisible();
    await page.getByRole('textbox', { name: 'Search models or providers' }).focus();
    await page.keyboard.press('Escape');
    await expect(page.getByText('Use a model for this session', { exact: true })).not.toBeVisible();
    expect(mutations(await receipt(request))).toEqual(mutations(restored));
    stages.push({ stage: 'reload-exact-owner-model-history-no-replay', owner: await savedSelection(page), receipt: restored });

    await send(page, prompts[2]);
    await page.getByRole('button', { name: 'Approve once', exact: true }).click();
    await expect(turn(page, 'Deterministic fixture reply 3.')).toBeVisible();
    await expect(page.getByRole('checkbox', { name: 'Stop', exact: true })).not.toBeVisible();
    const final = await receipt(request);
    expect(final.submits.map(submit => submit.message)).toEqual(prompts);
    expect(final.submits.map(submit => submit.run_id)).toEqual(['run_1', 'run_2', 'run_3']);
    expect(final.submits.every(submit => submit.session_id === SESSION && submit.profile_id === 'default' && submit.input_matches_message)).toBeTruthy();
    expect(final.submits[2].history).toEqual(restoredMessages.map(({ role, content }) => ({ role, content })));
    expect(final.approvals.map(approval => [approval.run_id, approval.request_id, approval.choice])).toEqual([
      ['run_1', 'approval_run_1', 'once'], ['run_3', 'approval_run_3', 'once'],
    ]);
    expect(final.approvals.every(approval => approval.session_id === SESSION && approval.profile_id === 'default')).toBeTruthy();
    expect(final.stops).toEqual(beforeLeave.stops);
    expect(final.model_locks).toEqual(beforeLeave.model_locks);
    expect(final.runs.map(run => run.status)).toEqual(['completed', 'cancelled', 'completed']);
    expect(final.sessions.find(session => session.session_id === 'synthetic-untouched').messages).toEqual([{ id: 'untouched', role: 'assistant', content: 'Synthetic isolated history.' }]);
    expect(final.unexpected_mutations).toEqual([]);
    expect(writes.filter(write => !/^\/v1\/runs(?:\/run_[1-3]\/(?:approval|stop))?$/.test(write.route) && write.route !== `/api/sessions/${SESSION}/model`)).toEqual([]);
    expect(errors).toEqual([]);
    stages.push({ stage: 'explicit-resume-no-duplicates', receipt: final });
    const artifact = testInfo.outputPath(`desktop-daily-workflow-${width}.json`);
    await writeFile(artifact, JSON.stringify({ qualification: 'compiled Flutter synthetic Chromium only; no native or inference acceptance', width, stages, writes }, null, 2));
    await testInfo.attach('integrated daily workflow receipts', { path: artifact, contentType: 'application/json' });
  });
}
