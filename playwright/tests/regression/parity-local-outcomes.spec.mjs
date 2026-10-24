import { test, expect } from '@playwright/test';
import { APP_URL, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

async function open(page, route) {
  await page.goto(`${APP_URL}#${route}`);
  await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function', null, { timeout: 30000 });
  await enableFlutterAccessibility(page);
}

async function focusFlutterField(page, field) {
  await field.click();
  // Flutter attaches its editing client after accessibility focus.
  await page.waitForTimeout(100);
}

async function fillFlutterField(page, field, value) {
  await focusFlutterField(page, field);
  await field.fill(value);
}

for (const width of [390, 1280]) {
  test(`Chat text direction routes, persists and resets at ${width}px`, async ({ page }) => {
    await page.setViewportSize({ width, height: 1000 });
    const errors = [];
    const mutations = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => {
      if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(message.text())) errors.push(message.text());
    });
    page.on('request', request => {
      if (!['GET', 'HEAD', 'OPTIONS'].includes(request.method())) mutations.push(request.method());
    });
    await open(page, '/settings?tab=config:appearance&page=theme&setting=appearance.text-direction');
    const rtl = page.getByRole('checkbox', { name: 'Right to left', exact: true });
    const ltr = page.getByRole('checkbox', { name: 'Left to right', exact: true });
    const auto = page.getByRole('checkbox', { name: 'Auto', exact: true });
    const thinking = page.getByRole('switch', { name: /Collapse thinking by default/ })
      .or(page.getByRole('checkbox', { name: /Collapse thinking by default/ }));
    await expect(thinking).not.toBeChecked();
    await thinking.click();
    await expect(thinking).toBeChecked();
    await expect(auto).toBeChecked();
    await rtl.click();
    await expect(rtl).toBeChecked();
    await page.reload();
    await enableFlutterAccessibility(page);
    await expect(rtl).toBeChecked();
    await expect(thinking).toBeChecked();
    await thinking.click();
    await ltr.click();
    await expect(ltr).toBeChecked();
    await auto.click();
    await page.reload();
    await enableFlutterAccessibility(page);
    await expect(auto).toBeChecked();
    await expect(thinking).not.toBeChecked();
    await page.getByRole('button', { name: 'Search settings', exact: true }).click();
    await page.getByRole('searchbox', { name: 'Search settings', exact: true }).fill('Text direction');
    await page.getByRole('button', { name: /Text direction/ }).click();
    await expect(page).toHaveURL(/page=chat-display/);
    await expect(page).toHaveURL(/setting=appearance.text-direction/);
    await expect(auto).toBeChecked();
    await page.screenshot({ path: test.info().outputPath(`chat-text-direction-${width}.png`) });
    expect(mutations).toEqual([]);
    expect(errors).toEqual([]);
  });
}

for (const width of [390, 1440]) {
  test(`Schedules selects bounded details and retains filtered Back at ${width}px`, async ({ page }) => {
    await page.setViewportSize({ width, height: 1100 });
    const mutations = [];
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => {
      if (/overflowed|RenderFlex|EXCEPTION CAUGHT/.test(message.text())) errors.push(message.text());
    });
    page.on('request', request => {
      if (!['GET', 'HEAD', 'OPTIONS'].includes(request.method())) mutations.push(request.method());
    });
    await page.route(/\/api\/jobs(?:\?.*)?$/, async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        headers: { 'access-control-allow-origin': new URL(APP_URL).origin },
        body: JSON.stringify({ jobs: [
          { id: 'zebra', name: 'Zebra review', enabled: true, schedule_display: 'Daily at 10:00' },
          { id: 'alpha', name: 'Alpha report', enabled: true, schedule_display: 'Weekly on Friday' },
        ] }),
      });
    });
    await open(page, '/tasks');
    await page.evaluate(() => globalThis.wingE2EHermesConnect());
    const alpha = page.getByRole('button', { name: /^Alpha report/ });
    const zebra = page.getByRole('button', { name: /^Zebra review/ });
    await expect(alpha).toBeVisible();
    await expect(zebra).toBeVisible();
    expect((await alpha.boundingBox()).y).toBeLessThan((await zebra.boundingBox()).y);
    const search = page.getByRole('textbox', { name: 'Search schedules', exact: true });
    await fillFlutterField(page, search, 'Zebra');
    await expect(search).toHaveValue('Zebra');
    await expect(alpha).toHaveCount(0);
    await zebra.press('Enter');
    await expect(page.getByText('Zebra review Enabled Job ID zebra Schedule Daily at 10:00', { exact: true })).toBeVisible();
    if (width < 820) {
      await page.getByRole('button', { name: 'Back', exact: true }).last().press('Enter');
      await focusFlutterField(page, search);
      await expect(search).toHaveValue('Zebra');
      await expect(zebra).toBeVisible();
    }
    await fillFlutterField(page, search, '');
    await alpha.click();
    await expect(page.getByText('Alpha report Enabled Job ID alpha Schedule Weekly on Friday', { exact: true })).toBeVisible();
    await page.screenshot({ path: test.info().outputPath(`schedules-master-detail-${width}.png`) });
    expect(mutations).toEqual([]);
    expect(errors).toEqual([]);
  });
}

