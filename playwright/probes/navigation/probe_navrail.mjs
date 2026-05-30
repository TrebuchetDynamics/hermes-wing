// Probe desktop nav rail at left edge
import {
  APP_URL,
  enableFlutterAccessibility as acc,
  openProbePage,
} from '../support/probe_runtime.mjs';

const { browser, page } = await openProbePage();

// 1. Profile contacts screen - look for nav rail
await page.goto(APP_URL, { waitUntil: 'load', timeout: 20000 });
await page.waitForTimeout(2000); await acc(page);

console.log('=== ALL ELEMENTS AT LEFT EDGE (x<257) ===');
const leftEdge = await page.evaluate(() => {
  const all = document.querySelectorAll('*');
  const items = [];
  for (const el of all) {
    const rect = el.getBoundingClientRect();
    const t = (el.textContent||'').trim();
    if (rect.width > 0 && rect.height > 0 && rect.x < 257 && t) {
      items.push({tag: el.tagName, text: t.substring(0,40), x:Math.round(rect.x)});
    }
    if (items.length > 30) break;
  }
  return items;
});
for (const i of leftEdge) console.log(`  <${i.tag}> "${i.text}" at x=${i.x}`);

// Check for NavigationRail or similar
const navRail = await page.evaluate(() => {
  const els = document.querySelectorAll('[class*="nav"], [class*="rail"], flt-semantics');
  return Array.from(els).filter(e => e.getBoundingClientRect().width > 0).slice(0,50).map(e => ({
    tag: e.tagName, cls: (e.className||'').substring(0,30), role: e.getAttribute('role')||'',
    text: (e.textContent||'').trim().substring(0,30), x: Math.round(e.getBoundingClientRect().x)
  }));
});
console.log('\n=== All elements with nav/rail class or flt-semantics ===');
for (const n of navRail) console.log(`  <${n.tag}> class="${n.cls}" role="${n.role}" text="${n.text}" x=${n.x}`);

// 2. Check different screens for nav rail
const screens = ['/chats', '/servers', '/agents', '/memory', '/config', '/settings'];
for (const s of screens) {
  await page.goto(`${APP_URL}#${s}`, { waitUntil: 'load', timeout: 15000 }).catch(()=>{});
  await page.waitForTimeout(1500); await acc(page);
  
  const atLeft = await page.evaluate(() => {
    const sems = document.querySelectorAll('flt-semantics');
    const items = [];
    for (const s of sems) {
      const r = s.getBoundingClientRect();
      const t = (s.textContent||'').trim();
      if (r.width > 0 && r.height > 0 && r.x < 257 && t && !t.startsWith('flutter-view')) {
        items.push({text: t.substring(0,40), x: Math.round(r.x), role: s.getAttribute('role')||''});
      }
    }
    return items;
  });
  console.log(`\n=== ${s} - Left edge elements ===`);
  for (const i of atLeft) console.log(`  [${i.role}] "${i.text}" at x=${i.x}`);
}

await browser.close();