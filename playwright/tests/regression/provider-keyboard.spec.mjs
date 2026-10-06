import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor, inventoryReceipts } from '../../support/inventory_keyboard.mjs';

// Per-test synthetic reads only. The normal fixture still advertises no provider API.
const providers = [
  { slug: 'candidate', label: 'Other', auth_type: 'oauth', configured: false },
  { slug: 'alpha', label: 'Display [alpha].*', auth_type: 'api_key', configured: true, env_vars: ['NOT_SEARCHABLE_ENV'], key_hint: '····ab12' },
  { slug: 'bare', label: null, auth_type: null },
  { slug: 'second', label: 'Second', auth_type: 'api_key', configured: true },
];
const models = {
  catalog: { providers: {
    alpha: { models: [{ id: 'selected' }] },
    candidate: { models: [{ id: 'observer' }] },
    second: { models: [{ id: 'title' }] },
  } },
  active: { provider: 'alpha', model: 'selected' },
  auxiliary: [
    { task: 'vision', provider: 'candidate', model: 'observer' },
    { task: 'title_generation', provider: 'second', model: 'title' },
  ],
  revision: 'r1',
};
const assignmentText = 'Active model alpha / selected Auxiliary models Vision: candidate / observer Title generation: second / title';
const rowNames = [
  'Display [alpha].*, API key, Configured',
  'Second, API key, Configured',
  'Other, OAuth sign-in, Not configured',
  'bare, Provider-managed authentication, Not configured',
];
const searchName = 'Search providers';
const clearName = 'Clear provider search';
const receipt = path => ({ method: 'GET', path, query: { profile: 'default' }, profile: 'default' });

