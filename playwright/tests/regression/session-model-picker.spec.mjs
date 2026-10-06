import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

for (const width of [390, 1280]) {
  test(`session picker search/filter/rejected confirmation/retry at ${width}px`, async ({ page, request }, testInfo) => {
    const dialog = page.getByLabel('Dialog', { exact: true });
    await page.setViewportSize({ width, height: 900 });
    const seeded = await request.post(`${APP}e2e/hermes/model-picker`);
    expect(await seeded.json()).toEqual({ synthetic: true, selectable: 303 });
    await page.goto(`${APP}#/hermes`);
    await enableFlutterAccessibility(page, { delay: 500 });
    await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
    await page.getByRole('checkbox', { name: 'Hermes model', exact: true }).click();
    await expect(page.getByText('Use a model for this session', { exact: true })).toBeVisible();
    const search = page.getByRole('textbox', { name: 'Search models or providers' });
    await search.click();
    // Wait for Flutter's native editing bridge before the first keystrokes.
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    await page.keyboard.type('ALPHA/MODEL-99');
    await expect(dialog.getByText('1 matching model', { exact: true })).toBeVisible();
    await expect(dialog.getByText('Selected: Display beta (beta) — shared', { exact: true })).toBeVisible();
    await page.getByRole('button', { name: /All selectable providers/ }).click();
    await page.getByRole('menuitem', { name: 'Display gamma', exact: true }).click();
    await expect(dialog.getByText('No matching models', { exact: true })).toBeVisible();
    await page.getByRole('button', { name: 'Clear model search' }).click();
    await expect(dialog.getByText('101 matching models', { exact: true })).toBeVisible();
    await page.getByRole('button', { name: 'Reset filters' }).click();
    await expect(dialog.getByText('303 matching models', { exact: true })).toBeVisible();
    await search.click();
    await search.fill('Forbidden');
    await expect(dialog.getByText('No matching models', { exact: true })).toBeVisible();
    await search.fill('ALPHA/MODEL-99');
    await page.getByRole('button', { name: 'alpha/model-99 Display alpha (alpha)', exact: true }).click();
    await expect(dialog.getByText('Selected: Display alpha (alpha) — alpha/model-99', { exact: true })).toBeVisible();
    const use = page.getByRole('button', { name: 'Use for session', exact: true });
    await use.click();
    await expect(dialog.getByText('Hermes could not confirm this session model.', { exact: true })).toBeVisible();
    await expect(search).toHaveValue('ALPHA/MODEL-99');
    let receipt = await (await request.get(`${APP}e2e/hermes/model-picker`)).json();
    expect(receipt.selected).toBeNull();
    expect(receipt.locks).toEqual([{ provider: 'alpha', model: 'alpha/model-99' }]);
    await use.click();
    await expect(page.getByText('Use a model for this session', { exact: true })).not.toBeVisible();
    await expect(page.getByRole('checkbox', { name: 'alpha/model-99', exact: true })).toBeVisible();
    receipt = await (await request.get(`${APP}e2e/hermes/model-picker`)).json();
    expect(receipt.selected).toEqual({ provider: 'alpha', model: 'alpha/model-99', model_lock: 'accepted', route_source: 'session' });
    expect(receipt.locks).toHaveLength(2);
    await page.getByRole('checkbox', { name: 'alpha/model-99', exact: true }).click();
    await expect(dialog.getByText('Selected: Display alpha (alpha) — alpha/model-99', { exact: true })).toBeVisible();
    await expect(search).toHaveValue('');
    await expect(dialog.getByRole('button', { name: /Display (alpha|beta|gamma) \((alpha|beta|gamma)\)/ }).first()).toHaveText('alpha/model-99 Display alpha (alpha)');
    await use.click();
    await expect(page.getByText('Use a model for this session', { exact: true })).not.toBeVisible();
    receipt = await (await request.get(`${APP}e2e/hermes/model-picker`)).json();
    expect(receipt.selected).toEqual({ provider: 'alpha', model: 'alpha/model-99', model_lock: 'accepted', route_source: 'session' });
    expect(receipt.locks).toEqual(Array(3).fill({ provider: 'alpha', model: 'alpha/model-99' }));
    // Escape is cancellation, not another session mutation.
    await page.getByRole('checkbox', { name: 'alpha/model-99', exact: true }).click();
    await search.focus();
    await page.keyboard.press('Escape');
    await expect(page.getByText('Use a model for this session', { exact: true })).not.toBeVisible();
    expect((await (await request.get(`${APP}e2e/hermes/model-picker`)).json()).locks).toHaveLength(3);
    await testInfo.attach('session-picker-receipt.json', { body: JSON.stringify({ platform: 'deterministic Chromium only; no inference qualification', width, ...receipt }), contentType: 'application/json' });
  });
}
