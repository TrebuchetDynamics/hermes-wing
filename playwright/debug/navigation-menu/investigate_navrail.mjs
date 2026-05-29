// Investigate: nav rail semantics tree + chat text entry
import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: true, args: ['--no-sandbox','--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

await page.goto('http://127.0.0.1:8767/', { timeout: 20000 });
await page.waitForTimeout(2000);
await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.dispatchEvent(new MouseEvent('click', {bubbles:true})));
await page.waitForTimeout(2000);

// Build full semantics tree
const tree = await page.evaluate(() => {
  function walk(el, depth) {
    const r = el.getBoundingClientRect();
    const results = [];
    const role = el.getAttribute('role') || '';
    const label = el.getAttribute('aria-label') || '';
    const text = (el.textContent||'').trim().substring(0,30);
    if (r.width > 0 && el.tagName === 'FLT-SEMANTICS') {
      results.push({d:depth, role, label, text, x:Math.round(r.x), y:Math.round(r.y), w:Math.round(r.width)});
    }
    for (const c of el.children) results.push(...walk(c, depth+1));
    return results;
  }
  return walk(document.querySelector('flutter-view'), 0);
});

console.log('=== FULL SEMANTICS TREE ===');
for (const t of tree) {
  const indent = '  '.repeat(t.d);
  console.log(indent + 'role=' + t.role + ' label="' + t.label + '" text="' + t.text + '" at ' + t.x + ',' + t.y + ' ' + t.w + 'px');
}

const left = tree.filter(t => t.x < 257);
console.log('\n=== LEFT EDGE (nav rail area, x<257) ===');
for (const t of left) {
  console.log('  role=' + t.role + ' label="' + t.label + '" text="' + t.text + '" at ' + t.x + ',' + t.y);
}

// Now test: go to a non-chats screen to see if nav rail appears differently
console.log('\n=== SETTINGS SCREEN TREE ===');
await page.goto('http://127.0.0.1:8767/#/settings', { timeout: 15000 });
await page.waitForTimeout(1500);
await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.dispatchEvent(new MouseEvent('click', {bubbles:true})));
await page.waitForTimeout(2000);

const tree2 = await page.evaluate(() => {
  function walk(el, d) {
    const r = el.getBoundingClientRect();
    const res = [];
    if (r.width > 0 && el.tagName === 'FLT-SEMANTICS') {
      res.push({d, role:el.getAttribute('role')||'', label:el.getAttribute('aria-label')||'', text:(el.textContent||'').trim().substring(0,30), x:Math.round(r.x), y:Math.round(r.y), w:Math.round(r.width)});
    }
    for (const c of el.children) res.push(...walk(c, d+1));
    return res;
  }
  return walk(document.querySelector('flutter-view'), 0);
});

const left2 = tree2.filter(t => t.x < 257);
console.log('Left edge on settings screen: ' + left2.length);
for (const t of left2) {
  console.log('  role=' + t.role + ' label="' + t.label + '" text="' + t.text + '" at ' + t.x + ',' + t.y);
}

await browser.close();