import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

// Delays/errors are per-test deterministic reads, never live Agent/provider calls.
for (const width of [390, 1280]) {
  for (const mode of ['success', 'failure', 'unsupported']) {
    test(`Connections health ${mode}, explicit pending retry is single-read at ${width}px`, async ({ page }, testInfo) => {
      const requests = [];
      const healthReceipts = [];
      const responseReads = [];
      const errors = [];
      let healthCalls = 0;
      let release;

      page.on('pageerror', error => errors.push(error.message));
      page.on('request', request => {
        const url = new URL(request.url());
        if (url.pathname.startsWith('/api/') || url.pathname.startsWith('/v1/') || url.pathname.startsWith('/health')) {
          requests.push({ method: request.method(), path: url.pathname, profile: url.searchParams.get('profile') });
        }
      });
      page.on('response', response => {
        if (new URL(response.url()).pathname === '/health/detailed') {
          responseReads.push(response.json().then(body => healthReceipts.push({ status: response.status(), body })));
        }
      });
      await page.route(url => url.pathname === '/v1/capabilities', async route => {
        const response = await route.fetch();
        const base = await response.json();
        const endpoints = { ...base.endpoints };
        if (mode === 'unsupported') delete endpoints.health_detailed;
        await route.fulfill({ response, json: { ...base, endpoints } });
      });
      await page.route(url => url.pathname === '/health/detailed', async route => {
        const call = ++healthCalls;
        const ok = call === 1 ? mode === 'success' : await new Promise(resolve => { release = resolve; });
        const status = ok ? 200 : 503;
        const body = ok ? {
          status: 'ok', platform: 'hermes-agent', version: call === 1 ? 'fixture-initial' : 'fixture-refreshed',
          gateway_state: 'running', active_agents: call,
        } : { error: { message: 'synthetic private health metadata' } };

        await route.fulfill({ status, json: body });
      });
      await page.setViewportSize({ width, height: 1400 });
      await page.goto(`${APP}#/gateway`);
      await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function');
      await enableFlutterAccessibility(page, { delay: 500 });
      await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
      const refresh = page.getByRole('button', { name: 'Refresh gateway status', exact: true });
      const retry = page.getByRole('button', { name: 'Retry', exact: true });
      const fallback = page.getByRole('group', { name: 'Connected. Basic health is available, but detailed status could not be loaded.', exact: true });
      const owner = () => page.evaluate(() => {
        const state = JSON.parse(globalThis.wingE2EHermesStateSummary());
        return { profile: state.selected_profile_id, session: state.active_session_id,
          status: state.status, provider: state.assigned_provider, model: state.assigned_model };
      });
      if (mode === 'unsupported') {
        await expect(page.getByText('Connected. Showing basic health because this gateway does not advertise detailed status.', { exact: true })).toBeVisible();
        await expect(refresh).toHaveCount(0);
        await expect(retry).toHaveCount(0);
        expect(healthCalls).toBe(0);
      } else if (mode === 'failure') {
        await expect(fallback).toBeVisible();
        await expect(retry).toBeEnabled();
      } else {
        await expect(page.getByText(/fixture-initial/)).toBeVisible();
        await expect(refresh).toBeEnabled();
        await expect(retry).toHaveCount(0);
      }
      const before = await owner();
      const initial = requests.length;
      if (mode !== 'unsupported') {
        const action = mode === 'failure' ? retry : refresh;
        await action.click();
        await expect.poll(() => healthCalls).toBe(2);
        await expect(refresh).toBeDisabled();
        if (mode === 'failure') await expect(retry).toBeDisabled();
        // Target the disabled health controls, not another focusable action.
        await refresh.dispatchEvent('click');
        if (mode === 'failure') await retry.dispatchEvent('click');
        expect(healthCalls).toBe(2);
        release(false);
        await expect(fallback).toBeVisible();
        await expect(retry).toBeEnabled();
        await expect(refresh).toBeEnabled();
        await expect(page.getByText(/synthetic private/)).toHaveCount(0);
        // Use actual traversal, not DOM focus: Flutter's focus tree owns keys.
        for (let index = 0; index < 12; index++) {
          await page.keyboard.press('Tab');
          await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
          if (await retry.evaluate(node => document.activeElement === node)) break;
        }
        await expect(retry).toBeFocused();
        await page.keyboard.press('Enter');
        await expect.poll(() => healthCalls).toBe(3);
        await expect(refresh).toBeDisabled();
        await expect(retry).toBeDisabled();
        await retry.dispatchEvent('click');
        await refresh.dispatchEvent('click');
        expect(healthCalls).toBe(3);
        release(true);
        await expect(page.getByText(/fixture-refreshed/)).toBeVisible();
        await expect(refresh).toBeEnabled();
        await expect(retry).toHaveCount(0);
        expect(requests.slice(initial)).toEqual([
          { method: 'GET', path: '/health/detailed', profile: null },
          { method: 'GET', path: '/health/detailed', profile: null },
        ]);
      } else {
        expect(requests.slice(initial)).toEqual([]);
      }
      const after = await owner();
      expect(after).toEqual(before);
      expect(requests.some(request => request.method !== 'GET')).toBe(false);
      expect(errors).toEqual([]);
      await Promise.all(responseReads);
      expect(healthReceipts.length).toBe(mode === 'unsupported' ? 0 : 3);
      if (mode !== 'unsupported') {
        expect(healthReceipts.map(receipt => receipt.status)).toEqual([mode === 'success' ? 200 : 503, 503, 200]);
        expect(healthReceipts[2].body.version).toBe('fixture-refreshed');
      }
      await testInfo.attach('connections-health-receipt.json', { body: JSON.stringify({
        target: 'fresh compiled Flutter Chromium deterministic fixture only', width, mode,
        reducedMotion: true, requests, healthResponseReadbacks: healthReceipts,
        explicitActionReads: requests.slice(initial), beforeOwner: before, afterOwner: after,
        healthCalls, pageErrors: errors,
      }), contentType: 'application/json' });
    });
  }
}