for (const width of [390, 1280]) {
  test(`Providers keyboard-only literal search/clear/shell escape preserves full assignment and Chat at ${width}px`, async ({ page }, testInfo) => {
    const trace = [];
    const io = inventoryReceipts(page, ['/api/providers', '/api/models']);
    const requests = [];
    page.on('request', request => {
      const url = new URL(request.url());
      if (url.pathname === '/health' || url.pathname.startsWith('/api/') || url.pathname.startsWith('/v1/')) {
        requests.push({ method: request.method(), path: url.pathname,
          query: Object.fromEntries(url.searchParams), profile: url.searchParams.get('profile') });
      }
    });
    const actor = keyboardActor(page, testInfo, trace);
    const shellRole = width === 390 ? 'tab' : 'button';
    const shellName = width === 390 ? 'Chat' : 'Chat';
    const search = actor.control('textbox', searchName);
    const assignment = page.getByText(assignmentText, { exact: true });
    const noMatches = page.locator('flt-semantics').getByText('No matching providers Try another provider name or slug, or clear the search.', { exact: true });
    const rows = async names => {
      for (const name of rowNames) {
        const row = actor.control('group', name);
        if (names.includes(name)) await expect(row).toBeVisible();
        else await expect(row).toHaveCount(0);
      }
      await expect(assignment).toBeVisible();
    };
    const owner = async () => page.evaluate(() => {
      const state = JSON.parse(globalThis.wingE2EHermesStateSummary());
      return { profile: state.selected_profile_id, session: state.active_session_id,
        provider: state.assigned_provider, model: state.assigned_model };
    });
    try {
      await page.route(url => url.pathname === '/v1/capabilities', async route => {
        const response = await route.fetch();
        const base = await response.json();
        await route.fulfill({ response, json: {
          ...base,
          profile_context: { type: 'query', name: 'profile', required: true, default_profile_id: 'default' },
          auth: { ...base.auth, granted_scopes: [...base.auth.granted_scopes, 'providers:read', 'models:read'] },
          endpoints: { ...base.endpoints,
            providers: { method: 'GET', path: '/api/providers', profile_scoped: true, required_scopes: ['providers:read'] },
            models: { method: 'GET', path: '/api/models', profile_scoped: true, required_scopes: ['models:read'] },
          },
        } });
      });
      await page.route(url => url.pathname === '/api/providers', route => route.fulfill({ status: 200, json: { data: providers } }));
      await page.route(url => url.pathname === '/api/models', route => route.fulfill({ status: 200, json: models }));
      await page.setViewportSize({ width, height: 1400 });
      await page.goto(`${APP}#/providers`);
      await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
      await enableFlutterAccessibility(page, { delay: 500 });
      await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
      // No initialization hooks or pointer/DOM actions after this bootstrap.
      await expect(search).toBeVisible();
      await rows(rowNames);
      await expect(actor.control('button', 'Manage credential')).toHaveCount(0);
      await expect(actor.control('button', 'Choose model')).toHaveCount(0);
      await io.settle();
      expect(io.readbacks.slice().sort((a, b) => a.path.localeCompare(b.path))).toEqual([
        { path: '/api/models', query: { profile: 'default' }, profile: 'default', status: 200, body: models },
        { path: '/api/providers', query: { profile: 'default' }, profile: 'default', status: 200, body: { data: providers } },
      ]);
      expect(io.requests.filter(r => ['/api/providers', '/api/models'].includes(r.path)).sort((a, b) => a.path.localeCompare(b.path)))
        .toEqual([receipt('/api/models'), receipt('/api/providers')]);
      const beforeOwner = await owner();
      expect(beforeOwner).toEqual({ profile: 'default', session: 'e2e-hermes-session', provider: 'alpha', model: 'selected' });
      const initial = requests.length;
      const beforeAssignment = await assignment.textContent();
      await actor.reach('textbox', searchName);
      await actor.visibleFocus('textbox', searchName, 'provider-editor');
      const setQuery = async value => {
        await actor.assertFocus('textbox', searchName);
        await page.keyboard.press('ControlOrMeta+A');
        await actor.record('ControlOrMeta+A');
        await actor.type(searchName, value);
      };
      for (const query of ['ALPHA', 'display [ALPHA].*']) {
        await setQuery(query);
        await rows([rowNames[0]]);
        await expect(page.getByText('Available providers', { exact: true })).toHaveCount(0);
      }
      // Hiding the assigned provider never filters the independent assignment.
      await setQuery('BARE');
      await rows([rowNames[3]]);
      await expect(page.getByText('Configured providers', { exact: true })).toHaveCount(0);
      expect(await owner()).toEqual(beforeOwner);
      for (const query of ['NOT_SEARCHABLE_ENV', 'ab12', 'oauth', 'api_key', '.*missing']) {
        await setQuery(query);
        await rows([]);
        await expect(noMatches).toBeVisible();
        await expect(page.getByText('No providers available', { exact: true })).toHaveCount(0);
        await expect(page.getByText('Providers unavailable', { exact: true })).toHaveCount(0);
        await expect(page.getByText('Providers could not be loaded from Hermes.', { exact: true })).toHaveCount(0);
      }
      await actor.press('Tab');
      await actor.assertFocus('button', clearName);
      await actor.visibleFocus('button', clearName, 'provider-clear', 'Shift+Tab');
      // Forward traversal leaves the route without activating any shell action.
      await actor.reach(shellRole, shellName);
      await actor.visibleFocus(shellRole, shellName, 'provider-shell');
      await actor.reach('button', clearName, 'Shift+Tab');
      await actor.press('Enter');
      await expect(actor.control('button', clearName)).toHaveCount(0);
      await rows(rowNames);
      await expect(noMatches).toHaveCount(0);
      const orderedRows = await page.getByRole('group').evaluateAll(nodes => nodes.map(n => n.getAttribute('aria-label')).filter(name => name && /^(Display \[alpha\]\.\*|Second|Other|bare),/.test(name)));
      expect(orderedRows).toEqual(rowNames);
      await actor.reach('textbox', searchName, 'Shift+Tab');
      await expect(search).toHaveValue('');
      await actor.type(searchName, 'SECOND');
      await rows([rowNames[1]]);
      await actor.press('Tab');
      await actor.assertFocus('button', clearName);
      await actor.press('Enter');
      await rows(rowNames);
      // With clear removed, escape the editor and return backwards to type again.
      await actor.reach('textbox', searchName, 'Shift+Tab');
      // Forward repair: a single empty-editor escape must be exactly reversible.
      await actor.press('Tab');
      await actor.press('Shift+Tab');
      await actor.assertFocus('textbox', searchName);
      if (width === 1280) {
        await page.setViewportSize({ width, height: 360 });
        const settings = actor.control('button', 'Settings');
        const beforeScroll = await settings.boundingBox();
        await actor.reach('button', 'Settings');
        const afterScroll = await settings.boundingBox();
        expect(afterScroll.y).toBeLessThan(beforeScroll.y);
        await actor.press('Tab');
        await actor.press('Shift+Tab');
        await actor.assertFocus('button', 'Settings');
        await page.setViewportSize({ width, height: 1400 });
        await actor.reach('textbox', searchName, 'Shift+Tab');
        await actor.press('Tab');
        await actor.press('Shift+Tab');
        await actor.assertFocus('textbox', searchName);
      }
      await actor.reach(shellRole, shellName);
      await actor.reach('textbox', searchName, 'Shift+Tab');
      await actor.type(searchName, 'BARE');
      await rows([rowNames[3]]);
      const afterAssignment = await assignment.textContent();
      expect(afterAssignment).toBe(beforeAssignment);
      const afterOwner = await owner();
      expect(afterOwner).toEqual(beforeOwner);
      await io.settle();
      expect(requests.slice(initial)).toEqual([]);
      expect(io.readbacks).toHaveLength(2);
      expect(requests.filter(r => r.method !== 'GET')).toEqual([]);
      expect(io.errors).toEqual([]);
      await testInfo.attach('provider-keyboard-receipt.json', { contentType: 'application/json', body: JSON.stringify({
        target: 'compiled JS-release Chromium deterministic read-only fixture only', width, reducedMotion: true,
        bootstrapRequests: requests.slice(0, initial), localKeyboardRequests: requests.slice(initial),
        responseReadbacks: io.readbacks, initialInventoryReads: 2, localControlReads: 0, mutationRequests: 0,
        beforeOwner, afterOwner, beforeAssignment, afterAssignment, fullAssignment: { active: models.active, auxiliary: models.auxiliary, revision: models.revision },
        orderedRows, finalQuery: 'BARE', finalRows: [rowNames[3]], trace, pageErrors: io.errors,
      }) });
    } finally {
      await testInfo.attach('provider-keyboard-trace.json', { contentType: 'application/json', body: JSON.stringify({ trace, requests, readbacks: io.readbacks, errors: io.errors }) });
      await testInfo.attach('provider-keyboard-semantics.txt', { contentType: 'text/plain', body: await page.locator('body').ariaSnapshot() });
    }
  });
}
