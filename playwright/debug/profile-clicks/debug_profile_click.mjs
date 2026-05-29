// Debug: find how to click profile contacts
import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

await page.goto('http://127.0.0.1:8767/', { waitUntil: 'load', timeout: 20000 });
await page.waitForTimeout(5000);

// Enable accessibility
await page.evaluate(() => {
  document.querySelector('flt-semantics-placeholder')?.dispatchEvent(new MouseEvent('click', { bubbles: true }));
});
await page.waitForTimeout(3000);

// Find all flt-semantics elements and check their roles, labels, and positions near "Mineru Builder"
const profileElements = await page.evaluate(() => {
  const all = document.querySelectorAll('flt-semantics');
  const results = [];
  for (const el of all) {
    const text = el.textContent?.trim() || '';
    const role = el.getAttribute('role') || '';
    const label = el.getAttribute('aria-label') || '';
    const rect = el.getBoundingClientRect();
    const tag = el.tagName;
    const style = el.getAttribute('style') || '';
    const childTags = Array.from(el.children).map(c => c.tagName).join(',');
    const childRoles = Array.from(el.children).map(c => c.getAttribute('role') || '').join(',');
    results.push({ tag, role, label, text: text.substring(0, 80), childTags: childTags.substring(0, 50), childRoles: childRoles.substring(0, 50), rect });
  }
  return results.filter(r => r.text.includes('Mineru') || r.text.includes('Support') || r.role === 'link' || r.role === 'listitem');
});

console.log('Profile-related semantics:');
for (const r of profileElements) {
  console.log(`  <${r.tag}> role="${r.role}" label="${r.label}"`);
  console.log(`    text="${r.text}"`);
  console.log(`    children="${r.childTags}" roles="${r.childRoles}"`);
  console.log(`    rect=${Math.round(r.rect.x)},${Math.round(r.rect.y)} ${Math.round(r.rect.width)}x${Math.round(r.rect.height)}`);
}

// Check what happens when we click on the ListTile area
console.log('\nTrying to click on the Mineru Builder tile area...');
const mineruTile = await page.evaluate(() => {
  // Find the flt-semantics that contains "Mineru Builder" but not as part of a larger blob
  const all = document.querySelectorAll('flt-semantics');
  for (const el of all) {
    const text = el.textContent || '';
    if (text.includes('Mineru Builder') && !text.includes('Mineru Builderprofile')) {
      const rect = el.getBoundingClientRect();
      return { 
        x: Math.round(rect.x + rect.width/2), 
        y: Math.round(rect.y + rect.height/2),
        text: text.substring(0, 100),
        tag: el.tagName,
        role: el.getAttribute('role'),
      };
    }
  }
  return null;
});
console.log('Mineru tile target:', JSON.stringify(mineruTile));

if (mineruTile) {
  // Click the center of the tile
  await page.mouse.click(mineruTile.x, mineruTile.y);
  await page.waitForTimeout(3000);
  console.log('After click URL:', page.url());
  
  const texts = await page.evaluate(() => {
    const sems = document.querySelectorAll('flt-semantics');
    return Array.from(sems).slice(0, 10).map(s => s.textContent?.trim().substring(0, 80));
  });
  console.log('Texts:', JSON.stringify(texts));
}

await browser.close();