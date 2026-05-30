// Debug: test different click methods on profile tiles
import { DEFAULT_APP_URL, enableFlutterAccessibility, openDebugPage } from '../support/browser.mjs';

const { browser, page } = await openDebugPage({
  gotoOptions: { waitUntil: 'load', timeout: 20000 },
  settleMs: 5000,
  enableAccessibility: true,
});

// Track console for errors
page.on('pageerror', err => console.log('PAGE ERROR:', err.message));

// Method 1: click via evaluate dispatching events
console.log('=== Method 1: Click via evaluate ===');
const result1 = await page.evaluate(() => {
  const buttons = document.querySelectorAll('flt-semantics[role="button"]');
  for (const btn of buttons) {
    if ((btn.textContent || '').includes('Support Triage')) {
      console.log('Found button:', btn.textContent?.substring(0, 50));
      const rect = btn.getBoundingClientRect();
      console.log('Rect:', rect.x, rect.y, rect.width, rect.height);
      // Try dispatching events
      btn.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
      btn.dispatchEvent(new PointerEvent('pointerup', { bubbles: true }));
      btn.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      return { method: 'evaluate', x: rect.x + rect.width/2, y: rect.y + rect.height/2 };
    }
  }
  return { method: 'not-found' };
});
console.log('Result1:', JSON.stringify(result1));
await page.waitForTimeout(3000);
console.log('URL:', page.url());

// Method 2: page.locator.click with force
console.log('\n=== Method 2: locator.click force ===');
await page.goto(DEFAULT_APP_URL, { waitUntil: 'load', timeout: 20000 });
await page.waitForTimeout(5000);
await enableFlutterAccessibility(page);

const locator = page.locator('flt-semantics[role="button"]').filter({ hasText: 'Support Triage' });
console.log('Locator count:', await locator.count());
if (await locator.count() > 0) {
  try {
    await locator.first().click({ force: true, timeout: 5000 });
    console.log('Click done');
    await page.waitForTimeout(3000);
    console.log('URL:', page.url());
  } catch (e) {
    console.log('Click error:', e.message.substring(0, 100));
  }
}

// Method 3: page.locator.dispatchEvent
console.log('\n=== Method 3: locator.dispatchEvent ===');
await page.goto(DEFAULT_APP_URL, { waitUntil: 'load', timeout: 20000 });
await page.waitForTimeout(5000);
await enableFlutterAccessibility(page);

const locator2 = page.locator('flt-semantics[role="button"]').filter({ hasText: 'Support Triage' });
if (await locator2.count() > 0) {
  await locator2.first().dispatchEvent('click');
  await page.waitForTimeout(3000);
  console.log('URL:', page.url());
}

await browser.close();