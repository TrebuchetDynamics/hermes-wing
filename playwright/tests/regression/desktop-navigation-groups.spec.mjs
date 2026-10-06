import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor, scopedInventory } from '../../support/inventory_keyboard.mjs';

const workflow = [['Chat', '/hermes'], ['Office', '/office'], ['Schedules', '/tasks']];
const utilities = [['Providers', '/providers'], ['Connections', '/gateway'], ['Tools', '/tools'],
  ['Profiles', '/profiles'], ['Persona', '/soul'], ['Settings', '/settings']];
const destinations = [...workflow, ...utilities];

test('desktop groups preserve named route selection, collapse and compact More recovery', async ({ page }, testInfo) => {
  const trace = [], requests = [], errors = [], snapshots = [];
  const actor = keyboardActor(page, testInfo, trace);
  page.on('pageerror', error => errors.push(error.message));
  page.on('request', request => {
    const url = new URL(request.url());
    if (url.pathname.startsWith('/api/') || url.pathname.startsWith('/v1/') || url.pathname.startsWith('/health')) {
      requests.push({ method: request.method(), path: url.pathname, query: Object.fromEntries(url.searchParams) });
    }
  });
  const owner = () => page.evaluate(() => {
    const state = JSON.parse(globalThis.wingE2EHermesStateSummary());
    return { profile: state.selected_profile_id, session: state.active_session_id,
      provider: state.assigned_provider, model: state.assigned_model, status: state.status };
  });
  const group = name => page.getByRole('group', { name, exact: true });
  const selected = async label => {
    for (const [name] of destinations) {
      const button = group(workflow.some(([label]) => label === name) ? 'Workflow' : 'Utilities')
        .getByRole('button', { name, exact: true });
      await expect(button).toHaveCount(1);
      if (name === label) await expect(button).toHaveAttribute('aria-current', 'true');
      else await expect(button).not.toHaveAttribute('aria-current', 'true');
    }
  };
  try {
    await scopedInventory(page, []);
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.goto(`${APP}#/profiles`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
    await enableFlutterAccessibility(page, { delay: 500 });
    await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
    await expect.poll(owner).toEqual({ profile: 'default', session: 'e2e-hermes-session', provider: null, model: null, status: 'connected' });
    const beforeOwner = await owner();
    await expect(actor.control('button', 'Collapse')).toHaveAttribute('aria-expanded', 'true');
    for (const [name] of workflow) await expect(group('Workflow').getByRole('button', { name, exact: true })).toHaveCount(1);
    for (const [name] of utilities) await expect(group('Utilities').getByRole('button', { name, exact: true })).toHaveCount(1);
    const first = await group('Workflow').boundingBox(), second = await group('Utilities').boundingBox();
    expect(first.y + first.height).toBeLessThan(second.y);
    await selected('Profiles');
    snapshots.push(await page.locator('body').ariaSnapshot());

    for (const collapsed of [false, true]) {
      if (collapsed) {
        await actor.reach('button', 'Collapse');
        await actor.visibleFocus('button', 'Collapse', 'sidebar-collapse');
        await actor.press('Space');
        await expect(actor.control('button', 'Expand')).toHaveAttribute('aria-expanded', 'false');
      }
      for (const [index, [name, path]] of destinations.entries()) {
        await actor.reach('button', name, index % 2 ? 'Shift+Tab' : 'Tab');
        if (name === 'Chat' || name === 'Connections') await actor.visibleFocus('button', name, `${collapsed ? 'collapsed' : 'expanded'}-${name.toLowerCase()}`);
        await actor.press(index % 2 ? 'Space' : 'Enter');
        await expect(page).toHaveURL(new RegExp(`#${path}$`));
        await selected(name);
        await expect(actor.control('button', collapsed ? 'Expand' : 'Collapse')).toHaveCount(1);
        expect(await owner()).toEqual(beforeOwner);
      }
      snapshots.push(await page.locator('body').ariaSnapshot());
    }

    await page.setViewportSize({ width: 390, height: 844 });
    await expect(group('Workflow')).toHaveCount(0);
    await expect(group('Utilities')).toHaveCount(0);
    for (const name of ['Chat', 'Profiles', 'Connections', 'More']) await expect(actor.control('tab', name)).toHaveCount(1);
    await actor.reach('tab', 'More'); await actor.press('Enter');
    await actor.reach('button', 'Office'); await actor.press('Space');
    // Compact More retains the existing imperative push contract: its active
    // page changes without replacing the root route-information URL.
    await expect(page.getByRole('heading', { name: 'Office', exact: true })).toBeVisible();
    await actor.reach('tab', 'More'); await actor.press('Space');
    await actor.reach('button', 'Schedules'); await actor.press('Enter');
    await expect(page.getByRole('heading', { name: 'Schedules', exact: true })).toBeVisible();
    await actor.reach('tab', 'Chat'); await actor.press('Enter');
    await expect(page).toHaveURL(/#\/hermes$/);
    await page.setViewportSize({ width: 1280, height: 900 });
    await expect(actor.control('button', 'Expand')).toHaveCount(1);
    await selected('Chat');
    await actor.reach('button', 'Expand'); await actor.press('Enter');
    await expect(actor.control('button', 'Collapse')).toHaveCount(1);
    expect(await owner()).toEqual(beforeOwner);
    expect(requests.every(request => request.method === 'GET')).toBe(true);
    expect(requests.filter(request => /\/sessions\/.+\/select|\/profiles\/.+\/select/.test(request.path))).toEqual([]);
    expect(errors).toEqual([]);
    await testInfo.attach('navigation-receipt.json', { contentType: 'application/json', body: JSON.stringify({
      target: 'compiled JS-release Chromium synthetic fixture only', desktop: [1280, 900], compact: [390, 844],
      beforeOwner, afterOwner: await owner(), requests, errors, trace, snapshots,
      limits: 'No native desktop, physical Android, screen-reader or live Agent qualification',
    }) });
  } finally {
    await testInfo.attach('navigation-semantics.txt', { contentType: 'text/plain', body: await page.locator('body').ariaSnapshot() });
    await testInfo.attach('navigation-trace.json', { contentType: 'application/json', body: JSON.stringify({ trace, requests, errors, snapshots }) });
  }
});
