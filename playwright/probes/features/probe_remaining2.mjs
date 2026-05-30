// Probe remaining testable features: agents select, search, voice toggles, register gateway
import {
  APP_URL,
  clickSemantic as click,
  enableFlutterAccessibility as a11y,
  openProbePage,
} from '../support/probe_runtime.mjs';

const { browser, page } = await openProbePage();

// 1. AGENTS - profile selection
console.log('=== 1. AGENTS: profile selection ===');
await page.goto(`${APP_URL}#/agents`, {timeout:15000});
await page.waitForTimeout(1500); await a11y(page);

// Click Voice Agent profile
await click(page, 'Voice Agent'); await page.waitForTimeout(2000);

const agentsAfter = await page.evaluate(() => {
  const sems = document.querySelectorAll('flt-semantics');
  const t = new Set();
  for (const s of sems) {
    const txt = (s.textContent||'').trim();
    if (txt && (txt.includes('Active profile') || txt.includes('Voice Agent') || txt.includes('voice'))) {
      t.add(txt.substring(0,60));
    }
  }
  return [...t];
});
console.log('After Voice Agent click:');
for (const a of agentsAfter) console.log('  "'+a+'"');

// 2. SEARCH - type text in search field
console.log('\n=== 2. SEARCH field ===');
await page.goto(APP_URL, {timeout:15000});
await page.waitForTimeout(1500); await a11y(page);

// The search input has aria-label "Search profiles" - it's a disabled input
// Try clicking the semantics overlay
const searchInfo = await page.evaluate(() => {
  const input = document.querySelector('input[aria-label="Search profiles"]');
  if (!input) return {found: false};
  const rect = input.getBoundingClientRect();
  const parent = input.closest('flt-semantics');
  return {found: true, disabled: input.disabled, rect: {x:Math.round(rect.x), y:Math.round(rect.y)}, parentRect: parent ? {x:Math.round(parent.getBoundingClientRect().x), y:Math.round(parent.getBoundingClientRect().y)} : null};
});
console.log('Search input:', JSON.stringify(searchInfo));

if (searchInfo.found) {
  // Click search button to activate search mode
  await click(page, 'Search profiles');
  await page.waitForTimeout(1500);
  
  // Now search field should be active
  // Check for input field at the top
  const searchActive = await page.evaluate(() => {
    const inputs = document.querySelectorAll('input');
    return Array.from(inputs).filter(i => i.getBoundingClientRect().width > 0).map(i => ({
      label: i.getAttribute('aria-label'),
      disabled: i.disabled,
      rect: {x:Math.round(i.getBoundingClientRect().x), y:Math.round(i.getBoundingClientRect().y)}
    }));
  });
  console.log('Active inputs:', JSON.stringify(searchActive));
  
  // Try typing in the search
  // Click on the search semantics
  await page.evaluate(() => {
    const sems = document.querySelectorAll('flt-semantics');
    for (const s of sems) {
      if ((s.textContent||'').includes('Search profiles') && s.getAttribute('role') === 'button') {
        s.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true}));
        s.dispatchEvent(new PointerEvent('pointerup',{bubbles:true}));
        s.dispatchEvent(new MouseEvent('click',{bubbles:true}));
        return;
      }
    }
  });
  await page.waitForTimeout(1000);
  
  await page.keyboard.type('mineru');
  await page.waitForTimeout(1000);
  
  const afterSearch = await page.evaluate(() => {
    const sems = document.querySelectorAll('flt-semantics');
    const t = new Set();
    for (const s of sems) {
      const txt = (s.textContent||'').trim();
      if (txt) t.add(txt.substring(0,40));
    }
    return [...t].filter(x => x.includes('Mineru') || x.includes('Support') || x.includes('Voice')).slice(0,5);
  });
  console.log('After search "mineru":', JSON.stringify(afterSearch));
}

// 3. VOICE TOGGLES - check switch state
console.log('\n=== 3. SETTINGS: switches ===');
await page.goto(`${APP_URL}#/settings`, {timeout:15000});
await page.waitForTimeout(1500); await a11y(page);

const toggles = await page.evaluate(() => {
  const all = document.querySelectorAll('[role="switch"], [aria-checked], .SwitchListTile');
  const results = [];
  for (const el of all) {
    const r = el.getBoundingClientRect();
    if (r.width > 0) {
      results.push({
        tag: el.tagName,
        role: el.getAttribute('role'),
        checked: el.getAttribute('aria-checked'),
        label: el.getAttribute('aria-label')||'',
        text: (el.textContent||'').trim().substring(0,40),
        y: Math.round(r.y)
      });
    }
  }
  return results;
});
console.log('Toggle/switch elements:', toggles.length);
for (const t of toggles) {
  console.log('  ['+t.role+'] checked='+t.checked+' label="'+t.label+'" text="'+t.text+'" at y='+t.y);
}

// 4. REGISTER GATEWAY - check if clickable
console.log('\n=== 4. REGISTER GATEWAY ===');
await page.goto(`${APP_URL}#/servers`, {timeout:15000});
await page.waitForTimeout(1500); await a11y(page);

await click(page, 'Register gateway');
await page.waitForTimeout(2000);
console.log('URL after register:', page.url());

// 5. MOBILE TAB CLICK - try clicking a tab
console.log('\n=== 5. MOBILE TAB CLICK ===');
await page.setViewportSize({width:390,height:844});
await page.goto(APP_URL, {timeout:15000});
await page.waitForTimeout(1500); await a11y(page);

// Click the Memory tab (3rd tab)
await click(page, 'tab');
await page.waitForTimeout(2000);
console.log('URL after 2nd tab click:', page.url());

// Also try clicking with tablist click at specific tab position
const tabs = await page.evaluate(() => {
  const ts = document.querySelectorAll('flt-semantics[role="tab"]');
  return Array.from(ts).map((t,i) => {
    const r = t.getBoundingClientRect();
    return {index: i, x:Math.round(r.x), y:Math.round(r.y), w:Math.round(r.width)};
  });
});
console.log('Tabs:', JSON.stringify(tabs));

if (tabs.length >= 3) {
  // Click the 3rd tab (Memory - index 2)
  await page.mouse.click(tabs[2].x + tabs[2].w/2, tabs[2].y + 20);
  await page.waitForTimeout(2000);
  console.log('URL after tab 2 click:', page.url());
}

await page.screenshot({path:'/tmp/navivox-remaining.png'});
await browser.close();