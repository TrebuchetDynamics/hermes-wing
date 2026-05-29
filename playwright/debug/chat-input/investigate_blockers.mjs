// Investigate: 1) Nav rail semantics 2) Long-press via gesture 3) Keyboard text entry
import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

async function a11y(p) {
  await p.evaluate(() => document.querySelector('flt-semantics-placeholder')?.dispatchEvent(new MouseEvent('click', {bubbles:true})));
  await p.waitForTimeout(2000);
}

await page.goto('http://127.0.0.1:8767/', { timeout: 20000 });
await page.waitForTimeout(2000); await a11y(page);

// 1. DEEP NAV RAIL PROBE: check for ANY elements with nav-related text at left
console.log('=== 1. NAV RAIL INVESTIGATION ===');
const navCandidates = await page.evaluate(() => {
  const searchWords = ['Chats', 'Servers', 'Agents', 'Memory', 'Config', 'Settings', 'chat_bubble', 'dns', 'smart_toy', 'psychology', 'keyboard_voice'];
  const all = document.querySelectorAll('*');
  const found = [];
  for (const el of all) {
    const t = (el.textContent||'').trim();
    const label = el.getAttribute('aria-label')||'';
    const rect = el.getBoundingClientRect();
    const role = el.getAttribute('role')||'';
    const cls = (el.className||'').substring(0,40);
    for (const w of searchWords) {
      if ((t.includes(w) || label.includes(w)) && rect.width > 0) {
        found.push({tag: el.tagName, role, cls, text: t.substring(0,30), label, x:Math.round(rect.x), y:Math.round(rect.y)});
        break;
      }
    }
  }
  return found.slice(0,40);
});
console.log('Nav-related elements:', navCandidates.length);
for (const n of navCandidates) console.log(`  <${n.tag}> role="${n.role}" cls="${n.cls}" text="${n.text}" label="${n.label}" at ${n.x},${n.y}`);

// Check if NavigationRail exists at all via class names
const railEls = await page.evaluate(() => {
  const all = document.querySelectorAll('*');
  return Array.from(all).filter(e => {
    const c = e.className || '';
    const t = (e.textContent||'').trim();
    const r = e.getBoundingClientRect();
    return (typeof c === 'string' && (c.includes('rail') || c.includes('nav'))) && r.width > 0;
  }).slice(0,10).map(e => ({tag: e.tagName, cls: (e.className||'').substring(0,40), rect: e.getBoundingClientRect()}));
});
console.log('\nRail/nav class elements:', railEls.length);
for (const r of railEls) console.log(`  <${r.tag}> class="${r.cls}" at ${Math.round(r.rect.x)},${Math.round(r.rect.y)} ${Math.round(r.rect.width)}x${Math.round(r.rect.height)}`);

// 2. LONG PRESS: try pointerdown hold for 1s then pointerup
console.log('\n=== 2. LONG PRESS TEST ===');
// Navigate to profile contacts first
await page.goto('http://127.0.0.1:8767/', { timeout: 15000 });
await page.waitForTimeout(2000); await a11y(page);

const lpResult = await page.evaluate(() => {
  return new Promise((resolve) => {
    const btns = document.querySelectorAll('flt-semantics[role="button"]');
    for (const b of btns) {
      if ((b.textContent||'').includes('Support Triage')) {
        const rect = b.getBoundingClientRect();
        const cx = rect.x + rect.width/2;
        const cy = rect.y + rect.height/2;
        
        // Track what appears
        b.dispatchEvent(new PointerEvent('pointerdown', {bubbles:true, clientX:cx, clientY:cy}));
        
        // Hold for 1200ms then release
        setTimeout(() => {
          b.dispatchEvent(new PointerEvent('pointerup', {bubbles:true, clientX:cx, clientY:cy}));
          
          // Check for detail sheet (new text appearing)
          const sems = document.querySelectorAll('flt-semantics');
          const newText = [];
          for (const s of sems) {
            const t = (s.textContent||'').trim();
            if (t && t.length > 10 && !t.includes('Navivox') && !t.includes('Search profiles')) {
              newText.push(t.substring(0,60));
            }
          }
          resolve([...new Set(newText)].slice(0,10));
        }, 1200);
        return;
      }
    }
    resolve(['button not found']);
  });
});
console.log('After long press:');
for (const t of lpResult) console.log(`  "${t}"`);

