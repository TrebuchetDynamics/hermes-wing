// Debug: examine popup menu semantics more carefully
import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

await page.goto('http://127.0.0.1:8767/', { waitUntil: 'load', timeout: 20000 });
await page.waitForTimeout(4000);
await page.evaluate(() => {
  document.querySelector('flt-semantics-placeholder')?.dispatchEvent(new MouseEvent('click', { bubbles: true }));
});
await page.waitForTimeout(3000);

// Check all visible elements before opening menu
console.log('=== Before menu ===');
const before = await page.evaluate(() => {
  const all = document.querySelectorAll('*');
  const results = [];
  for (const el of all) {
    const rect = el.getBoundingClientRect();
    const role = el.getAttribute('role') || '';
    const aria = el.getAttribute('aria-label') || '';
    if (rect.width > 0 && rect.height > 0 && el.children.length === 0 && (role || aria) && el.textContent?.trim()) {
      results.push({ tag: el.tagName, role, aria, text: el.textContent.trim().substring(0, 50) });
    }
    if (results.length > 50) break;
  }
  return results;
});
console.log('Interactive elements before menu:');
for (const b of before) console.log(`  <${b.tag}> role="${b.role}" aria="${b.aria}" text="${b.text}"`);

// Open menu
await page.evaluate(() => {
  const btns = document.querySelectorAll('flt-semantics[role="button"]');
  for (const b of btns) {
    if ((b.textContent || '').includes('Open profile list menu')) {
      b.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
      b.dispatchEvent(new PointerEvent('pointerup', { bubbles: true }));
      b.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      break;
    }
  }
});
await page.waitForTimeout(2000);

// Check ALL elements that appeared after menu
console.log('\n=== After menu - new/visible elements ===');
const after = await page.evaluate(() => {
  const all = document.querySelectorAll('*');
  const results = [];
  for (const el of all) {
    const tag = el.tagName.toLowerCase();
    const rect = el.getBoundingClientRect();
    const role = el.getAttribute('role') || '';
    const aria = el.getAttribute('aria-label') || '';
    const text = (el.textContent || '').trim().substring(0, 60);
    const style = el.getAttribute('style') || '';
    
    if (rect.width > 0 && rect.height > 0 && !['flt-semantics-placeholder', 'script', 'style', 'flt-announcement-polite', 'flt-announcement-assertive'].includes(tag)) {
      results.push({ tag, role, aria, text, rect: `${Math.round(rect.x)},${Math.round(rect.y)} ${Math.round(rect.width)}x${Math.round(rect.height)}` });
    }
    if (results.length > 60) break;
  }
  return results;
});
console.log('All visible elements:');
for (const a of after) console.log(`  <${a.tag}> role="${a.role}" aria="${a.aria}" text="${a.text}" rect=${a.rect}`);

// Try clicking on Manage gateways differently - use mouse coords at the menu position
const managePos = after.find(a => a.text.includes('Manage'));
if (managePos) {
  console.log('\nManage gateways position:', managePos.rect);
} else {
  // Menu might be a modal bottom sheet - check for overlay
  const overlays = await page.evaluate(() => {
    const ovs = document.querySelectorAll('[class*="overlay"], [class*="modal"], [class*="sheet"], [class*="menu"], [class*="dropdown"]');
    return Array.from(ovs).map(o => ({
      tag: o.tagName,
      cls: o.className?.substring(0, 60),
      rect: o.getBoundingClientRect(),
    }));
  });
  console.log('\nOverlays:', JSON.stringify(overlays));
}

await browser.close();