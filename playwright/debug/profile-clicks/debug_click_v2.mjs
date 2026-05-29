// Debug: check profile contact click in test context
import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

// Simulate the test setup
await page.goto('http://127.0.0.1:8767/', { waitUntil: 'load', timeout: 20000 });
await page.waitForTimeout(4000);
await page.evaluate(() => {
  document.querySelector('flt-semantics-placeholder')?.dispatchEvent(new MouseEvent('click', { bubbles: true }));
});
await page.waitForTimeout(3000);

console.log('=== Search for buttons with text ===');

// Check ALL buttons
const allButtons = await page.evaluate(() => {
  const btns = document.querySelectorAll('flt-semantics[role="button"]');
  return Array.from(btns).map(b => ({
    text: (b.textContent || '').trim().substring(0, 80),
    rect: b.getBoundingClientRect(),
  }));
});

console.log('All buttons:', allButtons.length);
for (const b of allButtons) {
  if (b.rect.width > 0 && b.rect.height > 0) {
    console.log(`  text="${b.text}" rect=${Math.round(b.rect.x)},${Math.round(b.rect.y)} ${Math.round(b.rect.width)}x${Math.round(b.rect.height)}`);
  }
}

// Check if "Support Triage" is in any button text
console.log('\n=== Checking Support Triage ===');
const supportFound = allButtons.filter(b => b.text.includes('Support Triage'));
console.log('Buttons with "Support Triage":', supportFound.length);
for (const b of supportFound) {
  console.log(`  "${b.text}" at ${b.rect.x},${b.rect.y}`);
}

// Try clicking first
if (supportFound.length > 0) {
  const btn = supportFound[0];
  console.log(`\nClicking at center: ${btn.rect.x + btn.rect.width/2}, ${btn.rect.y + btn.rect.height/2}`);
  
  // Use page.mouse.click at coordinates
  await page.mouse.click(btn.rect.x + btn.rect.width/2, btn.rect.y + btn.rect.height/2);
  await page.waitForTimeout(3000);
  console.log('URL after mouse click:', page.url());
}

// Go back
await page.goto('http://127.0.0.1:8767/', { waitUntil: 'load', timeout: 20000 });
await page.waitForTimeout(4000);
await page.evaluate(() => {
  document.querySelector('flt-semantics-placeholder')?.dispatchEvent(new MouseEvent('click', { bubbles: true }));
});
await page.waitForTimeout(3000);

// Use evaluate dispatch
console.log('\n=== Using evaluate dispatch ===');
const clicked = await page.evaluate(() => {
  const btns = document.querySelectorAll('flt-semantics[role="button"]');
  for (const b of btns) {
    if ((b.textContent || '').includes('Support Triage')) {
      b.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, cancelable: true }));
      b.dispatchEvent(new PointerEvent('pointerup', { bubbles: true, cancelable: true }));
      b.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
      return true;
    }
  }
  return false;
});
console.log('Clicked:', clicked);
await page.waitForTimeout(3000);
console.log('URL after dispatch:', page.url());

await browser.close();