// Probe untested features: desktop nav rail, gateway detail, profile detail, FAB, filter, search
import { chromium } from 'playwright';
import {
  APP_URL,
  clickSemantic as clickTxt,
  enableFlutterAccessibility as acc,
} from '../../support/flutter_semantics.mjs';

const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

// 1. Check if desktop nav rail exists (all destinations)
await page.goto(APP_URL, { waitUntil: 'load', timeout: 20000 });
await page.waitForTimeout(2000); await acc(page);
console.log('=== DESKTOP NAV RAIL ===');
const rail = await page.evaluate(() => {
  // Desktop NavigationRail renders flt-semantics with NavigationRailDestination labels
  const sems = document.querySelectorAll('flt-semantics');
  const items = [];
  for (const s of sems) {
    const t = (s.textContent||'').trim();
    const r = s.getAttribute('role')||'';
    const rect = s.getBoundingClientRect();
    if (rect.width > 0 && rect.height > 0 && (r === 'button' || (t && rect.x < 257))) {
      items.push({role:r, text:t.substring(0,40), x:Math.round(rect.x), y:Math.round(rect.y)});
    }
  }
  return items;
});
for (const i of rail) console.log(`  [${i.role}] "${i.text}" at ${i.x},${i.y}`);

// 2. Check FAB → Add profile bottom sheet
await clickTxt(page, 'Add profile');
await page.waitForTimeout(2000);
const fabSheet = await page.evaluate(() => {
  const sems = document.querySelectorAll('flt-semantics');
  const items = [];
  for (const s of sems) {
    const t = (s.textContent||'').trim();
    const rect = s.getBoundingClientRect();
    if (rect.width > 0 && t && !t.startsWith('Navivox') && !t.startsWith('N\n')) {
      items.push(t.substring(0,80));
    }
  }
  return [...new Set(items)].slice(0,15);
});
console.log('\n=== FAB Bottom Sheet ===');
for (const i of fabSheet) console.log(`  "${i}"`);

// Dismiss FAB sheet
await page.keyboard.press('Escape');
await page.waitForTimeout(1000);

// 3. Check long-press profile detail (Support Triage)
console.log('\n=== PROFILE DETAIL (long press support) ===');
await clickTxt(page, 'Support Triage');
await page.waitForTimeout(2000);
// Actually long press on the Support Triage tile
// The click above navigated to chat, so go back
await page.goBack();
await page.waitForTimeout(2000); await acc(page);

// Try to trigger long-press via sequential pointer events
await page.evaluate(() => {
  const btns = document.querySelectorAll('flt-semantics[role="button"]');
  for (const b of btns) {
    if ((b.textContent||'').includes('Support Triage')) {
      // Try gesture sequence for long press
      const rect = b.getBoundingClientRect();
      const cx = rect.x + rect.width/2;
      const cy = rect.y + rect.height/2;
      b.dispatchEvent(new PointerEvent('pointerdown', {bubbles:true, clientX:cx, clientY:cy}));
      // Dispatch after simulated hold
      setTimeout(() => {
        b.dispatchEvent(new PointerEvent('pointerup', {bubbles:true, clientX:cx, clientY:cy}));
      }, 100);
    }
  }
});
await page.waitForTimeout(2000);

const detailSheet = await page.evaluate(() => {
  const sems = document.querySelectorAll('flt-semantics');
  const items = [];
  for (const s of sems) {
    const t = (s.textContent||'').trim();
    const rect = s.getBoundingClientRect();
    if (rect.width > 0 && t && t.length > 5 && !t.includes('Navivox') && !t.includes('Search profiles') && !t.includes('Open profile')) {
      items.push(t.substring(0,100));
    }
  }
  return [...new Set(items)].slice(0,20);
});
for (const i of detailSheet) console.log(`  "${i}"`);

await page.screenshot({ path: '/tmp/navivox-deep-features.png' });
await browser.close();