// Debug: find the chat textbox element
import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

await page.goto('http://127.0.0.1:8767/', { waitUntil: 'load', timeout: 20000 });
await page.waitForTimeout(4000);
await page.evaluate(() => {
  document.querySelector('flt-semantics-placeholder')?.dispatchEvent(new MouseEvent('click', { bubbles: true }));
});
await page.waitForTimeout(3000);

// Navigate to chat
await page.evaluate(() => {
  const btns = document.querySelectorAll('flt-semantics[role="button"]');
  for (const b of btns) {
    if ((b.textContent || '').includes('Support Triage')) {
      b.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
      b.dispatchEvent(new PointerEvent('pointerup', { bubbles: true }));
      b.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      break;
    }
  }
});
await page.waitForTimeout(3000);

// Find ALL elements with roles
const allRoles = await page.evaluate(() => {
  const all = document.querySelectorAll('*');
  const roles = new Set();
  for (const el of all) {
    const r = el.getAttribute('role');
    if (r) roles.add(r);
  }
  return Array.from(roles);
});
console.log('All roles:', allRoles);

// Find elements with textbox role
const textboxes = await page.evaluate(() => {
  const tbs = document.querySelectorAll('[role="textbox"], [role="textbox"] *, input, textarea, [contenteditable]');
  const results = [];
  for (const tb of tbs) {
    const rect = tb.getBoundingClientRect();
    const ariaLabel = tb.getAttribute('aria-label') || '';
    const text = (tb.textContent || '').trim().substring(0, 40);
    results.push({ tag: tb.tagName, ariaLabel, text, rect: `${Math.round(rect.x)},${Math.round(rect.y)} ${Math.round(rect.width)}x${Math.round(rect.height)}`, visible: rect.width > 0 && rect.height > 0 });
  }
  return results;
});
console.log('\nTextboxes found:');
for (const tb of textboxes) {
  if (tb.visible) console.log(`  <${tb.tag}> label="${tb.ariaLabel}" text="${tb.text}" rect=${tb.rect}`);
}

// Find elements with contenteditable (Flutter uses them for text input)
const editable = await page.evaluate(() => {
  const eds = document.querySelectorAll('[contenteditable="true"], [contenteditable=""]');
  return Array.from(eds).map(e => ({
    tag: e.tagName,
    label: e.getAttribute('aria-label'),
    text: (e.textContent || '').trim().substring(0, 40),
    rect: e.getBoundingClientRect(),
  }));
});
console.log('\nContenteditable:', JSON.stringify(editable));

// Full search for "Message Gormes" text
const msgGormes = await page.evaluate(() => {
  const all = document.querySelectorAll('*');
  for (const el of all) {
    const label = el.getAttribute('aria-label') || '';
    if (label.includes('Message Gormes')) {
      return { tag: el.tagName, label, role: el.getAttribute('role'), rect: el.getBoundingClientRect(), outer: el.outerHTML?.substring(0, 200) };
    }
  }
  return null;
});
console.log('\nMessage Gormes element:', JSON.stringify(msgGormes, null, 2));

await browser.close();