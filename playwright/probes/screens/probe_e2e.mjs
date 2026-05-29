// Probe the E2E test build to discover accessible screens
import { chromium } from 'playwright';
import {
  APP_URL,
  enableFlutterAccessibility,
} from '../../support/flutter_semantics.mjs';

const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

await page.goto(APP_URL, { waitUntil: 'load', timeout: 20000 });
await page.waitForTimeout(5000);

// Enable accessibility
await enableFlutterAccessibility(page, { delay: 4000 });

// Check current URL
console.log('URL:', page.url());

// Get all visible text
const text = await page.evaluate(() => {
  const sems = document.querySelectorAll('flt-semantics');
  const texts = new Set();
  for (const s of sems) {
    const t = s.textContent?.trim();
    if (t && t.length > 0) texts.add(t.substring(0, 100));
  }
  return Array.from(texts);
});
console.log('\n=== Visible text ===');
text.forEach(t => console.log(`  "${t}"`));

// Count elements
const el = await page.evaluate(() => ({
  buttons: document.querySelectorAll('flt-semantics[role="button"]').length,
  inputs: document.querySelectorAll('input').length,
  groups: document.querySelectorAll('flt-semantics[role="group"]').length,
  allSems: document.querySelectorAll('flt-semantics').length,
}));
console.log('\nElements:', JSON.stringify(el));

// Check key landmarks
const landmarks = await page.evaluate(() => {
  const hasAppShell = document.body.textContent?.includes('Navivox');
  const hasProfileContacts = document.body.textContent?.includes('Mineru Builder') || document.body.textContent?.includes('Support Triage');
  const hasServerFilters = document.body.textContent?.includes('filter');
  const hasChat = document.body.textContent?.includes('Message');
  const hasSettings = document.body.textContent?.includes('Settings');
  return { hasAppShell, hasProfileContacts, hasServerFilters, hasChat, hasSettings };
});
console.log('Landmarks:', JSON.stringify(landmarks));

await page.screenshot({ path: '/tmp/navivox-e2e-probe.png' });
console.log('\nScreenshot saved');
await browser.close();