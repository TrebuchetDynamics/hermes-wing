// Probe remaining features: gateway manage modal, mobile shell, voice toggles, command word, route guard
import {
  APP_URL,
  clickSemantic as click,
  enableFlutterAccessibility as a11y,
  openProbePage,
} from '../support/probe_runtime.mjs';

const { browser, page } = await openProbePage();

// 1. MOBILE VIEWPORT
console.log('=== 1. MOBILE VIEWPORT (390x844) ===');
await page.setViewportSize({ width: 390, height: 844 });
await page.goto(APP_URL, { timeout: 20000 });
await page.waitForTimeout(2000); await a11y(page);

const mobileLayout = await page.evaluate(() => {
  const sems = document.querySelectorAll('flt-semantics');
  const items = [];
  for (const s of sems) {
    const r = s.getBoundingClientRect();
    const role = s.getAttribute('role')||'';
    const t = (s.textContent||'').trim().substring(0,30);
    if (r.width > 0 && (role || t)) items.push({role, text:t, x:Math.round(r.x), y:Math.round(r.y), w:Math.round(r.width), h:Math.round(r.height)});
  }
  return items.slice(0,30);
});
console.log('Mobile semantics:');
for (const m of mobileLayout) {
  if (m.text || m.role) console.log(`  [${m.role}] "${m.text}" at ${m.x},${m.y} ${m.w}x${m.h}`);
}
await page.screenshot({path:'/tmp/navivox-mobile.png'});

// 2. GATEWAY MANAGEMENT MODAL
console.log('\n=== 2. GATEWAY MANAGE MODAL ===');
await page.setViewportSize({ width: 1280, height: 900 });
await page.goto(`${APP_URL}#/servers`, { timeout: 15000 });
await page.waitForTimeout(1500); await a11y(page);

// Click Manage for Local Gormes
await click(page, 'Manage Local Gormes');
await page.waitForTimeout(2000);

const gwDetail = await page.evaluate(() => {
  const sems = document.querySelectorAll('flt-semantics');
  const texts = new Set();
  for (const s of sems) {
    const t = (s.textContent||'').trim();
    if (t && !t.startsWith('Gateways') && !t.startsWith('N\n')) {
      for (const line of t.split('\n')) {
        const l = line.trim();
        if (l) texts.add(l.substring(0,80));
      }
    }
  }
  return Array.from(texts).filter(t => t.length > 5).slice(0,20);
});
console.log('Gateway detail texts:');
for (const t of gwDetail) console.log(`  "${t}"`);

// Dismiss
await page.keyboard.press('Escape');
await page.waitForTimeout(1000);

// 3. SETTINGS TOGGLES (continuous voice switch)
console.log('\n=== 3. VOICE SETTINGS TOGGLES ===');
await page.goto(`${APP_URL}#/settings`, { timeout: 15000 });
await page.waitForTimeout(1500); await a11y(page);

const switches = await page.evaluate(() => {
  const switches = document.querySelectorAll('flt-semantics[role="switch"], [role="checkbox"]');
  return Array.from(switches).filter(s => s.getBoundingClientRect().width > 0).map(s => ({
    role: s.getAttribute('role'),
    label: s.getAttribute('aria-label')||'',
    checked: s.getAttribute('aria-checked'),
    text: (s.textContent||'').trim().substring(0,40),
    rect: s.getBoundingClientRect(),
  }));
});
console.log('Switch elements:');
for (const s of switches) console.log(`  [${s.role}] label="${s.label}" checked=${s.checked} text="${s.text}"`);

// 4. APP SHELL NAVIGATION - check all screens for nav bar structure
console.log('\n=== 4. NAVIGATION STRUCTURE ===');
const routes = ['/chats', '/servers', '/agents', '/memory', '/config', '/settings'];
const navText = {};
for (const route of routes) {
  await page.goto(`${APP_URL}#${route}`, { timeout: 15000 }).catch(()=>{});
  await page.waitForTimeout(1500); await a11y(page);
  
  // Look for bottom nav items (mobile) or navigation rail items
  const items = await page.evaluate(() => {
    const sems = document.querySelectorAll('flt-semantics');
    const nav = [];
    for (const s of sems) {
      const r = s.getBoundingClientRect();
      const role = s.getAttribute('role')||'';
      const t = (s.textContent||'').trim().substring(0,30);
      // Bottom nav items are typically at the bottom of the screen
      if (r.width > 0 && r.y > 600 && (role === 'button' || role === '')) {
        nav.push({role, text:t, x:Math.round(r.x), y:Math.round(r.y), w:Math.round(r.width)});
      }
    }
    return nav.slice(0,10);
  });
  navText[route] = items;
  console.log(`${route} bottom buttons:`, items.length);
  for (const i of items) console.log(`  [${i.role}] "${i.text}" at y=${i.y}`);
}

await browser.close();