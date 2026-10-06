import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

for (const width of [390, 1280]) {
  test(`Tools local search/independent clear/disclosure and exact refresh at ${width}px`, async ({ page }, testInfo) => {
    const errors = [];
    const requests = [];
    const inventories = [];
    const pendingReadbacks = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('request', request => {
      const path = new URL(request.url()).pathname;
      if (path.startsWith('/api/') || path.startsWith('/v1/')) {
        requests.push({ method: request.method(), path });
      }
    });
    page.on('response', response => {
      const path = new URL(response.url()).pathname;
      if (['/v1/skills', '/v1/toolsets'].includes(path)) {
        pendingReadbacks.push(response.json().then(body => {
          inventories.push({ path, status: response.status(), body });
        }));
      }
    });
    await page.setViewportSize({ width, height: 900 });
    await page.goto(`${APP}#/tools`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
    await enableFlutterAccessibility(page, { delay: 500 });
    await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
    const skills = page.getByRole('textbox', { name: /Search installed skills/ });
    const toolsets = page.getByRole('textbox', { name: /Search toolsets and resolved tools/ });
    const clearSkills = page.getByRole('button', { name: 'Clear installed skills search', exact: true });
    const clearToolsets = page.getByRole('button', { name: 'Clear toolsets search', exact: true });
    const skillsGroup = page.getByRole('group', { name: /^Installed skills/ });

    await expect(skills).toBeVisible();
    await expect(toolsets).toBeVisible();
    await Promise.all(pendingReadbacks);
    expect(inventories.map(i => i.path).sort()).toEqual(['/v1/skills', '/v1/toolsets']);
    for (const inventory of inventories) expect(inventory.status).toBe(200);
    expect(inventories.find(i => i.path === '/v1/skills').body.data.map(i => i.name)).toEqual(['github', 'ascii-art']);
    expect(inventories.find(i => i.path === '/v1/toolsets').body.data.map(i => i.name)).toEqual(['default', 'web']);
    const initial = requests.length;
    expect(requests.filter(r => r.path === '/v1/skills')).toHaveLength(1);
    expect(requests.filter(r => r.path === '/v1/toolsets')).toHaveLength(1);
    const setQuery = async (field, value) => {
      await field.click();
      await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
      await page.keyboard.press('ControlOrMeta+A');
      await page.keyboard.type(value);
      await expect(field).toHaveValue(value);
    };
    await expect(clearSkills).toHaveCount(0);
    await expect(clearToolsets).toHaveCount(0);
    await setQuery(skills, 'CREATIVE');
    await expect(skillsGroup).toContainText('ascii-art');
    await expect(skillsGroup).not.toContainText('GitHub workflow skill');
    await setQuery(toolsets, 'WEB_SEARCH');
    await expect(page.getByRole('button', { name: /Web Tools/ })).toBeVisible();
    await expect(page.getByRole('button', { name: /Default Tools/ })).toHaveCount(0);
    // Tab from the actual editing control to its suffix action; Enter clears
    // only that section. No synthesized fixture state or semantic click script.
    await skills.click();
    await page.keyboard.press('Tab');
    await page.keyboard.press('Enter');
    await expect(clearSkills).toHaveCount(0);
    await expect(skillsGroup).toContainText('GitHub workflow skill');
    await toolsets.click();
    await expect(toolsets).toHaveValue('WEB_SEARCH');
    await page.keyboard.press('Tab');
    await page.keyboard.press('Enter');
    await expect(clearToolsets).toHaveCount(0);
    await expect(page.getByRole('button', { name: /Default Tools/ })).toBeVisible();
    await setQuery(skills, '.*');
    await expect(page.getByText('No installed skills match this search.', { exact: true })).toBeVisible();
    await setQuery(toolsets, '.*');
    await expect(page.getByText('No toolsets match this search.', { exact: true })).toBeVisible();
    await clearSkills.click();
    await expect(clearToolsets).toBeVisible();
    await clearToolsets.click();
    await page.getByRole('button', { name: /Default Tools/ }).click();
    await expect(page.getByRole('checkbox', { name: 'read_file', exact: true })).toBeVisible();
    await page.getByRole('button', { name: /Web Tools/ }).click();
    await expect(page.getByRole('checkbox', { name: 'web_search', exact: true })).toBeVisible();
    expect(requests.slice(initial)).toEqual([]);
    await setQuery(skills, 'GITHUB');
    await setQuery(toolsets, 'WEB_SEARCH');
    expect(requests.slice(initial)).toEqual([]);
    await page.getByRole('button', { name: 'Refresh inventory', exact: true }).click();
    await expect.poll(() => requests.slice(initial).sort((a, b) => a.path.localeCompare(b.path))).toEqual([
      { method: 'GET', path: '/v1/skills' },
      { method: 'GET', path: '/v1/toolsets' },
    ]);
    await expect(skillsGroup).toContainText('GitHub workflow skill');
    await expect(page.getByRole('button', { name: /Web Tools/ })).toBeVisible();
    await skills.click();
    await expect(skills).toHaveValue('GITHUB');
    await toolsets.click();
    await expect(toolsets).toHaveValue('WEB_SEARCH');
    await Promise.all(pendingReadbacks);
    expect(inventories).toHaveLength(4);
    expect(errors).toEqual([]);
    await testInfo.attach('tools-search-receipt.json', {
      body: JSON.stringify({ target: 'compiled Chromium deterministic fixture only', width, reducedMotion: true, initialInventoryReads: 2, localSearchAndClearReads: 0, mutationRequests: 0, explicitRefreshReads: requests.slice(initial), inventoryResponseReadbacks: inventories, pageErrors: errors }),
      contentType: 'application/json',
    });
  });
}
