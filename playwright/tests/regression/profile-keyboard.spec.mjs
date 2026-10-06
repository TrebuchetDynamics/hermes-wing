import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor, inventoryReceipts } from '../../support/inventory_keyboard.mjs';

// Per-test synthetic read only; the default fixture still has no Profiles API.
const profiles = [
  { id: 'default', name: 'Home profile', revision: 'r1', description: 'Home inventory', model: 'Example/Home' },
  { id: 'coder', name: 'Coding profile', revision: 'r2', description: 'Review [draft].*', model: 'Example/Small' },
  { id: 'bare', name: null, revision: 'r3', description: null, model: null },
];
const rowNames = ['Home profile, ID: default, Active chat, Default', 'Coding profile, ID: coder', 'bare, ID: bare'];
const searchName = 'Search profiles';
const clearName = 'Clear profile search';

for (const width of [390, 1280]) {
  test(`Profiles keyboard-only literal search/clear/shell escape preserves exact Chat owner at ${width}px`, async ({ page }, testInfo) => {
    const trace = [];
    const io = inventoryReceipts(page, ['/api/profiles']);
    const requests = [];
    page.on('request', request => {
      const url = new URL(request.url());
      if (url.pathname === '/health' || url.pathname.startsWith('/api/') || url.pathname.startsWith('/v1/')) {
        requests.push({ origin: url.origin, method: request.method(), path: url.pathname,
          query: Object.fromEntries(url.searchParams), profile: url.searchParams.get('profile') });
      }
    });
    const actor = keyboardActor(page, testInfo, trace);
    const search = actor.control('textbox', searchName);
    const shellRole = width === 390 ? 'tab' : 'button';
    const shellName = width === 390 ? 'Chat' : 'Chat';
    const noMatches = page.locator('flt-semantics').getByText('No matching profiles Try another profile ID, name, description or model, or clear the search.', { exact: true });
    const rows = async names => {
      for (const name of rowNames) {
        const row = actor.control('group', name);
        if (names.includes(name)) await expect(row).toBeVisible();
        else await expect(row).toHaveCount(0);
      }
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
          auth: { ...base.auth, granted_scopes: [...base.auth.granted_scopes, 'profiles:read'] },
          endpoints: { ...base.endpoints,
            profiles: { method: 'GET', path: '/api/profiles', profile_scoped: false, required_scopes: ['profiles:read'] },
          },
        } });
      });
      await page.route(url => url.pathname === '/api/profiles', route => route.fulfill({ status: 200, json: { data: profiles } }));
      await page.setViewportSize({ width, height: 1400 });
      await page.goto(`${APP}#/profiles`);
      await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
      await enableFlutterAccessibility(page, { delay: 500 });
      await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
      await expect(search).toBeVisible();
      await page.evaluate(() => globalThis.wingE2EHermesLoadDefaultProfileInventory());
      // All initialization/state callbacks end here. User workflow is keys only.
      await rows(rowNames);
      await expect(actor.control('button', 'New Profile')).toHaveCount(0);
      for (const name of ['Edit Home profile', 'Edit Coding profile', 'Delete Coding profile', 'Browse folders']) {
        await expect(actor.control('button', name)).toHaveCount(0);
      }
      await io.settle();
      // Host-scoped administrative collection; do not invent a profile query.
      expect(io.readbacks).toEqual([{ path: '/api/profiles', query: {}, profile: null, status: 200, body: { data: profiles } }]);
      expect(requests.filter(r => r.path === '/api/profiles')).toEqual([
        { origin: new URL(APP).origin, method: 'GET', path: '/api/profiles', query: {}, profile: null },
      ]);
      const beforeOwner = await owner();
      // This fixture has no model-inventory capability. Nulls are real readback,
      // not an inferred selection or synthetic management/model grant.
      expect(beforeOwner).toEqual({ profile: 'default', session: 'e2e-hermes-session', provider: null, model: null });
      const initial = requests.length;
      await actor.reach('textbox', searchName);
      await actor.visibleFocus('textbox', searchName, 'profile-editor');
      const setQuery = async value => {
        await actor.assertFocus('textbox', searchName);
        await page.keyboard.press('ControlOrMeta+A');
        await actor.record('ControlOrMeta+A');
        await actor.type(searchName, value);
      };
      const hiddenActiveOwners = [];
      for (const query of ['CODER', 'coding PROFILE', 'review [DRAFT].*', 'example/SMALL']) {
        await setQuery(query);
        await rows([rowNames[1]]);
        const currentOwner = await owner();
        expect(currentOwner).toEqual(beforeOwner);
        hiddenActiveOwners.push({ query, owner: currentOwner });
      }
      await setQuery('BARE');
      await rows([rowNames[2]]);
      await expect(actor.control('button', 'Chat with bare')).toBeVisible();
      expect(await owner()).toEqual(beforeOwner);
      await setQuery('.*not present');
      await rows([]);
      await expect(noMatches).toBeVisible();
      for (const text of ['No profiles available', 'Profiles unavailable', 'Loading profiles', 'Profiles could not be loaded from Hermes.', 'Could not load local profiles.']) {
        await expect(page.getByText(text, { exact: true })).toHaveCount(0);
      }
      await actor.press('Tab');
      await actor.assertFocus('button', clearName);
      await actor.visibleFocus('button', clearName, 'profile-clear', 'Shift+Tab');
      // Shell navigation is focus only. Row Chat and shell controls are never activated.
      await actor.reach(shellRole, shellName);
      await actor.visibleFocus(shellRole, shellName, 'profile-shell');
      await actor.reach('button', clearName, 'Shift+Tab');
      await actor.press('Enter');
      await expect(actor.control('button', clearName)).toHaveCount(0);
      await rows(rowNames);
      await expect(noMatches).toHaveCount(0);
      const orderedRows = await page.getByRole('group').evaluateAll(nodes => nodes.map(n => n.getAttribute('aria-label')).filter(name => name && /^(Home profile|Coding profile|bare), ID:/.test(name)));
      expect(orderedRows).toEqual(rowNames);
      await actor.reach('textbox', searchName, 'Shift+Tab');
      await expect(search).toHaveValue('');
      await actor.type(searchName, 'CODER');
      await rows([rowNames[1]]);
      await actor.press('Tab');
      await actor.assertFocus('button', clearName);
      await actor.press('Enter');
      await rows(rowNames);
      await actor.reach('textbox', searchName, 'Shift+Tab');
      await actor.reach(shellRole, shellName);
      await actor.reach('textbox', searchName, 'Shift+Tab');
      await actor.type(searchName, 'BARE');
      await rows([rowNames[2]]);
      const afterOwner = await owner();
      expect(afterOwner).toEqual(beforeOwner);
      await io.settle();
      expect(requests.slice(initial)).toEqual([]);
      expect(io.readbacks).toHaveLength(1);
      expect(requests.filter(r => r.method !== 'GET')).toEqual([]);
      expect(io.errors).toEqual([]);
      await expect(page).toHaveURL(/#\/profiles$/);
      await testInfo.attach('profile-keyboard-receipt.json', { contentType: 'application/json', body: JSON.stringify({
        target: 'compiled JS-release Chromium deterministic read-only fixture only', width, reducedMotion: true,
        bootstrapRequests: requests.slice(0, initial), localKeyboardRequests: requests.slice(initial),
        responseReadbacks: io.readbacks, initialInventoryReads: 1, localControlReads: 0, mutationRequests: 0,
        inventoryOwner: { origin: new URL(APP).origin, operation: 'profiles', scope: 'profiles:read', profileScoped: false },
        beforeOwner, hiddenActiveOwners, afterOwner, orderedRows, revisions: profiles.map(p => ({ id: p.id, revision: p.revision })),
        finalQuery: 'BARE', finalRows: [rowNames[2]], trace, pageErrors: io.errors,
      }) });
    } finally {
      await testInfo.attach('profile-keyboard-trace.json', { contentType: 'application/json', body: JSON.stringify({ trace, requests, readbacks: io.readbacks, errors: io.errors }) });
      await testInfo.attach('profile-keyboard-semantics.txt', { contentType: 'text/plain', body: await page.locator('body').ariaSnapshot() });
    }
  });
}
