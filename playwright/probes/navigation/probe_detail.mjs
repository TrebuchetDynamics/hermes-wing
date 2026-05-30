// Deep-dive: gateway management + profile details
import {
  APP_URL,
  clickSemantic,
  enableFlutterAccessibility,
  longPressSemantic,
  openProbePage,
} from '../support/probe_runtime.mjs';

const { browser, page } = await openProbePage();

// Navigate to gateway management
await page.goto(`${APP_URL}#/servers`, { waitUntil: 'load', timeout: 20000 });
await page.waitForTimeout(4000);
await enableFlutterAccessibility(page);

// Click Manage for Local Gormes
await clickSemantic(page, 'Manage Local Gormes', { delay: 3000 });

console.log('=== Gateway Detail ===');
const url = page.url();
console.log('URL:', url);

const textLines = await page.evaluate(() => {
  const sems = document.querySelectorAll('flt-semantics');
  const texts = new Set();
  for (const s of sems) {
    const t = (s.textContent || '').trim();
    if (t) {
      for (const line of t.split('\n')) {
        const l = line.trim();
        if (l) texts.add(l.substring(0, 100));
      }
    }
  }
  return Array.from(texts).slice(0, 30);
});
console.log('Texts:');
for (const t of textLines) console.log(`  "${t}"`);

// Now go back and test profile detail via long-press equivalent
// Navigate to profile contacts
await page.goto(`${APP_URL}#/chats`, { waitUntil: 'load', timeout: 20000 });
await page.waitForTimeout(4000);
await enableFlutterAccessibility(page);

// Try to trigger the profile detail bottom sheet by long-pressing
// Flutter's onLongPress uses GestureLongPress which translates to pointer events
console.log('\n=== Profile Detail (via long press simulation) ===');
await longPressSemantic(page, 'Support Triage', { delay: 3000 });
console.log('Profile detail trigger: long-press simulated');

const detailText = await page.evaluate(() => {
  const sems = document.querySelectorAll('flt-semantics');
  const texts = new Set();
  for (const s of sems) {
    const t = (s.textContent || '').trim();
    if (t) {
      for (const line of t.split('\n')) {
        const l = line.trim();
        if (l && l.length > 10) texts.add(l.substring(0, 100));
      }
    }
  }
  return Array.from(texts).filter(t => !t.includes('Search') && !t.includes('Navivox')).slice(0, 20);
});
console.log('Detail texts:');
for (const t of detailText) console.log(`  "${t}"`);

await page.screenshot({ path: '/tmp/navivox-gateway-detail.png' });
await browser.close();