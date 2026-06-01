import assert from 'node:assert/strict';
import test from 'node:test';

import { waitForProbeReady } from './page_readiness.mjs';

test('waitForProbeReady preserves the probe readiness sequence', async () => {
  const calls = [];
  const page = {
    async waitForTimeout(delayMs) {
      calls.push(['waitForTimeout', delayMs]);
    },
    async evaluate(fn) {
      calls.push(['evaluate', typeof fn]);
    },
  };

  await waitForProbeReady(page, { delayMs: 1500 });

  assert.deepEqual(calls, [
    ['waitForTimeout', 1500],
    ['evaluate', 'function'],
    ['waitForTimeout', 2000],
  ]);
});
