import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

// A per-test, read-only synthetic Agent contract; never changes the server's
// default unavailable Profiles behavior or advertises real-service support.
const profiles = [
  { id: 'default', name: 'Home profile', revision: 'r1', description: 'Home inventory', model: 'Example/Home' },
  { id: 'coder', name: 'Coding profile', revision: 'r2', description: 'Review [draft].*', model: 'Example/Small' },
  { id: 'bare', name: null, revision: 'r3', description: null, model: null },
];
for (const width of [390, 1280]) {
  test(`Profiles local search/no-match/keyboard clear preserves Chat and performs zero requests at ${width}px`, async ({ page }, testInfo) => {
    const requests = [];
    const inventories = [];
    const errors = [];
    const pending = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('request', request => {
      const url = new URL(request.url());
      if (url.pathname.startsWith('/api/') || url.pathname.startsWith('/v1/')) {
        requests.push({ method: request.method(), path: url.pathname, profile: url.searchParams.get('profile') });
      }
    });
    page.on('response', response => {
      if (new URL(response.url()).pathname === '/api/profiles') {
        pending.push(response.json().then(body => inventories.push({ status: response.status(), body })));
      }
    });
    await page.route(url => url.pathname === '/v1/capabilities', async route => {
      const response = await route.fetch();
      const base = await response.json();
      await route.fulfill({ response, json: {
        ...base,
        profile_context: { type: 'query', name: 'profile', required: true, default_profile_id: 'default' },
        auth: { ...base.auth, granted_scopes: [...base.auth.granted_scopes, 'profiles:read'] },
        endpoints: { ...base.endpoints, profiles: { method: 'GET', path: '/api/profiles', required_scopes: ['profiles:read'] } },
      } });
    });
    await page.route(url => url.pathname === '/api/profiles', route => route.fulfill({ status: 200, json: { data: profiles } }));
    await page.setViewportSize({ width, height: 1000 });
    await page.goto(`${APP}#/profiles`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
    await enableFlutterAccessibility(page, { delay: 500 });
    await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
    const search = page.getByRole('textbox', { name: 'Search profiles', exact: true });
    const clear = page.getByRole('button', { name: 'Clear profile search', exact: true });
    const activeHome = page.getByRole('group', { name: /Home profile, ID: default, Active chat/ });
    const chat = name => page.getByRole('button', { name: `Chat with ${name}`, exact: true });
    await expect(search).toBeVisible();
    await page.evaluate(() => globalThis.wingE2EHermesLoadDefaultProfileInventory());
    await expect(chat('Home profile')).toBeVisible();
    await expect(activeHome).toBeVisible();
    await Promise.all(pending);
    expect(inventories).toEqual([{ status: 200, body: { data: profiles } }]);
    const initial = requests.length;
    const setQuery = async value => {
      await search.click();
      await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
      await page.keyboard.press('ControlOrMeta+A');
      await page.keyboard.type(value);
      await expect(search).toHaveValue(value);
    };
    for (const query of ['CODER', 'coding PROFILE', 'review [DRAFT].*', 'example/SMALL']) {
      await setQuery(query);
      await expect(chat('Coding profile')).toBeVisible();
      await expect(chat('Home profile')).toHaveCount(0);
      await expect(activeHome).toHaveCount(0);
    }
    await setQuery('BARE');
    await expect(chat('bare')).toBeVisible();
    await setQuery('.*not present');
    await expect(chat('bare')).toHaveCount(0);
    await expect(page.locator('flt-semantics').getByText('No matching profiles Try another profile ID, name, description or model, or clear the search.', { exact: true })).toBeVisible();
    await expect(page.getByText('No profiles available', { exact: true })).toHaveCount(0);
    await search.click();
    await page.keyboard.press('Tab');
    await page.keyboard.press('Enter');
    await expect(clear).toHaveCount(0);
    await expect(chat('Home profile')).toBeVisible();
    await expect(chat('Coding profile')).toBeVisible();
    await expect(chat('bare')).toBeVisible();
    await expect(activeHome).toBeVisible();
    await search.click();
    await expect(search).toHaveValue('');
    expect(requests.slice(initial)).toEqual([]);
    expect(requests.filter(r => r.path === '/api/profiles')).toHaveLength(1);
    expect(requests.some(r => r.method !== 'GET')).toBe(false);
    expect(errors).toEqual([]);
    await testInfo.attach('profile-search-receipt.json', { body: JSON.stringify({
      target: 'compiled Chromium deterministic read-only fixture only', width, reducedMotion: true,
      inventoryResponseReadbacks: inventories, requests, localSearchAndClearRequests: requests.slice(initial),
      finalActiveProfile: 'default (selected semantic group verified)', pageErrors: errors,
    }), contentType: 'application/json' });
  });
}
