import { test, expect } from '@playwright/test';
import { writeFile } from 'node:fs/promises';
import { enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

async function frame(page) {
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
}
async function key(page, name, activate = true) {
  const button = page.getByRole('button', { name, exact: true });
  await expect(button).toHaveCount(1);
  for (let i = 0; i < 40; i++) {
    if (await button.evaluate(el => el === document.activeElement || el.contains(document.activeElement))) {
      if (activate) await page.keyboard.press('Enter');
      await frame(page);
      return;
    }
    await page.keyboard.press('Tab');
    await frame(page);
  }
  throw new Error(`Tab did not reach ${name}`);
}
async function counts(page, inspect, setup, cancel) {
  await expect(page.getByText(`Fixture calls: inspect=${inspect} setup=${setup} cancel=${cancel}`, { exact: true })).toBeVisible();
}
async function capture(page, info, name) {
  const path = info.outputPath(`${name}.png`);
  await page.screenshot({ path, fullPage: false });
  await info.attach(name, { path, contentType: 'image/png' });
}

for (const width of [390, 1280]) {
  for (const installed of [false, true]) {
    test(`${width}px 2x text ${installed ? 'existing' : 'missing'} consent Stop failure retry and route fence`, async ({ page }, info) => {
      const errors = [];
      const mutations = [];
      page.on('pageerror', e => errors.push(e.message));
      page.on('request', r => { if (r.method() !== 'GET') mutations.push(r.method()); });
      await page.setViewportSize({ width, height: 1100 });
      await page.goto('/');
      await enableFlutterAccessibility(page, { delay: 0 });
      if (installed) await key(page, 'Fixture ready');
      await key(page, 'Optional Local setup');
      const action = installed ? 'Adopt this installation' : 'Install Hermes Agent here';
      await expect(page.getByRole('group', { name: new RegExp(installed ? '^Hermes Agent is ready' : '^Hermes Agent is not installed') })).toBeVisible();
      await counts(page, 1, 0, 0);
      await key(page, action);
      await expect(page.getByText('Allow local Hermes setup?', { exact: true })).toBeVisible();
      await capture(page, info, 'consent');
      await page.keyboard.press('Escape');
      await counts(page, 1, 0, 0);
      await key(page, action);
      await key(page, 'Cancel');
      await counts(page, 1, 0, 0);
      await key(page, action);
      await key(page, 'Run setup');
      await counts(page, 1, 1, 0);
      await expect(page.getByRole('progressbar', { name: /Starting the Hermes gateway.*96%/ })).toBeVisible();
      await key(page, 'Stop setup');
      await counts(page, 1, 1, 1);
      await key(page, 'Fixture success');
      await expect(page.getByRole('group', { name: /^Setup stopped/ })).toBeVisible();
      await counts(page, 1, 1, 1);
      await key(page, 'Check again', false);
      await capture(page, info, 'stopped');
      await key(page, 'Check again');
      await counts(page, 2, 1, 1);
      await key(page, 'Adopt this installation');
      await key(page, 'Run setup');
      await key(page, 'Fixture failure');
      await expect(page.getByRole('group', { name: /^Setup needs attention/ })).toBeVisible();
      expect(await page.locator('flt-semantics').evaluateAll(nodes => nodes.map(n => `${n.textContent} ${n.getAttribute('aria-label')}`).join(' '))).not.toContain('synthetic private output');
      await counts(page, 2, 2, 1);
      await key(page, 'Check again', false);
      await capture(page, info, 'failure');
      await key(page, 'Check again');
      await counts(page, 3, 2, 1);
      await key(page, 'Adopt this installation');
      await key(page, 'Run setup');
      await key(page, 'Fixture success');
      await expect(page.getByRole('group', { name: /^Hermes gateway is ready/ })).toBeVisible();
      await counts(page, 4, 3, 1);
      await expect(page.getByRole('group', { name: /Continue to pairing before managing Hermes capabilities/ })).toBeVisible();
      await key(page, 'Continue to pairing', false);
      await capture(page, info, 'verified');
      await key(page, 'Continue to pairing');
      await expect(page.getByText('Direct Agent entry remains independent', { exact: true })).toBeVisible();
      await key(page, 'Optional Local setup');
      await counts(page, 5, 3, 1);
      await key(page, 'Adopt this installation');
      await key(page, 'Run setup');
      await key(page, 'Leave setup');
      await counts(page, 5, 4, 2);
      await key(page, 'Fixture failure');
      await expect(page.getByText('Direct Agent entry remains independent', { exact: true })).toBeVisible();
      await counts(page, 5, 4, 2);
      await expect(page.getByRole('group', { name: /^Setup needs attention/ })).toHaveCount(0);
      // A second disposed operation completes successfully, without redirect.
      await key(page, 'Optional Local setup');
      await counts(page, 6, 4, 2);
      await key(page, 'Adopt this installation');
      await key(page, 'Run setup');
      await key(page, 'Leave setup');
      await counts(page, 6, 5, 3);
      await key(page, 'Fixture success');
      await counts(page, 6, 5, 3);
      await expect(page.getByText('Direct Agent entry remains independent', { exact: true })).toBeVisible();
      await expect(page.getByRole('group', { name: /^Hermes gateway is ready/ })).toHaveCount(0);
      expect(errors).toEqual([]);
      expect(mutations).toEqual([]);
      await writeFile(info.outputPath('receipt.json'), JSON.stringify({ width, textScale: 2, installed, keyboard: true, inspects: 6, setups: 5, cancels: 3, errors, networkMutations: mutations, backend: 'synthetic typed LocalWingLinkHost', nativeInstall: 'NOT_CHECKED' }, null, 2));
    });
  }
}
