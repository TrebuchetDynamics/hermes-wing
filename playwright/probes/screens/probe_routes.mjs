// Probe the Navivox Flutter web app to discover what screens/routes are accessible
// and what the app shell looks like from the semantics tree

import { chromium } from 'playwright';
import {
  APP_URL,
  enableFlutterAccessibility,
} from '../../support/flutter_semantics.mjs';

const browser = await chromium.launch({ 
  headless: true,
  args: ['--no-sandbox', '--ignore-gpu-blocklist'],
});

const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

// Probe different routes
const routes = ['/', '/#/', '/#/chats', '/#/setup', '/#/servers', '/#/settings'];
const allLogs = [];

for (const route of routes) {
  page.on('console', msg => {
    if (msg.type() === 'error') allLogs.push(`[${route}] [${msg.type()}] ${msg.text()}`);
  });
  
  await page.goto(`${APP_URL.replace(/\/$/, '')}${route}`, { waitUntil: 'load', timeout: 20000 }).catch(() => {});
  await page.waitForTimeout(6000);

  // Enable accessibility
  await enableFlutterAccessibility(page, { delay: 4000 });

  // Get visible text
  const text = await page.evaluate(() => {
    const sems = document.querySelectorAll('flt-semantics');
    const texts = new Set();
    for (const s of sems) {
      const t = s.textContent?.trim();
      if (t && t.length > 0) texts.add(t.substring(0, 100));
    }
    return Array.from(texts).slice(0, 15);
  });
  
  console.log(`\n=== ${route} ===`);
  for (const t of text) console.log(`  "${t}"`);

  // Count buttons
  const btnCount = await page.evaluate(() => document.querySelectorAll('flt-semantics[role="button"]').length);
  const inputs = await page.evaluate(() => document.querySelectorAll('input').length);
  console.log(`  buttons: ${btnCount}, inputs: ${inputs}`);

  // Screenshot
  await page.screenshot({ path: `/tmp/navivox-route-${route.replace(/[/#]/g, '_')}.png` });
}

console.log('\n=== Errors ===');
for (const l of allLogs) console.log(l);

await browser.close();