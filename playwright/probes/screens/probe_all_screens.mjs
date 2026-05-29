// Probe all navigable screens for content
import { chromium } from 'playwright';
import {
  APP_URL,
  enableFlutterAccessibility,
} from '../../support/flutter_semantics.mjs';

const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

const screens = [
  { route: '/', label: 'Profile Contacts' },
  { route: '/servers', label: 'Gateways' },
  { route: '/agents', label: 'Agents' },
  { route: '/memory', label: 'Memory' },
  { route: '/config', label: 'Config' },
  { route: '/settings', label: 'Settings' },
];

for (const { route, label } of screens) {
  await page.goto(`${APP_URL}#${route}`, { waitUntil: 'load', timeout: 20000 }).catch(() => {});
  await page.waitForTimeout(4000);
  await enableFlutterAccessibility(page);

  // Get visible text lines
  const textLines = await page.evaluate(() => {
    const sems = document.querySelectorAll('flt-semantics');
    const texts = new Set();
    for (const s of sems) {
      const t = (s.textContent || '').trim();
      if (t) {
        for (const line of t.split('\n')) {
          const l = line.trim();
          if (l) texts.add(l.substring(0, 80));
        }
      }
    }
    return Array.from(texts).slice(0, 30);
  });

  const buttons = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('flt-semantics[role="button"], flt-semantics[role="menuitem"]'))
      .filter(b => b.getBoundingClientRect().width > 0)
      .map(b => ({
        text: (b.textContent || '').trim().substring(0, 40),
        label: b.getAttribute('aria-label') || '',
        role: b.getAttribute('role'),
        x: Math.round(b.getBoundingClientRect().x),
      }));
  });

  console.log(`\n=== ${label} (/#${route}) ===`);
  console.log('Texts:');
  for (const t of textLines) console.log(`  "${t}"`);
  console.log('Buttons/Items:');
  for (const b of buttons) console.log(`  [${b.role}] "${b.label || b.text}" at x=${b.x}`);

  await page.screenshot({ path: `/tmp/navivox-screen-${label.toLowerCase().replace(/\s+/g, '-')}.png` });
}

await browser.close();