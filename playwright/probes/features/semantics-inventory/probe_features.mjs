// Probe: server filter chips, nav rail labels, settings interactions
import {
  APP_URL,
  clickSemantic as clickTxt,
  openProbePage,
} from '../../support/probe_runtime.mjs';
import { waitForProbeReady } from '../shared/page_readiness.mjs';

const { browser, page } = await openProbePage();

await page.goto(APP_URL, { waitUntil: 'load', timeout: 20000 });
await waitForProbeReady(page, { delayMs: 2000 });

// 1. Probe ALL semantics elements with their role and position
console.log('=== COMPLETE SEMANTICS TREE ===');
const all = await page.evaluate(() => {
  const sems = document.querySelectorAll('flt-semantics');
  const items = [];
  for (const s of sems) {
    const r = s.getBoundingClientRect();
    if (r.width > 0) {
      const role = s.getAttribute('role')||'';
      const label = s.getAttribute('aria-label')||'';
      const text = (s.textContent||'').trim().substring(0,50);
      const tag = s.tagName;
      items.push({role, label, text, x:Math.round(r.x), y:Math.round(r.y), w:Math.round(r.width)});
    }
  }
  return items;
});
// Show role, text, and position for all items
for (const i of all) {
  if (i.role || i.label || i.text) {
    console.log(`  [${i.role||'-'}] label="${i.label}" text="${i.text}" at ${i.x},${i.y} ${i.w}px`);
  }
}

// 2. Check for nav rail labels (Chats, Servers, Agents, Memory, Config, Settings)
console.log('\n=== NAV RAIL SEARCH ===');
const navLabels = ['Chats','Servers','Agents','Memory','Config','Settings'];
for (const l of navLabels) {
  const found = all.filter(i => i.text.includes(l) || i.label.includes(l));
  if (found.length > 0) {
    for (const f of found) console.log(`  Found "${l}": [${f.role}] "${f.text}" at ${f.x},${f.y}`);
  } else {
    console.log(`  NOT FOUND: "${l}"`);
  }
}

// 3. Check for server filter labels
console.log('\n=== SERVER FILTER SEARCH ===');
const filterLabels = ['All','Local Gormes','Office Gormes'];
for (const l of filterLabels) {
  const found = all.filter(i => i.text.includes(l) || i.label.includes(l));
  if (found.length > 0) {
    for (const f of found) console.log(`  Found "${l}": [${f.role}] "${f.text}" at ${f.x},${f.y}`);
  } else {
    console.log(`  NOT FOUND: "${l}"`);
  }
}

// 4. Check for settings screen interactions
await page.goto(`${APP_URL}#/settings`, { waitUntil: 'load', timeout: 15000 });
await waitForProbeReady(page, { delayMs: 1500 });

const settings = await page.evaluate(() => {
  const btns = document.querySelectorAll('flt-semantics[role="button"]');
  return Array.from(btns).filter(b => b.getBoundingClientRect().width > 0).map(b => ({
    text: (b.textContent||'').trim().substring(0,40),
    label: b.getAttribute('aria-label')||'',
    x: Math.round(b.getBoundingClientRect().x), y: Math.round(b.getBoundingClientRect().y),
  }));
});
console.log('\n=== SETTINGS BUTTONS ===');
for (const b of settings) console.log(`  "${b.label||b.text}" at ${b.x},${b.y}`);

await browser.close();