import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor, inventoryReceipts, scopedInventory } from '../../support/inventory_keyboard.mjs';

const skillsName = 'Search installed skills';
const toolsetsName = 'Search toolsets and resolved tools';
const defaultTools = 'Default Tools default Enabled · Configured · 1 resolved tool';
const webTools = 'Web Tools web Disabled · Configured · 1 resolved tool';
const skillsFixture = { object: 'list', data: [
  { name: 'github', description: 'GitHub workflow skill', category: 'github' },
  { name: 'ascii-art', description: 'ASCII art generation', category: 'creative' },
] };
const toolsetsFixture = { object: 'list', platform: 'api_server', data: [
  { name: 'default', label: 'Default Tools', enabled: true, configured: true, tools: ['read_file'] },
  { name: 'web', label: 'Web Tools', enabled: false, configured: true, tools: ['web_search'] },
] };
const jobs = [
  { id: 'job_morning', name: 'Morning check', enabled: true, state: 'active', schedule_display: 'Every day at 09:00' },
  { id: 'job_evening', name: 'Evening review', enabled: false, state: 'paused', schedule_display: '0 18 * * *' },
  { id: 'job_failure', name: 'Failed task', enabled: false, state: 'error', schedule_display: 'Every Monday' },
];
const cardText = job => `${job.name} ${job.state === 'active' ? 'Active' : job.state === 'paused' ? 'Paused' : 'Error'} Job ID ${job.id} Schedule ${job.schedule_display}`;
const receipt = (path, query = { profile: 'default' }) => ({ method: 'GET', path, query, profile: 'default' });

async function bootstrap(page, width, route) {
  await page.setViewportSize({ width, height: 900 });
  await page.goto(`${APP}#/${route}`);
  await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
  await enableFlutterAccessibility(page, { delay: 500 });
  await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
}

