import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

const CONTROL = `${APP}e2e/hermes/lifecycle`;
const summary = page => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()));
const receipt = async request => (await request.get(CONTROL)).json();
const settledFrames = page => page.evaluate(() => new Promise(resolve =>
  requestAnimationFrame(() => requestAnimationFrame(resolve))));
async function focusControl(page, field) {
  await expect(field).toBeEnabled();
  let target = await field.elementHandle();
  // Use the same settled keyboard traversal as the inventory journeys. A
  // semantic pointer focus after approval can precede Flutter's input handlers;
  // waiting on :focus alone neither activates nor reacquires the editor.
  for (let step = 0; step < 64; step++) {
    // Session transitions can replace the semantic editor. Conversely a named
    // form field can drop its label on focus, so retain its current handle then.
    const candidates = await field.elementHandles();
    if (candidates.length === 1) target = candidates[0];
    await page.keyboard.press('Tab');
    await settledFrames(page);
    if (await target.evaluate(element => element === document.activeElement || element.contains(document.activeElement))) {
      return target;
    }
  }
  throw new Error('Keyboard could not reach the enabled control within 64 Tab keys');
}
async function focusEditor(page, field) {
  await focusControl(page, field);
  const input = page.locator('input:focus, textarea:focus');
  await expect(input).toBeFocused();
  return input;
}
async function fill(page, name, value) {
  const field = name.startsWith('Message ') ? page.getByRole('textbox').last() : page.getByRole('textbox', { name, exact: true });
  const input = await focusEditor(page, field);
  // Type only after activation, not into a transient semantic DOM value.
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.type(value);
  await settledFrames(page);
  await expect(input).toHaveValue(value);
  await page.keyboard.press('Tab');
  await expect.poll(() => page.locator('body').ariaSnapshot()).toContain(value);
}
async function expectDraft(page, text) {
  // Re-enter the editor: an unfocused semantic DOM value can be stale.
  const input = await focusEditor(page, page.getByRole('textbox').last());
  await expect(input).toHaveValue(text);
  return input;
}
async function chooseHistory(page, width, title) {
  if (width < 600) {
    await page.getByRole('button', { name: 'More actions', exact: true }).click();
    await page.getByRole('menuitem', { name: 'Sessions', exact: true }).click();
  } else await page.getByRole('button', { name: 'Sessions', exact: true }).first().click();
  await fill(page, 'Search sessions', title);
  await page.getByRole('button', { name: new RegExp(`^${title} `) }).last().click();
}

