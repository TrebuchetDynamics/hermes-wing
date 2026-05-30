// Debug: check popup menu DOM and send button
import { openDebugPage } from '../support/browser.mjs';

const { browser, page } = await openDebugPage({
  gotoOptions: { waitUntil: 'load', timeout: 20000 },
  settleMs: 4000,
  enableAccessibility: true,
});

// Open menu
console.log('=== Opening menu ===');
await page.evaluate(() => {
  const btns = document.querySelectorAll('flt-semantics[role="button"]');
  for (const b of btns) {
    if ((b.textContent || '').includes('Open profile list menu')) {
      b.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
      b.dispatchEvent(new PointerEvent('pointerup', { bubbles: true }));
      b.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      console.log('Clicked menu button');
      break;
    }
  }
});
await page.waitForTimeout(2000);

// Check DOM for menu items
const menuInfo = await page.evaluate(() => {
  const sems = document.querySelectorAll('flt-semantics');
  const results = [];
  for (const s of sems) {
    const text = (s.textContent || '').trim();
    const role = s.getAttribute('role') || '';
    const rect = s.getBoundingClientRect();
    if (text && rect.width > 0 && rect.height > 0 && (text.includes('Manage') || text.includes('Settings') || text.includes('Memory') || text.includes('Config') || text.includes('Profiles'))) {
      results.push({ text: text.substring(0, 60), role, rect: `${Math.round(rect.x)},${Math.round(rect.y)} ${Math.round(rect.width)}x${Math.round(rect.height)}` });
    }
  }
  return results;
});
console.log('Menu items found:', menuInfo.length);
for (const m of menuInfo) {
  console.log(`  text="${m.text}" role="${m.role}" rect=${m.rect}`);
}

// Check total visible semantics
const totalSem = await page.evaluate(() => {
  return Array.from(document.querySelectorAll('flt-semantics')).filter(s => s.getBoundingClientRect().width > 0).length;
});
console.log('Total visible semantics:', totalSem);

// Now go to chat and check send button
console.log('\n=== Chat send button ===');
// Close menu by clicking somewhere else, then navigate to Support Triage
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
console.log('URL:', page.url());

// Check send button
const sendInfo = await page.evaluate(() => {
  const btns = document.querySelectorAll('flt-semantics[role="button"]');
  const results = [];
  for (const b of btns) {
    const text = (b.textContent || '').trim();
    const rect = b.getBoundingClientRect();
    if (rect.width > 0 && rect.height > 0) {
      results.push({ text: text.substring(0, 40), rect: `${Math.round(rect.x)},${Math.round(rect.y)} ${Math.round(rect.width)}x${Math.round(rect.height)}` });
    }
  }
  return results;
});
console.log('Chat buttons:');
for (const s of sendInfo) console.log(`  "${s.text}" rect=${s.rect}`);

// Check chat composer input
const chatInput = await page.evaluate(() => {
  const input = document.querySelector('[aria-label="Message Gormes"]');
  if (!input) return 'not found';
  return { tag: input.tagName, type: input.getAttribute('type'), value: input.value };
});
console.log('Chat input:', JSON.stringify(chatInput));

await browser.close();