import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

// Per-test advertised-contract fixture matching Wing's existing client/channel
// tests. Not the upstream dashboard's unscoped content/exists contract, and not
// production registration/authentication or a claim about an installed Agent.
for (const width of [390, 1280]) {
  for (const mode of ['save', 'read-failure', 'write-failure', 'conflict']) {
    test(`Persona ${mode} explicit revision save and readback at ${width}px`, async ({ page }, testInfo) => {
      const initial = '\n\n\t  Inert fixture persona.\n  Indented line. \t\n\n';
      const newer = '\n\t  Inert newer server persona. café 東京. \n\n';
      let persisted = { soul: initial, revision: 'persona-r1' };
      const requests = [], reads = [], writes = [], errors = [];
      let failed = false;
      page.on('pageerror', error => errors.push(error.message));
      page.on('request', request => {
        const url = new URL(request.url());
        if (/^\/(api|v1)\//.test(url.pathname)) requests.push({
          method: request.method(), path: url.pathname, profile: url.searchParams.get('profile'),
        });
      });
      await page.route(url => url.pathname === '/v1/capabilities', async route => {
        const response = await route.fetch(); const base = await response.json();
        await route.fulfill({ response, json: { ...base,
          profile_context: { type: 'query', name: 'profile', required: true, default_profile_id: 'default' },
          auth: { ...base.auth, granted_scopes: [...base.auth.granted_scopes, 'profiles:read', 'profiles:write'] },
          endpoints: { ...base.endpoints,
            profiles: { method: 'GET', path: '/api/profiles', required_scopes: ['profiles:read'] },
            profile_soul: { method: 'GET', path: '/api/profiles/{name}/soul', required_scopes: ['profiles:read'] },
            profile_soul_update: { method: 'PUT', path: '/api/profiles/{name}/soul', required_scopes: ['profiles:write'] },
          },
        } });
      });
      await page.route(url => url.pathname === '/api/profiles', route => route.fulfill({ status: 200, json: {
        data: [{ id: 'default', name: 'Fixture profile', revision: 'profile-r1' }],
      } }));
      await page.route(url => url.pathname === '/api/profiles/default/soul', async route => {
        const request = route.request(); const url = new URL(request.url());
        expect(url.searchParams.get('profile')).toBe('default');
        if (request.method() === 'GET') {
          const fail = mode === 'read-failure' && !failed;
          if (fail) failed = true;
          const body = fail ? { error: 'synthetic private failure' } : { ...persisted };
          reads.push({ status: fail ? 503 : 200, body });
          return route.fulfill({ status: fail ? 503 : 200, json: body });
        }
        expect(request.method()).toBe('PUT');
        const body = request.postDataJSON(); const revision = request.headers()['if-match'];
        expect(Object.keys(body)).toEqual(['soul']);
        expect(revision).toBe(persisted.revision);
        let status = 200;
        if (!failed && mode === 'write-failure') { failed = true; status = 503; }
        else if (!failed && mode === 'conflict') {
          failed = true; status = 412;
          persisted = { soul: newer, revision: 'persona-r2' };
        } else persisted = { soul: body.soul, revision: mode === 'conflict' ? 'persona-r3' : 'persona-r2' };
        writes.push({ revision, body, status, bodyUtf8: [...Buffer.from(request.postData(), 'utf8')] });
        return route.fulfill({ status, json: status === 200 ? persisted : { error: 'synthetic private failure' } });
      });
      await page.setViewportSize({ width, height: 1000 });
      await page.goto(`${APP}#/soul`);
      await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
      await enableFlutterAccessibility(page, { delay: 500 });
      await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
      await expect(page.getByRole('group', { name: 'Choose a profile Select a profile before opening its persona editor.', exact: true })).toBeVisible();
      await page.evaluate(() => globalThis.wingE2EHermesLoadDefaultProfileInventory());
      const field = page.getByRole('textbox', { name: 'Persona', exact: true });
      const save = page.getByRole('button', { name: 'Save', exact: true });
      if (mode === 'read-failure') {
        await expect(save).toBeDisabled();
        await expect(page.locator('flt-semantics').getByText('Hermes could not complete that profile change.', { exact: true })).toBeVisible();
        const retry = page.getByRole('button', { name: 'Retry', exact: true });
        await retry.click();
      }
      await field.click();
      await expect(field).toHaveValue(initial);
      expect(writes).toEqual([]);
      const draft = '\n\t  Inert explicit fixture draft.\n  Unicode: café 東京 🪽 e\u0301. \t\n\n';
      const edit = async text => {
        await field.click();
        await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
        await page.keyboard.press('ControlOrMeta+A'); await page.keyboard.type(text);
        await expect(field).toHaveValue(text);
      };
      await edit(draft); expect(writes).toEqual([]);
      await save.click();
      if (mode === 'conflict') {
        await field.click();
        await expect(field).toHaveValue(newer);
        await expect(page.locator('flt-semantics').getByText(/This profile changed elsewhere/)).toBeVisible();
        expect(writes).toHaveLength(1); await edit(draft); await save.click();
      } else if (mode === 'write-failure') {
        await expect(page.locator('flt-semantics').getByText('Hermes could not complete that profile change.', { exact: true })).toBeVisible();
        await field.click();
        await expect(field).toHaveValue(draft); expect(writes).toHaveLength(1);
        await save.click();
      }
      await expect.poll(() => writes.filter(write => write.status === 200).length).toBe(1);
      const readback = await page.evaluate(async () => {
        const response = await fetch('/api/profiles/default/soul?profile=default');
        const bytes = [...new Uint8Array(await response.arrayBuffer())];
        return { status: response.status, body: JSON.parse(new TextDecoder().decode(new Uint8Array(bytes))), bytes };
      });
      const expectedSaved = {
        soul: draft, revision: mode === 'conflict' ? 'persona-r3' : 'persona-r2',
      };
      expect(readback).toEqual({ status: 200, body: expectedSaved,
        bytes: [...Buffer.from(JSON.stringify(expectedSaved), 'utf8')],
      });
      expect([...Buffer.from(readback.body.soul, 'utf8')]).toEqual([...Buffer.from(draft, 'utf8')]);
      for (const write of writes) {
        expect(write.body).toEqual({ soul: draft });
        expect(write.bodyUtf8).toEqual([...Buffer.from(JSON.stringify({ soul: draft }), 'utf8')]);
      }
      // Dispose the editor through real routing, then load from Agent again.
      const readCount = reads.length, writeCount = writes.length;
      await page.evaluate(() => { location.hash = '/settings'; });
      await expect(field).toHaveCount(0);
      await page.evaluate(() => { location.hash = '/soul'; });
      await field.click();
      await expect(field).toHaveValue(draft);
      expect(reads).toHaveLength(readCount + 1);
      expect(reads.at(-1).body).toEqual(expectedSaved);
      expect(writes).toHaveLength(writeCount);
      expect(writes.map(write => write.revision)).toEqual(mode === 'conflict' ?
        ['persona-r1', 'persona-r2'] : mode === 'write-failure' ? ['persona-r1', 'persona-r1'] : ['persona-r1']);
      expect(requests.filter(r => r.method !== 'GET')).toEqual(writes.map(() => ({
        method: 'PUT', path: '/api/profiles/default/soul', profile: 'default',
      })));
      expect(errors).toEqual([]);
      await expect(page.getByText(/synthetic private failure/)).toHaveCount(0);
      await testInfo.attach('persona-receipt.json', { body: JSON.stringify({
        target: 'fresh compiled Flutter Chromium advertised-contract fixture only',
        width, mode, reducedMotion: true, initial, newer, draft, requests, reads, writes, readback,
        editorReload: { document: draft, revision: reads.at(-1).body.revision, writes: writeCount },
        lineEndings: 'LF browser documents; CRLF, whitespace-only and empty tested through production client/widgets',
        pageErrors: errors,
        ownerTransitions: 'widget-covered; browser fixture does not replace owner',
      }), contentType: 'application/json' });
    });
  }
}
