import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

const CONTROL = `${APP}e2e/hermes/lifecycle`;
const summary = page => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()));
const receipt = async request => (await request.get(CONTROL)).json();
async function fill(page, name, value) {
  const field = name.startsWith('Message ') ? page.getByRole('textbox').last() : page.getByRole('textbox', { name, exact: true });
  await expect(field).toBeEnabled();
  await field.click();
  // Flutter attaches its native editing bridge after semantic focus settles.
  await page.waitForTimeout(100);
  const input = page.locator('input:focus, textarea:focus');
  if (!await input.count()) {
    await field.click();
    await page.waitForTimeout(100);
  }
  await input.fill(value);
  await expect(input).toHaveValue(value);
  await page.keyboard.press('Tab');
  await expect.poll(() => page.locator('body').ariaSnapshot()).toContain(value);
}
async function expectDraft(page, text) {
  // The unfocused Flutter semantic editing bridge can retain its previous DOM
  // value. Re-enter the public editor to read the current controller value.
  await page.getByRole('textbox').last().click();
  await page.waitForTimeout(100);
  const input = page.locator('input:focus, textarea:focus');
  if (!await input.count()) {
    await page.keyboard.press('Tab');
    await page.getByRole('textbox').last().click();
  }
  await expect(input).toHaveValue(text);
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
