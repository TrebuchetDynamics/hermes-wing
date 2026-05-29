import { chromium } from 'playwright';

const browser = await chromium.launch({ 
  headless: true,
  args: ['--no-sandbox', '--ignore-gpu-blocklist', '--use-gl=angle', '--use-angle=swiftshader'],
});

const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

const logs = [];
page.on('console', msg => logs.push(`[${msg.type()}] ${msg.text()}`));
page.on('pageerror', err => logs.push(`[PAGE_ERROR] ${err.message}`));

await page.goto('http://127.0.0.1:8767/', { waitUntil: 'load', timeout: 30000 });
await page.waitForTimeout(5000);

// Click the Enable accessibility placeholder via JS (it's at -1,-1 so can't be clicked normally)
await page.evaluate(() => {
  const placeholder = document.querySelector('flt-semantics-placeholder');
  if (placeholder) {
    // Dispatch a click event directly
    placeholder.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
    placeholder.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, cancelable: true }));
    placeholder.dispatchEvent(new PointerEvent('pointerup', { bubbles: true, cancelable: true }));
  }
});
console.log('Clicked accessibility placeholder');

await page.waitForTimeout(8000);

const state = await page.evaluate(() => {
  const sems = document.querySelectorAll('flt-semantics');
  const results = [];
  for (const sem of sems) {
    const rect = sem.getBoundingClientRect();
    const role = sem.getAttribute('role') || '';
    const label = sem.getAttribute('aria-label') || '';
    const text = (sem.textContent || '').trim().substring(0, 80);
    if (rect.width > 0 && rect.height > 0) {
      results.push({ role, label, text: text.substring(0, 60), rect });
    }
    if (results.length > 100) break;
  }
  return results;
});

console.log(`\nSemantics elements with size: ${state.length}`);
for (const s of state) {
  console.log(`  role="${s.role}" label="${s.label}" text="${s.text}" rect=${Math.round(s.rect.x)},${Math.round(s.rect.y)} ${Math.round(s.rect.width)}x${Math.round(s.rect.height)}`);
}

// Also get all aria-labeled elements
const allAria = await page.evaluate(() => {
  const all = document.querySelectorAll('[aria-label]');
  return Array.from(all).slice(0, 30).map(el => ({
    tag: el.tagName,
    label: el.getAttribute('aria-label'),
    text: (el.textContent || '').trim().substring(0, 60),
    rect: el.getBoundingClientRect(),
  }));
});
console.log(`\nAll aria-labeled elements: ${allAria.length}`);
for (const a of allAria) {
  if (a.rect.width > 0 && a.rect.height > 0) {
    console.log(`  <${a.tag}> label="${a.label}" text="${a.text}"`);
  }
}

await page.screenshot({ path: '/tmp/navivox-sema-enabled.png' });
console.log('\nScreenshot saved');
await browser.close();