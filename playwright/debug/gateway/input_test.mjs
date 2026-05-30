import { openDebugPage } from '../support/browser.mjs';
import { setNativeInputValue } from '../support/semantic_actions.mjs';

const { browser, page } = await openDebugPage({
  gotoOptions: { waitUntil: 'load', timeout: 30000 },
  settleMs: 5000,
  enableAccessibility: true,
  accessibilitySettleMs: 4000,
});

// Check what flt-semantics elements have text-fields with labels we need
const semanticsInfo = await page.evaluate(() => {
  const all = document.querySelectorAll('flt-semantics');
  return Array.from(all).map(s => ({
    label: s.getAttribute('aria-label'),
    role: s.getAttribute('role'),
    'data-role': s.getAttribute('data-semantics-role'),
    childInput: s.querySelector('input')?.getAttribute('aria-label'),
    rect: s.getBoundingClientRect(),
  })).filter(s => s.rect.width > 0);
});
console.log('flt-semantics elements:');
for (const s of semanticsInfo) {
  console.log(`  label="${s.label}" role="${s.role}" data-role="${s['data-role']}" child="${s.childInput}"`);
}

// Try clicking the flt-semantics that contains the address input
const addrSemantics = page.locator('flt-semantics').filter({ has: page.locator('input[aria-label="Gateway address field"]') });
console.log('Address semantics count:', await addrSemantics.count());
if (await addrSemantics.count() > 0) {
  await addrSemantics.first().click({ force: true });
  await page.waitForTimeout(1000);
  await page.keyboard.type('192.168.1.1');
  await page.waitForTimeout(1000);
}

// Check what the input value is
const val1 = await page.evaluate(() => {
  const input = document.querySelector('input[aria-label="Gateway address field"]');
  return input ? { value: input.value, disabled: input.disabled } : null;
});
console.log('After keyboard type:', JSON.stringify(val1));

// Try using evaluate to set value via Flutter's internal mechanism
await setNativeInputValue(page, 'input[aria-label="Gateway address field"]', '10.0.0.1');
await page.waitForTimeout(1000);

const val2 = await page.evaluate(() => {
  const input = document.querySelector('input[aria-label="Gateway address field"]');
  return input ? input.value : null;
});
console.log('After native value setter:', val2);

await browser.close();