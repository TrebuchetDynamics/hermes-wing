import { test, expect } from '@playwright/test';
import { APP_URL, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

async function fill(page, name, value) {
  await page.getByRole('textbox', { name, exact: true }).click();
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.type(value);
  await expect(page.locator('input:focus, textarea:focus')).toHaveValue(value);
}

for (const width of [390, 1280]) {
  test(`access request is safe and preserves draft at ${width}`, async ({ page, context }) => {
    await context.grantPermissions(['clipboard-read', 'clipboard-write']);
    await page.setViewportSize({ width, height: 1000 });
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => {
      if (/RenderFlex|overflowed|EXCEPTION CAUGHT/.test(message.text())) errors.push(message.text());
    });
    const apiCalls = [];
    page.on('request', request => {
      if (/\/v1\/(chat|sessions|runs|capabilities)|\/api\/auth/.test(request.url())) apiCalls.push(request.url());
    });
    await page.goto(`${APP_URL}#/hermes/add?mode=remote&welcome=1`);
    await page.waitForFunction(() => typeof globalThis.wingE2EHermesConnect === 'function', null, { timeout: 30000 });
    await enableFlutterAccessibility(page);
    const fields = page.getByRole('textbox');
    await expect(fields.first()).toBeVisible();
    await fill(page, 'Hermes Agent URL', 'https://synthetic.example.invalid/p/exact');
    await fill(page, 'Access token', 'synthetic-not-for-clipboard');
    const before = apiCalls.length;
    const help = page.getByRole('button', { name: 'I need access to Hermes', exact: true });
    await help.scrollIntoViewIfNeeded();
    await help.click();
    await expect(page.getByText('Already chatting with Hermes on your computer?', { exact: false })).toBeVisible();
    await page.getByRole('button', { name: 'Copy request for Hermes', exact: true }).click();
    await expect(page.getByLabel('Alert').getByText('Request copied. Paste it in your existing Hermes chat. No connection values or secrets were included.', { exact: true })).toBeVisible();
    const copied = await page.evaluate(() => navigator.clipboard.readText());
    expect(copied).toContain('API_SERVER_KEY');
    expect(copied).toContain('Do not rotate existing credentials');
    expect(copied).not.toContain('synthetic.example.invalid');
    expect(copied).not.toContain('synthetic-not-for-clipboard');
    await page.screenshot({ path: test.info().outputPath(`connection-access-${width}.png`) });
    await page.getByRole('button', { name: 'Close', exact: true }).click();
    await page.getByRole('textbox', { name: 'Hermes Agent URL', exact: true }).click();
    await expect(page.locator('input:focus, textarea:focus')).toHaveValue('https://synthetic.example.invalid/p/exact');
    await page.getByRole('textbox', { name: 'Access token', exact: true }).click();
    await expect(page.locator('input:focus, textarea:focus')).toHaveValue('synthetic-not-for-clipboard');
    expect(apiCalls.length).toBe(before);
    expect(errors).toEqual([]);
  });
}
