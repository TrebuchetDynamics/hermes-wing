import { expect } from '@playwright/test';
import { writeFile, readFile, readdir } from 'node:fs/promises';
import { throws, deepEqual, equal } from 'node:assert/strict';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const managementRoute = /^\/v1\/(devices|pairing|hosts|profiles)(?:\/|$)/;

export async function observeMatrixPage(page) {
  const observed = { agentMutations: [], management: [], errors: [] };
  page.on('pageerror', e => observed.errors.push(e.message));
  page.on('request', request => {
    const path = new URL(request.url()).pathname;
    if (/^\/(api|p|v1)\//.test(path) && request.method() !== 'GET') observed.agentMutations.push(`${request.method()} ${path}`);
    if (managementRoute.test(path)) observed.management.push(`${request.method()} ${path}`);
  });
  await page.route(/\/v1\/(devices|pairing|hosts|profiles)(?:\/|\?|$)/,
    route => route.fulfill({ status: 403, json: { error: 'synthetic management denial' } }));
  return observed;
}

export function assertNoMatrixTraffic(observed) {
  expect(observed.agentMutations).toEqual([]);
  expect(observed.management).toEqual([]);
  expect(observed.errors).toEqual([]);
}

export async function verifyMatrixNegativeControl(page, observed, info) {
  assertNoMatrixTraffic(observed);
  const status = await page.evaluate(async () => (await fetch('/v1/hosts')).status);
  expect(status).toBe(403);
  expect(observed.management).toEqual(['GET /v1/hosts']);
  throws(() => assertNoMatrixTraffic(observed), /GET \/v1\/hosts/);
  await writeFile(info.outputPath('matrix-negative-control.json'), JSON.stringify({
    task: 'CONNECTION-PRODUCTION-BROWSER-MATRIX', goal: 'CONNECTION-PATHS',
    title: info.title, status, observed, rejected: true,
  }, null, 2));
}

export async function recordMatrixBoundary(page, observed, info) {
  // Missing control/receipt is a failure, never a silently omitted matrix case.
  const state = await control(page);
  await writeFile(info.outputPath('matrix-boundary.json'), JSON.stringify({
    task: 'CONNECTION-PRODUCTION-BROWSER-MATRIX', goal: 'CONNECTION-PATHS',
    title: info.title, observed, state,
    native: 'NOT_CHECKED', liveAuthentication: 'NOT_CHECKED', physicalSecureStore: 'NOT_CHECKED', delivered: 'NOT_CHECKED',
  }, null, 2));
  assertNoMatrixTraffic(observed);
  if (!info.title.startsWith('production optional')) expect([state.inspect, state.setup, state.cancel]).toEqual([0, 0, 0]);
}

export async function aggregateMatrixReceipts(resultsPath) {
  const results = JSON.parse(await readFile(resultsPath, 'utf8'));
  const specs = [];
  function visit(suite) {
    specs.push(...(suite.specs ?? []));
    for (const child of suite.suites ?? []) visit(child);
  }
  for (const suite of results.suites) visit(suite);
  equal(specs.length, 15, 'complete matrix case count');
  for (const spec of specs) {
    equal(spec.ok, true, spec.title);
    for (const test of spec.tests) {
      equal(test.status, 'expected', spec.title);
      equal(test.results.length, 1, 'no retries');
      equal(test.results[0].status, 'passed', spec.title);
    }
  }
  const root = path.dirname(resultsPath);
  const boundaries = [], negatives = [];
  for (const entry of await readdir(root, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    for (const name of await readdir(path.join(root, entry.name))) {
      if (!['matrix-boundary.json', 'matrix-negative-control.json'].includes(name)) continue;
      const receipt = JSON.parse(await readFile(path.join(root, entry.name, name), 'utf8'));
      (name === 'matrix-boundary.json' ? boundaries : negatives).push(receipt);
    }
  }
  const sorted = receipts => receipts.map(r => r.title).sort();
  deepEqual(sorted(boundaries), specs.filter(s => !s.title.startsWith('matrix detects')).map(s => s.title).sort(), 'every real journey has a boundary receipt');
  deepEqual(sorted(negatives), specs.filter(s => /^(saved endpoint keyboard|matrix detects)/.test(s.title)).map(s => s.title).sort(), 'every persistent page has a negative control');
  for (const receipt of boundaries) {
    assertNoMatrixTraffic(receipt.observed);
    if (!receipt.title.startsWith('production optional')) deepEqual([receipt.state.inspect, receipt.state.setup, receipt.state.cancel], [0, 0, 0]);
  }
  for (const receipt of negatives) {
    equal(receipt.status, 403);
    equal(receipt.rejected, true);
    deepEqual(receipt.observed.management, ['GET /v1/hosts']);
  }
  const summary = { task: 'CONNECTION-PRODUCTION-BROWSER-MATRIX', goal: 'CONNECTION-PATHS', cases: specs.length, boundaries: boundaries.length, negativeControls: negatives.length, titles: sorted(boundaries) };
  await writeFile(path.join(root, 'matrix-aggregate.json'), JSON.stringify(summary, null, 2));
  return summary;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  console.log(JSON.stringify(await aggregateMatrixReceipts(process.argv[2]), null, 2));
}

export const control = (page, action = 'read') => page.evaluate(
  action => JSON.parse(globalThis.wingConnectionMatrixControl(action)), action);

export async function counts(page, inspect, setup, cancel) {
  await expect.poll(async () => {
    const state = await control(page);
    return [state.inspect, state.setup, state.cancel];
  }).toEqual([inspect, setup, cancel]);
}

export async function activate(page, name) {
  const button = page.getByRole('button', { name, exact: true });
  await expect(button).toHaveCount(1);
  for (let i = 0; i < 100; i++) {
    if (await button.evaluate(node => {
      let active = document.activeElement;
      while (active?.shadowRoot?.activeElement) active = active.shadowRoot.activeElement;
      return active === node || node.contains(active);
    })) {
      await page.keyboard.press('Enter');
      await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
      return;
    }
    await page.keyboard.press('Tab');
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(resolve)));
  }
  throw new Error(`Keyboard did not reach ${name}`);
}

export async function fill(page, name, value) {
  const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const field = page.getByLabel(new RegExp(`^${escaped}(?:\\n|$)`));
  await expect(field).toHaveCount(1);
  let focused = false;
  for (let i = 0; i < 100; i++) {
    focused = await field.evaluate(node => {
      let active = document.activeElement;
      while (active?.shadowRoot?.activeElement) active = active.shadowRoot.activeElement;
      return node === active || node.contains(active);
    });
    if (focused) break;
    await page.keyboard.press('Tab');
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(resolve)));
  }
  expect(focused, `keyboard focus on ${name}`).toBe(true);
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.type(value);
  await expect(page.locator('input:focus, textarea:focus')).toHaveValue(value);
}