test('Skills category facets combine with literal search and survive refresh', async ({ page }) => {
  const mutations = [];
  await open(page, '/tools');
  page.on('request', request => {
    if (!['GET', 'HEAD', 'OPTIONS'].includes(request.method())) mutations.push(request.method());
  });
  await page.evaluate(() => globalThis.wingE2EHermesConnect());
  const skills = page.getByRole('group', { name: 'Installed skills', exact: true });
  const creative = page.getByRole('checkbox', { name: 'creative', exact: true });
  const github = page.getByRole('checkbox', { name: 'github', exact: true });
  await creative.click();
  await expect(skills).toContainText('ascii-art');
  await expect(skills).not.toContainText('GitHub workflow skill');
  await github.click();
  await expect(skills).toContainText('GitHub workflow skill');
  await fillFlutterField(page, page.getByRole('textbox', { name: 'Search installed skills', exact: true }), 'github');
  await expect(skills).not.toContainText('ascii-art');
  await expect(skills).toContainText('GitHub workflow skill');
  await page.getByRole('button', { name: 'Refresh inventory', exact: true }).click();
  await expect(creative).toBeChecked();
  await expect(github).toBeChecked();
  await focusFlutterField(page, page.getByRole('textbox', { name: 'Search installed skills', exact: true }));
  await expect(page.getByRole('textbox', { name: 'Search installed skills', exact: true })).toHaveValue('github');
  await page.screenshot({ path: test.info().outputPath('skills-category-facets.png') });
  expect(mutations).toEqual([]);
});

test('Sidebar pins persist across reload without mutating Agent sessions', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1100 });
  await open(page, '/hermes');
  await page.evaluate(() => globalThis.wingE2EHermesConnect());
  await expect.poll(() => page.evaluate(() => JSON.parse(globalThis.wingE2EHermesStateSummary()).status)).toBe('connected');
  const mutations = [];
  page.on('request', request => {
    if (!['GET', 'HEAD', 'OPTIONS'].includes(request.method())) mutations.push(request.method());
  });
  const shell = page.getByRole('group', { name: 'Loaded sessions', exact: true });
  await expect(shell.getByRole('button', { name: 'Open E2E Hermes Session', exact: true })).toHaveCount(1);
  await expect(shell.getByRole('button', { name: 'Pin', exact: true })).toHaveCount(1);
  await shell.getByRole('button', { name: 'Pin', exact: true }).click();
  await expect(shell.getByText('Pinned', { exact: true })).toBeVisible();
  await expect(shell.getByRole('button', { name: 'Open E2E Hermes Session', exact: true })).toHaveCount(1);
  await page.reload();
  await enableFlutterAccessibility(page);
  await page.evaluate(() => globalThis.wingE2EHermesConnect());
  await expect(shell.getByRole('button', { name: 'Unpin', exact: true })).toHaveCount(1);
  await shell.getByRole('button', { name: 'Unpin', exact: true }).press('Enter');
  await expect(shell.getByText('Pinned', { exact: true })).toHaveCount(0);
  await expect(shell.getByRole('button', { name: 'Open E2E Hermes Session', exact: true })).toHaveCount(1);
  await page.screenshot({ path: test.info().outputPath('sidebar-pins.png') });
  expect(mutations).toEqual([]);
});
