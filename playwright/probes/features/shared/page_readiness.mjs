import { enableFlutterAccessibility } from '../../support/probe_runtime.mjs';

export async function waitForProbeReady(page, { delayMs = 1500 } = {}) {
  await page.waitForTimeout(delayMs);
  await enableFlutterAccessibility(page);
}