for (const width of [390, 1280]) {
  test(`lost tab recovery preserves the other session-owned run at ${width}px`, async ({ page, request }) => {
    test.setTimeout(120000);
    expect((await request.post(CONTROL, { data: { scenario: 'tab-reconnect' } })).ok()).toBe(true);
    const errors = [];
    const mutations = [];
    page.on('request', request => {
      const path = new URL(request.url()).pathname;
      if (/^\/(api|v1)\//.test(path) && ['POST', 'PUT', 'PATCH', 'DELETE'].includes(request.method())) {
        mutations.push([request.method(), path]);
      }
    });
    page.on('pageerror', error => errors.push(error.name));
    page.on('console', message => {
      if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(message.text())) errors.push('render error');
    });
    await page.setViewportSize({ width, height: 1000 });
    await page.goto(`${APP}#/hermes/add`);
    await page.waitForFunction(() => typeof globalThis.wingE2EReduceMotion === 'function');
    await page.evaluate(() => globalThis.wingE2EReduceMotion());
    await enableFlutterAccessibility(page, { delay: 0 });
    await fill(page, 'Hermes Agent URL', new URL(APP).origin);
    await fill(page, 'Connection name (optional)', 'Synthetic workspace recovery');
    await page.getByRole('button', { name: 'Add Hermes', exact: true }).click();
    await page.getByLabel(/Synthetic workspace recovery.*online/).click();
    await expect.poll(async () => (await summary(page)).active_session_id).toBe('e2e-hermes-session');
    await fill(page, 'Message Endpoint contact…', 'Synthetic independent run A');
    await page.getByRole('button', { name: 'Send', exact: true }).click();
    await expect(page.getByRole('button', { name: 'Approve once', exact: true })).toBeVisible();
    await chooseHistory(page, width, 'Synthetic untouched session');
    await expect.poll(async () => (await summary(page)).active_session_id).toBe('synthetic-untouched');
    await fill(page, 'Message Endpoint contact…', 'Synthetic independent run B');
    await page.getByRole('button', { name: 'Send', exact: true }).click();
    await expect.poll(async () => (await receipt(request)).submits.length).toBe(2);
    await expect(page.getByRole('button', { name: 'Approve once', exact: true })).toBeVisible();
    await fill(page, 'Message Endpoint contact…', 'Synthetic retained sibling draft');
    expect((await request.post(`${CONTROL}/disconnect`, { data: { run_id: 'run_1' } })).ok()).toBe(true);
    await expect.poll(async () => (await receipt(request)).status_reads.some(r => r.run_id === 'run_1')).toBe(true);
    expect((await summary(page)).active_session_id).toBe('synthetic-untouched');
    await expectDraft(page, 'Synthetic retained sibling draft');
    await page.keyboard.press('Control+PageDown');
    await expect.poll(async () => (await summary(page)).active_session_id).toBe('e2e-hermes-session');
    await expect(page.getByRole('button', { name: 'Reconnect', exact: true })).toBeVisible();
    expect((await request.post(`${CONTROL}/recover`, { data: { run_id: 'run_1' } })).ok()).toBe(true);
    let release;
    const held = new Promise(resolve => { release = resolve; });
    let entered = false;
    await page.route(url => url.pathname === '/v1/runs/run_1', async route => {
      entered = true;
      await held;
      await route.continue();
    });
    const beforeRecovery = await summary(page);
    await page.getByRole('button', { name: 'Reconnect', exact: true }).click();
    await expect.poll(() => entered).toBe(true);
    expect((await summary(page)).reconciliations_started).toBe(beforeRecovery.reconciliations_started + 1);
    await page.keyboard.press('Control+PageDown');
    await expect.poll(async () => (await summary(page)).active_session_id).toBe('synthetic-untouched');
    const focusedSibling = await focusControl(page,
      page.getByRole('button', { name: 'Close Synthetic untouched session', exact: true }));
    release();
    await expect.poll(async () => (await summary(page)).reconciliations_completed).toBe(beforeRecovery.reconciliations_completed + 1);
    expect(await focusedSibling.evaluate(element => document.activeElement === element)).toBe(true);
    await expect.poll(() => page.locator('body').ariaSnapshot()).toContain('Synthetic retained sibling draft');
    expect((await summary(page)).active_session_id).toBe('synthetic-untouched');
    await expect(page.getByText('Synthetic canonical tab recovery.', { exact: true })).not.toBeVisible();
    await page.keyboard.press('Control+PageDown');
    await expect.poll(async () => (await summary(page)).active_session_id).toBe('e2e-hermes-session');
    await expect(page.getByRole('group', { name: /Synthetic canonical tab recovery\.$/ })).toBeVisible();
    const final = await receipt(request);
    expect(final.submits.map(r => [r.run_id, r.session_id, r.profile_id])).toEqual([
      ['run_1', 'e2e-hermes-session', 'default'], ['run_2', 'synthetic-untouched', 'default'],
    ]);
    expect(final.event_reads.filter(r => r.run_id === 'run_2')).toHaveLength(1);
    expect(final.runs.find(r => r.run_id === 'run_2').status).toBe('waiting_for_approval');
    expect(final.approvals).toEqual([]);
    expect(final.stops).toEqual([]);
    expect(final.unexpected_mutations).toEqual([]);
    expect(mutations).toEqual([['POST', '/v1/runs'], ['POST', '/v1/runs']]);
    expect(errors).toEqual([]);
  });

  test(`owner-bound workspace drafts, keyboard switching and uncertain Stop close at ${width}px`, async ({ page, request }) => {
    test.setTimeout(120000);
    expect((await request.post(CONTROL)).ok()).toBe(true);
    const errors = [];
    page.on('pageerror', error => errors.push(error.name));
    page.on('console', message => {
      if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(message.text())) errors.push('render error');
    });
    await page.setViewportSize({ width, height: 1000 });
    await page.goto(`${APP}#/hermes/add`);
    await page.waitForFunction(() => typeof globalThis.wingE2EReduceMotion === 'function');
    await page.evaluate(() => globalThis.wingE2EReduceMotion());
    await enableFlutterAccessibility(page, { delay: 0 });
    await fill(page, 'Hermes Agent URL', new URL(APP).origin);
    await fill(page, 'Connection name (optional)', 'Synthetic workspace host');
    await page.getByRole('button', { name: 'Add Hermes', exact: true }).click();
    await page.getByLabel(/Synthetic workspace host.*online/).click();
    await expect.poll(async () => (await summary(page)).active_session_id).toBe('e2e-hermes-session');
    await fill(page, 'Message Endpoint contact…', 'Synthetic short A');
    await chooseHistory(page, width, 'Synthetic untouched session');
    await expect.poll(async () => (await summary(page)).active_session_id).toBe('synthetic-untouched');
    await expect(page.getByRole('group', { name: /Synthetic isolated history\.$/ })).toBeVisible();
    await fill(page, 'Message Endpoint contact…', 'Synthetic deliberately longer draft B');
    // Chromium reserves Ctrl+Tab; Ctrl+PageDown/PageUp are the shared alternate.
    await page.keyboard.press('Control+PageDown');
    await expect.poll(async () => (await summary(page)).active_session_id).toBe('e2e-hermes-session');
    await expectDraft(page, 'Synthetic short A');
    await page.keyboard.press('Control+PageUp');
    await expect.poll(async () => (await summary(page)).active_session_id).toBe('synthetic-untouched');
    await expectDraft(page, 'Synthetic deliberately longer draft B');
    await page.keyboard.press('Control+PageDown');
    await expect.poll(async () => (await summary(page)).active_session_id).toBe('e2e-hermes-session');
    await fill(page, 'Message Endpoint contact…', 'Synthetic captured workspace run');
    await page.getByRole('button', { name: 'Send', exact: true }).click();
    await expect(page.getByRole('button', { name: 'Approve once', exact: true })).toBeVisible();
    await page.getByRole('button', { name: 'Close E2E Hermes Session', exact: true }).click();
    await page.getByRole('button', { name: 'Stop and close', exact: true }).click();
    await expect(page.getByText(/^Stop is not confirmed\./)).toBeVisible();
    expect((await receipt(request)).stops).toEqual([{ run_id: 'run_1', session_id: 'e2e-hermes-session', profile_id: 'default', status: 'stopping' }]);
    expect((await receipt(request)).submits).toHaveLength(1);
    await page.getByRole('button', { name: 'Keep open', exact: true }).click();
    await expect(page.getByRole('button', { name: 'Close E2E Hermes Session', exact: true })).toBeVisible();
    expect((await request.post(`${CONTROL}/terminal`, { data: { run_id: 'run_1' } })).ok()).toBe(true);
    await page.getByRole('button', { name: 'Reconnect', exact: true }).click();
    await expect(page.getByRole('group', { name: /Synthetic canonical stopped outcome\.$/ })).toBeVisible();
    await page.getByRole('button', { name: 'Close E2E Hermes Session', exact: true }).click();
    await expect.poll(async () => (await summary(page)).active_session_id).toBe('synthetic-untouched');
    await expectDraft(page, 'Synthetic deliberately longer draft B');

    // A second explicit run exercises direct Stop-and-close success: Agent
    // becomes terminal between Stop acknowledgment and the exact status read.
    await chooseHistory(page, width, 'E2E Hermes Session');
    await expect.poll(async () => (await summary(page)).active_session_id).toBe('e2e-hermes-session');
    await fill(page, 'Message Endpoint contact…', 'Synthetic second explicit workspace run');
    await page.getByRole('button', { name: 'Send', exact: true }).click();
    await expect(page.getByRole('button', { name: 'Approve once', exact: true })).toBeVisible();
    let terminalRead = false;
    await page.route(url => url.pathname === '/v1/runs/run_2', async route => {
      if (!terminalRead && (await receipt(request)).runs.find(run => run.run_id === 'run_2')?.status === 'stopping') {
        expect((await request.post(`${CONTROL}/terminal`, { data: { run_id: 'run_2' } })).ok()).toBe(true);
        terminalRead = true;
      }
      await route.continue();
    });
    await page.getByRole('button', { name: 'Close E2E Hermes Session', exact: true }).click();
    await page.getByRole('button', { name: 'Stop and close', exact: true }).click();
    await expect.poll(async () => (await summary(page)).active_session_id).toBe('synthetic-untouched');
    expect(terminalRead).toBe(true);
    await expect(page.getByRole('button', { name: 'Close E2E Hermes Session', exact: true })).not.toBeVisible();
    await expectDraft(page, 'Synthetic deliberately longer draft B');
    const final = await receipt(request);
    expect(final.submits).toHaveLength(2);
    expect(final.stops).toHaveLength(2);
    expect(final.sessions.find(s => s.session_id === 'synthetic-untouched').messages).toEqual([
      { id: 'untouched', role: 'assistant', content: 'Synthetic isolated history.' },
    ]);
    expect(errors).toEqual([]);
  });
}
