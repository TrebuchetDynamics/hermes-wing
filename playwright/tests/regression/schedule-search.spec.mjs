import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

// Bounded synthetic display metadata only; no real Agent or job mutation.
const jobs = [
  { id: 'job_morning', name: 'Morning check', enabled: true, state: 'active', schedule_display: 'Every day at 09:00' },
  { id: 'job_evening', name: 'Evening review', enabled: false, state: 'paused', schedule_display: '0 18 * * *' },
  { id: 'job_failure', name: 'Failed task', enabled: false, state: 'error', schedule_display: 'Every Monday' },
];

for (const width of [390, 1280]) {
  test(`Schedules local search/filter/clear and read-only refresh at ${width}px`, async ({ page }, testInfo) => {
    const errors = [];
    const requests = [];
    let jobRead = 0;

    page.on('pageerror', error => errors.push(error.message));
    page.on('request', request => {
      const path = new URL(request.url()).pathname;
      if (path.startsWith('/api/') || path.startsWith('/v1/')) {
        const query = new URL(request.url()).searchParams;
        requests.push({ method: request.method(), path,
          ...(path === '/api/jobs' ? { profile: query.get('profile'), includeDisabled: query.get('include_disabled') } : {}) });
      }
    });
    await page.route(url => url.pathname === '/v1/capabilities', async route => {
      const response = await route.fetch();
      const catalog = await response.json();
      catalog.profile_context = { type: 'query', name: 'profile', required: true, default_profile_id: 'default' };
      catalog.endpoints.jobs.profile_scoped = true;
      await route.fulfill({ response, json: catalog });
    });
    await page.route(url => url.pathname === '/api/jobs', route => {
      jobRead++;
      return route.fulfill({
        status: jobRead === 3 ? 503 : 200, contentType: 'application/json',
        body: JSON.stringify(jobRead === 3 ? { error: 'synthetic private transport details' } : { jobs }),
      });
    });
    await page.setViewportSize({ width, height: 900 });
    await page.goto(`${APP}#/tasks`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
    await enableFlutterAccessibility(page, { delay: 500 });
    await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
    const search = page.getByRole('textbox', { name: 'Search schedules', exact: true });
    await expect(search).toBeVisible();

    const setQuery = async value => {
      await search.click();
      // Flutter installs its native editing bridge after semantic focus.
      await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
      await page.keyboard.press('ControlOrMeta+A');
      await page.keyboard.type(value);
      await expect(search).toHaveValue(value);
    };
    const cardText = job => `${job.name} ${job.state === 'active' ? 'Active' : job.state === 'paused' ? 'Paused' : 'Error'} Job ID ${job.id} Schedule ${job.schedule_display}`;
    await expect(page.getByText(cardText(jobs[0]), { exact: true })).toBeVisible();
    const initial = requests.length;
    const initialJobReads = requests.filter(r => r.path === '/api/jobs').length;
    expect(initialJobReads).toBe(1);
    const result = async (names) => {
      for (const job of jobs) {
        const title = page.getByText(cardText(job), { exact: true });
        if (names.includes(job.name)) await expect(title).toBeVisible();
        else await expect(title).toHaveCount(0);
      }
    };
    await search.click();
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    await page.keyboard.type('mOrNiNg CHECK');
    await result(['Morning check']);
    await setQuery('JOB_EVENING');
    await result(['Evening review']);
    await setQuery('eVeRy MoNdAy');
    await result(['Failed task']);
    await setQuery('.*');
    await result([]);
    // Exclude Flutter's duplicate aria-live announcement from the visible result.
    const noMatches = page.locator('flt-semantics').getByText('No matching schedules Try another name, job ID or schedule, or clear the filters.', { exact: true });
    await expect(noMatches).toBeVisible();
    await expect(page.getByText('No schedules yet', { exact: true })).toHaveCount(0);
    const clear = page.getByRole('button', { name: 'Clear filters', exact: true });
    await clear.click();
    await result(jobs.map(job => job.name));
    // The clear action keeps focus on its stable button. Refocus the editor
    // before inspecting its native editing value and entering another query.
    await search.click();
    await expect(search).toHaveValue('');
    const enabled = page.getByRole('checkbox', { name: 'Enabled', exact: true });
    const disabled = page.getByRole('checkbox', { name: 'Disabled', exact: true });
    await enabled.click();
    await result(['Morning check']);
    await disabled.click();
    await result(['Evening review', 'Failed task']);
    await setQuery('JOB_MORNING');
    await result([]);
    await expect(noMatches).toBeVisible();
    expect(requests.slice(initial)).toEqual([]);
    await clear.click();
    await expect(clear).toBeEnabled();
    await result(jobs.map(job => job.name));
    expect(requests.slice(initial)).toEqual([]);
    await setQuery('EVENING');
    await result(['Evening review']);
    expect(requests.slice(initial)).toEqual([]);
    await page.getByRole('button', { name: 'Refresh schedules', exact: true }).click();
    await result(['Evening review']);
    await expect(search).toHaveValue('EVENING');
    const receipt = { method: 'GET', path: '/api/jobs', profile: 'default', includeDisabled: 'true' };
    await expect.poll(() => requests.slice(initial)).toEqual([receipt]);
    await expect(page.getByRole('button', { name: 'Refresh schedules', exact: true })).toBeEnabled();
    await page.getByRole('button', { name: 'Refresh schedules', exact: true }).click();
    const retry = page.getByRole('button', { name: 'Retry', exact: true });
    await expect(retry).toBeVisible();
    await result([]);
    await expect(search).toHaveCount(0);
    await expect(noMatches).toHaveCount(0);
    await expect(page.getByText('synthetic private transport details', { exact: false })).toHaveCount(0);
    await expect.poll(() => requests.slice(initial)).toEqual([receipt, receipt]);
    await retry.click();
    await result(['Evening review']);
    await expect(search).toBeVisible();
    await search.click();
    await expect(search).toHaveValue('EVENING');
    await expect(retry).toHaveCount(0);
    await expect.poll(() => requests.slice(initial)).toEqual([receipt, receipt, receipt]);
    expect(jobRead).toBe(4);
    expect(requests.filter(request => request.method !== 'GET')).toEqual([]);
    expect(errors).toEqual([]);
    await testInfo.attach('schedule-search-receipt.json', {
      body: JSON.stringify({ target: 'compiled Chromium deterministic fixture only', width, ownerProfile: 'default', initialJobReads, localSearchRequests: 0, mutationRequests: 0, explicitOutcomes: ['success', 'failure', 'retry success'], refreshRequests: requests.slice(initial), finalDisplayedJobs: ['Evening review'], pageErrors: errors }),
      contentType: 'application/json',
    });
  });
}
