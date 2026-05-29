// Probe all testable but untested features
import { chromium } from 'playwright';
import {
  APP_URL as APP,
  enableFlutterAccessibility,
} from '../../support/flutter_semantics.mjs';

const b = await chromium.launch({ headless: true, args: ['--no-sandbox'] });

async function probe(label, url, fn) {
  const p = await b.newPage({ viewport: { width: 1280, height: 900 } });
  await p.goto(url, { timeout: 15000 });
  await p.waitForTimeout(2000);
  await enableFlutterAccessibility(p);
  const result = await fn(p);
  console.log(`\n=== ${label} ===`);
  if (Array.isArray(result)) {
    result.forEach((r, i) => console.log(`  ${i}: ${JSON.stringify(r)}`));
  } else {
    console.log(`  ${JSON.stringify(result)}`);
  }
  await p.close();
}

// 1. Settings screen - command word sheet voice toggles
await probe('Settings switches', APP + '#/settings', async (p) => {
  const labels = await p.evaluate(() => {
    return Array.from(document.querySelectorAll('[role="switch"]'))
      .map(e => ({
        label: e.getAttribute('aria-label') || '',
        checked: e.getAttribute('aria-checked'),
        text: (e.textContent || '').trim().substring(0, 40),
      }));
  });
  return labels.length > 0 ? labels : 'NO SWITCHES FOUND';
});

// 2. Chat screen - more_vert info sheet, voice banner
await probe('Chat thread semantics', APP, async (p) => {
  // Click Support Triage to enter chat
  const btns = await p.evaluate(() => {
    const s = document.querySelectorAll('flt-semantics[role="button"]');
    for (const e of s) {
      if ((e.textContent || '').includes('Support Triage')) {
        const r = e.getBoundingClientRect();
        return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
      }
    }
    return null;
  });
  if (btns) {
    await p.mouse.click(btns.x, btns.y);
    await p.waitForTimeout(2000);
  }
  const text = await p.evaluate(() => {
    const s = document.querySelectorAll('flt-semantics');
    return Array.from(s)
      .map(e => ({
        role: e.getAttribute('role') || '',
        text: (e.textContent || '').trim().substring(0, 50),
        label: e.getAttribute('aria-label') || '',
      }))
      .filter(e => e.text.length > 0)
      .slice(0, 30);
  });
  return text;
});

// 3. FAB → Create from seed
await probe('FAB create from seed', APP, async (p) => {
  const btns = await p.evaluate(() => {
    const s = document.querySelectorAll('flt-semantics[role="button"]');
    for (const e of s) {
      if ((e.textContent || '').includes('Add profile')) {
        const r = e.getBoundingClientRect();
        return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
      }
    }
    return null;
  });
  if (btns) {
    await p.mouse.click(btns.x, btns.y);
    await p.waitForTimeout(2000);
  }
  const text = await p.evaluate(() => {
    const s = document.querySelectorAll('flt-semantics');
    return Array.from(s)
      .map(e => (e.textContent || '').trim().substring(0, 60))
      .filter(t => t.includes('Create from') || t.includes('New profile') || t.includes('Add server'));
  });
  return text;
});

// 4. Config screen - edit button
await probe('Config screen', APP + '#/config', async (p) => {
  const btns = await p.evaluate(() => {
    const s = document.querySelectorAll('flt-semantics[role="button"]');
    return Array.from(s).map(e => ({
      text: (e.textContent || '').trim().substring(0, 50),
      label: e.getAttribute('aria-label') || '',
    }));
  });
  return btns;
});

await b.close();