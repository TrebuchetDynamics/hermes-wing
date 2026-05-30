// Debug: check chat send button and input
import { openDebugPage } from '../support/browser.mjs';

const { browser, page } = await openDebugPage({
  gotoOptions: { waitUntil: 'load', timeout: 20000 },
  settleMs: 4000,
  enableAccessibility: true,
});

// Navigate to chat fresh (without opening menu)
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

// Check ALL semantics after navigation
const chatState = await page.evaluate(() => {
  const sems = document.querySelectorAll('flt-semantics');
  const results = [];
  for (const s of sems) {
    const rect = s.getBoundingClientRect();
    if (rect.width > 0 && rect.height > 0) {
      const role = s.getAttribute('role') || '';
      const label = s.getAttribute('aria-label') || '';
      const text = (s.textContent || '').trim().substring(0, 50);
      results.push({ role, label, text, rect: `${Math.round(rect.x)},${Math.round(rect.y)} ${Math.round(rect.width)}x${Math.round(rect.height)}` });
    }
  }
  return results;
});
console.log('Chat semantics:');
for (const s of chatState) {
  if (s.label || s.text) {
    console.log(`  role=${s.role.padEnd(10)} label="${s.label}" text="${s.text}" rect=${s.rect}`);
  }
}

// Check send button specifically
const sendBtn = chatState.find(s => s.label === 'Send' || s.text.includes('Send') || s.text.includes('send'));
console.log('\nSend button:', JSON.stringify(sendBtn));

// Check chat input
const chatInput = await page.evaluate(() => {
  const inputs = document.querySelectorAll('input');
  return Array.from(inputs).map(i => ({
    'aria-label': i.getAttribute('aria-label'),
    type: i.getAttribute('type'),
    value: i.value,
    rect: i.getBoundingClientRect(),
  })).filter(i => i.rect.width > 0);
});
console.log('Chat inputs:', JSON.stringify(chatInput, null, 2));

await browser.close();