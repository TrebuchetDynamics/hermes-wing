import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

// Per-test synthetic, read-only inventory; the normal fixture remains unavailable.
const providers = [
  { slug: 'candidate', label: 'Other', auth_type: 'oauth', configured: false },
  { slug: 'alpha', label: 'Display [alpha].*', auth_type: 'api_key', configured: true, env_vars: ['NOT_SEARCHABLE_ENV'], key_hint: '····ab12' },
  { slug: 'bare', label: null, auth_type: null },
  { slug: 'second', label: 'Second', auth_type: 'api_key', configured: true },
];
const models = {
  catalog: { providers: { alpha: { models: [{ id: 'selected' }] } } },
  active: { provider: 'alpha', model: 'selected' }, auxiliary: [], revision: 'r1',
};
for (const width of [390, 1280]) {
  test(`Providers literal local search/no-match/keyboard clear preserves model and Chat with zero calls at ${width}px`, async ({ page }, testInfo) => {
    const requests = [];
    const inventories = [];
    const pending = [];
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('request', request => {
      const url = new URL(request.url());
      if (url.pathname.startsWith('/api/') || url.pathname.startsWith('/v1/')) {
        requests.push({ method: request.method(), path: url.pathname, profile: url.searchParams.get('profile') });
      }
    });
    page.on('response', response => {
      const path = new URL(response.url()).pathname;
      if (['/api/providers', '/api/models'].includes(path)) {
        pending.push(response.json().then(body => inventories.push({ path, status: response.status(), body })));
      }
    });
    await page.route(url => url.pathname === '/v1/capabilities', async route => {
      const response = await route.fetch();
      const base = await response.json();
      await route.fulfill({ response, json: {
        ...base,
        profile_context: { type: 'query', name: 'profile', required: true, default_profile_id: 'default' },
        auth: { ...base.auth, granted_scopes: [...base.auth.granted_scopes, 'providers:read', 'models:read'] },
        endpoints: { ...base.endpoints,
          providers: { method: 'GET', path: '/api/providers', required_scopes: ['providers:read'] },
          models: { method: 'GET', path: '/api/models', required_scopes: ['models:read'] },
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
    const search = page.getByRole('textbox', { name: 'Search providers', exact: true });
    const clear = page.getByRole('button', { name: 'Clear provider search', exact: true });
    const row = name => page.getByRole('group', { name: new RegExp(`^${name},`) });
    await expect(search).toBeVisible();
    await expect(page.getByText('Active model alpha / selected', { exact: true })).toBeVisible();
    await expect(row('Second')).toBeVisible();
    await Promise.all(pending);
    expect(inventories.sort((a, b) => a.path.localeCompare(b.path))).toEqual([
      { path: '/api/models', status: 200, body: models },
      { path: '/api/providers', status: 200, body: { data: providers } },
    ]);
    const owner = async () => page.evaluate(() => {
      const state = JSON.parse(globalThis.wingE2EHermesStateSummary());
      return { profile: state.selected_profile_id, session: state.active_session_id,
        provider: state.assigned_provider, model: state.assigned_model };
    });
    const before = await owner();
    expect(before).toEqual({ profile: 'default', session: 'e2e-hermes-session', provider: 'alpha', model: 'selected' });
    const initial = requests.length;
    const setQuery = async value => {
      await search.click();
      await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
      await page.keyboard.press('ControlOrMeta+A');
      await page.keyboard.type(value);
      await expect(search).toHaveValue(value);
    };
    for (const query of ['ALPHA', 'display [ALPHA].*']) {
      await setQuery(query);
      await expect(page.getByRole('group', { name: 'Display [alpha].*, API key, Configured', exact: true })).toBeVisible();
      await expect(row('Second')).toHaveCount(0);
      await expect(page.getByText('Available providers', { exact: true })).toHaveCount(0);
      await expect(page.getByText('Active model alpha / selected', { exact: true })).toBeVisible();
    }
    await setQuery('BARE');
    await expect(row('bare')).toBeVisible();
    await expect(page.getByText('Configured providers', { exact: true })).toHaveCount(0);
    for (const query of ['NOT_SEARCHABLE_ENV', 'ab12', 'oauth', '.*missing']) {
      await setQuery(query);
      await expect(page.locator('flt-semantics').getByText('No matching providers Try another provider name or slug, or clear the search.', { exact: true })).toBeVisible();
      await expect(row('bare')).toHaveCount(0);
      await expect(page.getByText('No providers available', { exact: true })).toHaveCount(0);
    }
    await search.click();
    await page.keyboard.press('Tab');
    await page.keyboard.press('Enter');
    await expect(clear).toHaveCount(0);
    await expect(row('Second')).toBeVisible();
    await expect(row('Other')).toBeVisible();
    const labels = await page.getByRole('group').evaluateAll(nodes => nodes.map(n => n.getAttribute('aria-label')).filter(x => x && /^(Display \[alpha\]\.\*|Second|Other|bare),/.test(x)));
    expect(labels.map(x => x.split(',')[0])).toEqual(['Display [alpha].*', 'Second', 'Other', 'bare']);
    await search.click();
    await expect(search).toHaveValue('');
    const after = await owner();
    expect(after).toEqual(before);
    expect(requests.slice(initial)).toEqual([]);
    expect(requests.filter(r => r.path === '/api/providers')).toEqual([{ method: 'GET', path: '/api/providers', profile: 'default' }]);
    expect(requests.some(r => r.method !== 'GET')).toBe(false);
    expect(errors).toEqual([]);
    await testInfo.attach('provider-search-receipt.json', { body: JSON.stringify({
      target: 'compiled Chromium deterministic read-only fixture only', width, reducedMotion: true,
      inventoryResponseReadbacks: inventories, requests, localSearchAndClearRequests: requests.slice(initial),
      beforeOwner: before, afterOwner: after, orderedLabels: labels, pageErrors: errors,
    }), contentType: 'application/json' });
  });
}
