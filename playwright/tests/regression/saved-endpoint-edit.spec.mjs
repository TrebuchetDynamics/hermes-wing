import { test, expect, chromium } from '@playwright/test';
import { mkdir, writeFile, rm } from 'node:fs/promises';
import path from 'node:path';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';
import { keyboardActor } from '../../support/inventory_keyboard.mjs';
import { managementRoute, observeMatrixPage, recordMatrixBoundary, verifyMatrixNegativeControl } from '../../support/connection_production_matrix_fixture.mjs';

test.describe.configure({ retries: 0 });
for (const width of [390, 1280]) for (const zoom of [1, 2]) {
  test(`saved endpoint keyboard edit/test ${width}px zoom ${zoom}`, async ({ request }, info) => {
    test.setTimeout(120000);
    const profile = info.outputPath('profile');
    await mkdir(path.join(profile, 'Default'), { recursive: true });
    await writeFile(path.join(profile, 'Default', 'Preferences'), JSON.stringify({partition:{default_zoom_level:{x:Math.log(zoom)/Math.log(1.2)}}}));
    const context = await chromium.launchPersistentContext(profile, { executablePath: process.env.CHROME_EXECUTABLE, headless: true, viewport: {width:width*zoom,height:1100*zoom}, reducedMotion:'reduce', args:['--no-sandbox','--disable-setuid-sandbox'] });
    const page = context.pages()[0]; const trace = [], requests = [], errors = [];
    const matrixObserved = info.project.name === 'connection-production-matrix' ? await observeMatrixPage(page) : null;
    const actor = keyboardActor(page, info, trace);
    const state = () => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()));
    const store = action => page.evaluate(action => JSON.parse(globalThis.wingE2EEndpointSaveControl(action)), action);
    const button = name => page.getByRole('button',{name,exact:true});
    async function activate(name) {
      const target = button(name);
      await expect(target).toHaveCount(1);
      for (let i = 0; i < 160; i++) {
        if (await target.evaluate(node => {
          let active = document.activeElement;
          while (active?.shadowRoot?.activeElement) active = active.shadowRoot.activeElement;
          return node === active || node.contains(active);
        })) break;
        await actor.press('Tab');
      }
      await actor.assertFocus('button',name);
      await actor.press('Enter');
    }
    async function fill(name, value) {
      // Flutter appends the hint to a focused native editor's accessible name.
      // Password inputs also have no implicit textbox role in Chromium.
      const field = page.getByLabel(new RegExp(`^${name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}(?:\\n|$)`));
      await expect(field).toHaveCount(1);
      let focused = false;
      for (let i = 0; i < 40; i++) {
        focused = await field.evaluate(node => {
          let active = document.activeElement;
          while (active?.shadowRoot?.activeElement) active = active.shadowRoot.activeElement;
          return node === active || node.contains(active);
        });
        if (focused) break;
        await actor.press('Tab');
      }
      expect(focused, `keyboard focus on ${name}`).toBe(true);
      await page.keyboard.press('ControlOrMeta+A'); await page.keyboard.type(value);
      await expect(field).toHaveValue(value);
    }
    page.on('pageerror',e => errors.push(e.message));
    page.on('console',m => { if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(m.text())) errors.push(m.text()); });
    page.on('request',r => { const u = new URL(r.url()); if (/^\/(api|v1|p)\//.test(u.pathname)) requests.push({method:r.method(),path:u.pathname}); });
    try {
      expect((await request.post(`${APP}e2e/hermes/session-restoration`)).ok()).toBe(true);
      await page.goto(`${APP}#/hermes/add`);
      await page.waitForFunction(() => typeof globalThis.wingE2EReduceMotion === 'function');
      await enableFlutterAccessibility(page,{delay:0});
      await page.evaluate(() => globalThis.wingE2EReduceMotion());
      const metrics = await page.evaluate(() => ({width:innerWidth,dpr:devicePixelRatio,reduced:matchMedia('(prefers-reduced-motion: reduce)').matches}));
      expect(metrics.width).toBe(width); expect(metrics.dpr).toBe(zoom); expect(metrics.reduced).toBe(true);
      await fill('Hermes Agent URL',new URL(APP).origin);
      await fill('Connection name (optional)','Synthetic saved host');
      await activate('Add Hermes');
      await expect(page.getByLabel(/Synthetic saved host.*online/)).toBeVisible();
      // Fixture-only owner bootstrap; every saved-edit action below is a key.
      await page.evaluate(() => globalThis.wingE2EHermesConnect());
      await expect.poll(async () => (await state()).active_session_id).not.toBeNull();
      await page.evaluate(() => { location.hash = '#/hermes'; });
      await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
      await page.evaluate(() => { location.hash = '#/hermes/add'; });
      await expect(button('Edit saved Agent connection')).toBeVisible();
      const owner = await state(); const initial = await store('read');
      const draft = `${new URL(APP).origin}/p/shared`;
      await activate('Edit saved Agent connection');
      await fill('Hermes Agent URL',draft);
      await fill('Replacement Agent credential','synthetic-credential');
      await expect(page.getByLabel(/^Replacement Agent credential(?:\n|$)/)).toHaveAttribute('type','password');
      let status = 401, parked;
      await page.route('**/p/shared/v1/capabilities', async route => {
        if (parked) await parked;
        await route.fulfill({status,json:status === 200 ? {object:'hermes.api_server.capabilities',platform:'hermes-agent',schema_version:1} : {error:'synthetic denial'}});
      });
      await activate('Test connection');
      await expect(page.getByRole('alertdialog').locator('span').filter({hasText:/Agent discovery denied this credential/})).toBeVisible();
      expect(await store('read')).toEqual(initial); expect(await state()).toEqual(owner);
      status = 200;
      await activate('Test connection');
      await expect(page.getByRole('alertdialog').locator('span').filter({hasText:/Supported Agent discovery responded/})).toBeVisible();
      expect(await store('read')).toEqual(initial); expect(await state()).toEqual(owner);
      // Cancel a parked read, then let its success settle: no late announcement.
      let release; parked = new Promise(resolve => { release = resolve; });
      await activate('Test connection');
      await activate('Cancel test'); release(); parked = null;
      await expect(page.getByRole('alertdialog').locator('span').filter({hasText:/Test cancelled/})).toBeVisible();
      await page.screenshot({path:info.outputPath(`cancelled-${width}-${zoom}.png`),animations:'disabled'});
      await activate('Cancel'); expect(await store('read')).toEqual(initial);
      await activate('Edit saved Agent connection');
      await fill('Hermes Agent URL',draft);
      await fill('Replacement Agent credential','synthetic-credential');
      await store('fail-next');
      await activate('Save');
      await expect(page.getByRole('alertdialog').locator('span').filter({hasText:/Could not save this connection/})).toBeVisible();
      await expect(page.getByRole('textbox',{name:'Hermes Agent URL',exact:true})).toHaveValue(draft);
      expect((await store('read')).completed).toBe(initial.completed);
      await page.screenshot({path:info.outputPath(`retry-${width}-${zoom}.png`),animations:'disabled'});
      await activate('Save');
      await expect(page.getByRole('alertdialog')).toHaveCount(0);
      const saved = await store('read');
      expect(saved.completed).toBe(initial.completed+1); expect(saved.attempts).toBe(initial.attempts+2);
      expect(await state()).toEqual(owner);
      await activate('Edit saved Agent connection');
      await expect(page.getByRole('textbox',{name:'Hermes Agent URL',exact:true})).toHaveValue(draft);
      await expect(page.getByLabel(/^Replacement Agent credential(?:\n|$)/)).toHaveValue('');
      await actor.reach('button','Test connection');
      if (zoom === 1) await actor.visibleFocus('button','Test connection',`test-focus-${width}`);
      await page.screenshot({path:info.outputPath(`saved-${width}-${zoom}.png`),animations:'disabled'});
      await activate('Cancel');
      expect(requests.filter(r => r.method !== 'GET')).toEqual([]);
      expect(requests.filter(r => managementRoute.test(r.path) || /wing-link|\/v1\/runs/.test(r.path))).toEqual([]);
      expect(errors).toEqual([]);
      await writeFile(info.outputPath('receipt.json'),JSON.stringify({platform:'fresh compiled Flutter Chromium',backend:'deterministic loopback fixture; synthetic intercepted direct discovery',metrics,initial,saved,requests,errors,trace:trace.filter(t => !t.action?.startsWith('type')),native:'NOT_CHECKED',inference:'NOT_CHECKED'},null,2));
    } finally {
      try {
        if (matrixObserved) {
          await recordMatrixBoundary(page, matrixObserved, info);
          // Deliberately injected only after recording the clean real journey.
          await verifyMatrixNegativeControl(page, matrixObserved, info);
        }
      }
      finally { await context.close(); await rm(profile,{recursive:true,force:true}); }
    }
  });
}