for (const width of [390, 1280]) {
  test(`Tools keyboard-only editors/independent clear/disclosure/refresh at ${width}px`, async ({ page }, testInfo) => {
    const trace = [];
    const io = inventoryReceipts(page, ['/v1/skills', '/v1/toolsets']);
    const actor = keyboardActor(page, testInfo, trace);
    const shellRole = width === 390 ? 'tab' : 'button';
    const shellName = width === 390 ? 'Chat' : 'Chat';
    try {
      await scopedInventory(page, ['skills', 'toolsets']);
      // Deterministic scoped API responses, not actions on application state.
      for (const [path, body] of [['/v1/skills', skillsFixture], ['/v1/toolsets', toolsetsFixture]]) {
        await page.route(url => url.pathname === path, route => route.fulfill({ status: 200, json: body }));
      }
      await bootstrap(page, width, 'tools');
      await expect(actor.control('textbox', skillsName)).toBeVisible();
      await io.settle();
      expect(io.readbacks).toHaveLength(2);
      expect(io.readbacks.find(r => r.path === '/v1/skills').body).toEqual(skillsFixture);
      expect(io.readbacks.find(r => r.path === '/v1/toolsets').body).toEqual(toolsetsFixture);
      expect(io.requests.filter(r => ['/v1/skills', '/v1/toolsets'].includes(r.path)).sort((a,b) => a.path.localeCompare(b.path)))
        .toEqual([receipt('/v1/skills'), receipt('/v1/toolsets')]);
      const initial = io.requests.length;
      const skillsGroup = page.getByRole('group', { name: 'Installed skills', exact: true });
      await actor.reach('textbox', skillsName);
      await actor.visibleFocus('textbox', skillsName, 'skills-editor');
      await actor.type(skillsName, 'CREATIVE');
      await expect(skillsGroup).toContainText('ascii-art');
      await expect(skillsGroup).not.toContainText('GitHub workflow skill');
      await actor.reach('textbox', toolsetsName);
      await actor.visibleFocus('textbox', toolsetsName, 'toolsets-editor');
      await actor.type(toolsetsName, 'WEB_SEARCH');
      await expect(actor.control('button', webTools)).toBeVisible();
      await expect(actor.control('button', defaultTools)).toHaveCount(0);
      await actor.reach('button', 'Clear installed skills search', 'Shift+Tab');
      await actor.visibleFocus('button', 'Clear installed skills search', 'skills-clear');
      await actor.press('Enter');
      await expect(actor.control('button', 'Clear installed skills search')).toHaveCount(0);
      await expect(skillsGroup).toContainText('GitHub workflow skill');
      await actor.reach('textbox', toolsetsName);
      await expect(actor.control('textbox', toolsetsName)).toHaveValue('WEB_SEARCH');
      await actor.reach('textbox', skillsName, 'Shift+Tab');
      await actor.type(skillsName, '.*');
      await expect(page.getByText('No installed skills match this search.', { exact: true })).toBeVisible();
      await actor.reach('button', 'Clear toolsets search');
      await actor.visibleFocus('button', 'Clear toolsets search', 'toolsets-clear');
      await actor.press('Space');
      await actor.reach('textbox', toolsetsName, 'Shift+Tab');
      await actor.type(toolsetsName, '.*');
      await expect(page.getByText('No toolsets match this search.', { exact: true })).toBeVisible();
      await actor.reach('button', 'Clear installed skills search', 'Shift+Tab');
      await actor.press('Enter');
      await actor.reach('textbox', toolsetsName);
      await expect(actor.control('textbox', toolsetsName)).toHaveValue('.*');
      await actor.reach('button', 'Clear toolsets search');
      await actor.press('Enter');
      await actor.reach('button', defaultTools);
      await actor.visibleFocus('button', defaultTools, 'default-disclosure');
      await actor.press('Enter');
      const readFile = actor.control('checkbox', 'read_file');
      await expect(readFile).toBeVisible();
      // RawChip exports a checkbox role on web even for a display-only Chip.
      // It must remain non-tappable and outside keyboard mutation navigation.
      expect(await readFile.evaluate(node => ({ tabIndex: node.tabIndex, tappable: node.hasAttribute('flt-tappable') })))
        .toEqual({ tabIndex: -1, tappable: false });
      await testInfo.attach('expanded-tools-semantics.json', { contentType:'application/json', body:JSON.stringify({ snapshot:await page.locator('body').ariaSnapshot(), html:await page.locator('flt-semantics').filter({has:readFile}).last().evaluate(node=>node.outerHTML) }) });
      // Flutter exposes the expanded tile as a tappable group containing the
      // read-only chip, rather than its collapsed button role. Record that truth.
      await expect(actor.control('group', `${defaultTools} Resolved tools`)).toHaveAttribute('aria-description', 'Expanded');
      await actor.press('Tab');
      await actor.assertFocus('button', webTools); // Read-only tool is not a mutation destination.
      await actor.press('Shift+Tab');
      await actor.assertFocus('group', `${defaultTools} Resolved tools`);
      await actor.press('Space');
      await expect(readFile).toHaveCount(0);
      await expect(actor.control('button', defaultTools)).toHaveAttribute('aria-description', 'Collapsed');
      await actor.press('Tab');
      await actor.assertFocus('button', webTools);
      await actor.visibleFocus('button', webTools, 'web-disclosure');
      await actor.press('Space');
      await expect(actor.control('checkbox', 'web_search')).toBeVisible();
      expect(await actor.control('checkbox', 'web_search').evaluate(node => ({ tabIndex: node.tabIndex, tappable: node.hasAttribute('flt-tappable') })))
        .toEqual({ tabIndex: -1, tappable: false });
      await expect(actor.control('group', `${webTools} Resolved tools`)).toHaveAttribute('aria-description', 'Expanded');
      await actor.reach(shellRole, shellName);
      await actor.reach('group', `${webTools} Resolved tools`, 'Shift+Tab');
      await actor.press('Enter');
      await expect(actor.control('checkbox', 'web_search')).toHaveCount(0);
      await actor.reach(shellRole, shellName);
      await actor.reach('button', webTools, 'Shift+Tab');
      await actor.reach('textbox', skillsName, 'Shift+Tab');
      await actor.type(skillsName, 'GITHUB');
      await actor.reach('textbox', toolsetsName);
      await actor.type(toolsetsName, 'WEB_SEARCH');
      expect(io.requests.slice(initial)).toEqual([]);
      await actor.reach('button', 'Refresh inventory', 'Shift+Tab');
      await actor.visibleFocus('button', 'Refresh inventory', 'tools-refresh');
      await actor.press('Enter');
      await expect.poll(() => io.requests.slice(initial).sort((a,b) => a.path.localeCompare(b.path)))
        .toEqual([receipt('/v1/skills'), receipt('/v1/toolsets')]);
      await expect(actor.control('button', 'Refresh inventory')).toBeEnabled();
      await actor.reach('textbox', skillsName);
      await expect(actor.control('textbox', skillsName)).toHaveValue('GITHUB');
      await actor.reach('textbox', toolsetsName);
      await expect(actor.control('textbox', toolsetsName)).toHaveValue('WEB_SEARCH');
      await expect(skillsGroup).toContainText('GitHub workflow skill');
      await expect(actor.control('button', webTools)).toBeVisible();
      await io.settle();
      expect(io.readbacks).toHaveLength(4);
      for (const r of io.readbacks) {
        expect(r.status).toBe(200);
        expect(r.query).toEqual({profile:'default'});
        expect(r.body).toEqual(r.path === '/v1/skills' ? skillsFixture : toolsetsFixture);
      }
      expect(io.requests.filter(r => r.method !== 'GET')).toEqual([]);
      expect(io.errors).toEqual([]);
      await testInfo.attach('tools-keyboard-receipt.json', { contentType:'application/json', body:JSON.stringify({ target:'compiled Chromium deterministic fixture only', width, reducedMotion:true, initialInventoryReads:2, localControlReads:0, mutationRequests:0, bootstrapRequests:io.requests.slice(0,initial), explicitRefreshReads:io.requests.slice(initial), responseReadbacks:io.readbacks, trace, pageErrors:io.errors }) });
    } finally {
      await testInfo.attach('tools-keyboard-trace.json', { contentType:'application/json', body:JSON.stringify({trace, requests:io.requests, readbacks:io.readbacks, errors:io.errors}) });
    }
  });

  test(`Schedules keyboard-only search/filter/clear/refresh/failure/Retry at ${width}px`, async ({ page }, testInfo) => {
    const trace = [];
    const io = inventoryReceipts(page, ['/api/jobs']);
    const actor = keyboardActor(page, testInfo, trace);
    const shellRole = width === 390 ? 'tab' : 'button';
    const shellName = width === 390 ? 'Chat' : 'Chat';
    let jobRead = 0;
    const result = async names => {
      for (const job of jobs) {
        const card = page.getByText(cardText(job), {exact:true});
        if (names.includes(job.name)) await expect(card).toBeVisible();
        else await expect(card).toHaveCount(0);
      }
    };
    try {
      await scopedInventory(page, ['jobs']);
      await page.route(url => url.pathname === '/api/jobs', route => {
        jobRead++;
        return route.fulfill({ status: jobRead === 3 ? 503 : 200,
          json: jobRead === 3 ? {error:'synthetic private transport details'} : {jobs} });
      });
      await bootstrap(page, width, 'tasks');
      await expect(actor.control('textbox', 'Search schedules')).toBeVisible();
      await result(jobs.map(j => j.name));
      await io.settle();
      const jobsReceipt = receipt('/api/jobs', {profile:'default',include_disabled:'true'});
      expect(io.requests.filter(r => r.path === '/api/jobs')).toEqual([jobsReceipt]);
      expect(io.readbacks).toHaveLength(1);
      expect(io.readbacks[0].body).toEqual({jobs});
      const initial = io.requests.length;
      await actor.reach('textbox', 'Search schedules');
      await actor.visibleFocus('textbox', 'Search schedules', 'schedule-editor');
      await actor.type('Search schedules', '.*');
      await result([]);
      const noMatches = page.locator('flt-semantics').getByText('No matching schedules Try another name, job ID or schedule, or clear the filters.', {exact:true});
      await expect(noMatches).toBeVisible();
      await expect(page.getByText('No schedules yet',{exact:true})).toHaveCount(0);
      await actor.reach('button', 'Clear filters');
      await actor.visibleFocus('button', 'Clear filters', 'schedule-clear', 'Shift+Tab');
      await actor.press('Enter');
      await actor.assertFocus('button', 'Clear filters');
      await result(jobs.map(j => j.name));
      await actor.reach(shellRole, shellName);
      await actor.reach('button', 'Clear filters', 'Shift+Tab');
      await actor.reach('checkbox', 'Enabled', 'Shift+Tab');
      await actor.visibleFocus('checkbox', 'Enabled', 'enabled-filter');
      await actor.press('Space');
      await expect(actor.control('checkbox', 'Enabled')).toBeChecked();
      await result(['Morning check']);
      await actor.press('Tab');
      await actor.assertFocus('checkbox', 'Disabled');
      await actor.visibleFocus('checkbox', 'Disabled', 'disabled-filter');
      await actor.press('Enter');
      await expect(actor.control('checkbox', 'Disabled')).toBeChecked();
      await result(['Evening review','Failed task']);
      await actor.reach('checkbox', 'All', 'Shift+Tab');
      await actor.visibleFocus('checkbox', 'All', 'all-filter');
      await actor.press('Space');
      await expect(actor.control('checkbox', 'All')).toBeChecked();
      await result(jobs.map(j => j.name));
      await actor.press('Shift+Tab');
      await actor.assertFocus('textbox', 'Search schedules');
      await expect(actor.control('textbox', 'Search schedules')).toHaveValue('');
      await actor.type('Search schedules', 'JOB_MORNING');
      await result(['Morning check']);
      await actor.reach('checkbox', 'Disabled');
      await actor.press('Space');
      await result([]);
      await expect(noMatches).toBeVisible();
      expect(io.requests.slice(initial)).toEqual([]);
      await actor.reach('button', 'Clear filters');
      await actor.press('Space');
      await actor.assertFocus('button', 'Clear filters');
      await actor.press('Enter'); // Idempotent clear remains keyboard-operable.
      await actor.reach('checkbox', 'Disabled', 'Shift+Tab');
      await actor.press('Space');
      await actor.reach('textbox', 'Search schedules', 'Shift+Tab');
      await actor.type('Search schedules', 'EVENING');
      await result(['Evening review']);
      expect(io.requests.slice(initial)).toEqual([]);
      await actor.reach('button', 'Refresh schedules', 'Shift+Tab');
      await actor.visibleFocus('button', 'Refresh schedules', 'schedule-refresh');
      await actor.press('Enter');
      await expect.poll(() => io.requests.slice(initial)).toEqual([jobsReceipt]);
      await expect(actor.control('button', 'Refresh schedules')).toBeEnabled();
      await result(['Evening review']);
      await actor.reach('textbox', 'Search schedules');
      await expect(actor.control('textbox', 'Search schedules')).toHaveValue('EVENING');
      await expect(actor.control('checkbox', 'Disabled')).toBeChecked();
      await actor.reach('button', 'Refresh schedules', 'Shift+Tab');
      await actor.press('Space');
      await expect(actor.control('button', 'Retry')).toBeVisible();
      await expect(page.getByRole('group', {
        name: 'Schedules unavailable Schedules could not be loaded from Hermes.', exact: true,
      })).toBeVisible();
      await result([]);
      await expect(actor.control('textbox', 'Search schedules')).toHaveCount(0);
      await expect(noMatches).toHaveCount(0);
      await expect(page.getByText('synthetic private transport details', {exact:false})).toHaveCount(0);
      await expect.poll(() => io.requests.slice(initial)).toEqual([jobsReceipt,jobsReceipt]);
      await actor.reach('button', 'Retry');
      await actor.visibleFocus('button', 'Retry', 'schedule-retry', 'Shift+Tab');
      await actor.reach(shellRole, shellName);
      await actor.reach('button', 'Retry', 'Shift+Tab');
      await actor.press('Enter');
      await result(['Evening review']);
      await expect(actor.control('button', 'Retry')).toHaveCount(0);
      await actor.reach('textbox', 'Search schedules');
      await expect(actor.control('textbox', 'Search schedules')).toHaveValue('EVENING');
      await expect(actor.control('checkbox', 'Disabled')).toBeChecked();
      await expect.poll(() => io.requests.slice(initial)).toEqual([jobsReceipt,jobsReceipt,jobsReceipt]);
      await io.settle();
      expect(jobRead).toBe(4);
      expect(io.readbacks.map(r => r.status)).toEqual([200,200,503,200]);
      expect(io.readbacks.map(r => r.body)).toEqual([{jobs},{jobs},{error:'synthetic private transport details'},{jobs}]);
      for (const r of io.readbacks) expect(r.query).toEqual(jobsReceipt.query);
      expect(io.requests.filter(r => r.method !== 'GET')).toEqual([]);
      expect(io.errors).toEqual([]);
      await testInfo.attach('schedule-keyboard-receipt.json', { contentType:'application/json', body:JSON.stringify({ target:'compiled Chromium deterministic fixture only', width, reducedMotion:true, initialJobReads:1, localControlReads:0, mutationRequests:0, bootstrapRequests:io.requests.slice(0,initial), explicitRefreshReads:io.requests.slice(initial), responseReadbacks:io.readbacks, finalFilter:'Disabled', finalQuery:'EVENING', finalDisplayedJobs:['Evening review'], trace, pageErrors:io.errors }) });
    } finally {
      await testInfo.attach('schedule-keyboard-trace.json', { contentType:'application/json', body:JSON.stringify({trace, requests:io.requests, readbacks:io.readbacks, errors:io.errors}) });
    }
  });
}