// 3. KEYBOARD TEXT ENTRY: try clicking semantics overlay then keyboard.type
console.log('\n=== 3. TEXT ENTRY VIA KEYBOARD ===');
// Navigate to Support Triage chat
const clicked = await page.evaluate(() => {
  const btns = document.querySelectorAll('flt-semantics[role="button"]');
  for (const b of btns) {
    if ((b.textContent||'').includes('Support Triage')) {
      b.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true}));
      b.dispatchEvent(new PointerEvent('pointerup',{bubbles:true}));
      b.dispatchEvent(new MouseEvent('click',{bubbles:true}));
      return true;
    }
  }
  return false;
});
await page.waitForTimeout(3000);
console.log('At chat:', page.url());

// Find the textarea semantics parent
const semParent = await page.evaluate(() => {
  const ta = document.querySelector('textarea[aria-label="Message Gormes"]');
  if (!ta) return null;
  const parent = ta.closest('flt-semantics');
  if (!parent) return {tag: ta.tagName, rect: ta.getBoundingClientRect()};
  return {tag: parent.tagName, rect: parent.getBoundingClientRect(), role: parent.getAttribute('role')};
});
console.log('Textarea container:', JSON.stringify(semParent));

// Click the semantics parent to focus
if (semParent) {
  await page.mouse.click(semParent.rect.x + 10, semParent.rect.y + 10);
  await page.waitForTimeout(500);
  
  // Try keyboard input
  await page.keyboard.type('keyboard typed hello');
  await page.waitForTimeout(500);
  
  // Check if value was transmitted
  const val = await page.evaluate(() => {
    const ta = document.querySelector('textarea[aria-label="Message Gormes"]');
    return ta ? ta.value : null;
  });
  console.log('Textarea value after keyboard:', val);
  
  // Also check by trying to click the semantics and then type
  // Try clicking the flt-semantics directly
  await page.evaluate(() => {
    const ta = document.querySelector('textarea[aria-label="Message Gormes"]');
    const sem = ta?.closest('flt-semantics');
    if (sem) {
      sem.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true}));
      sem.dispatchEvent(new PointerEvent('pointerup',{bubbles:true}));
      sem.dispatchEvent(new MouseEvent('click',{bubbles:true}));
    }
  });
  await page.waitForTimeout(500);
  await page.keyboard.type(' more text');
  await page.waitForTimeout(500);
  
  const val2 = await page.evaluate(() => {
    const ta = document.querySelector('textarea[aria-label="Message Gormes"]');
    return ta ? ta.value : null;
  });
  console.log('Textarea value after 2nd attempt:', val2);
  
  // Now try to click the send button (last empty button)
  await page.evaluate(() => {
    const btns = document.querySelectorAll('flt-semantics[role="button"]');
    const b = btns[btns.length - 1]; // Send button is last
    if (b) {
      b.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true}));
      b.dispatchEvent(new PointerEvent('pointerup',{bubbles:true}));
      b.dispatchEvent(new MouseEvent('click',{bubbles:true}));
    }
  });
  await page.waitForTimeout(2000);
  
  const texts = await page.evaluate(() => {
    const sems = document.querySelectorAll('flt-semantics');
    return Array.from(sems).slice(0,20).map(s => (s.textContent||'').trim().substring(0,60)).filter(t => t);
  });
  console.log('Texts after send:', [...new Set(texts)].slice(0,10));
}

await page.screenshot({path:'/tmp/navivox-blockers-test.png'});
await browser.close();