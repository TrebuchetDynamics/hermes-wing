import { DEFAULT_APP_URL, createDebugPage, SWIFTSHADER_LAUNCH_ARGS } from '../support/browser.mjs';

// Use system Chromium with proper swiftshader for headless WebGL rendering.
const { browser, page } = await createDebugPage({
  launchOptions: { args: SWIFTSHADER_LAUNCH_ARGS },
});

const allLogs = [];
page.on('console', msg => allLogs.push(`[${msg.type()}] ${msg.text()}`));
page.on('pageerror', err => allLogs.push(`[PAGE_ERROR] ${err.message}`));

await page.goto(DEFAULT_APP_URL, { waitUntil: 'load', timeout: 30000 });

// Check WebGL immediately
const wg = await page.evaluate(() => {
  const c = document.createElement('canvas');
  const gl2 = c.getContext('webgl2');
  const gl = gl2 || c.getContext('webgl');
  if (!gl) return { ok: false, err: c.getContext('webgl') };
  return { ok: true, vendor: gl.getParameter(gl.VENDOR), renderer: gl.getParameter(gl.RENDERER) };
});
console.log('WebGL:', JSON.stringify(wg));

for (let i = 0; i < 10; i++) {
  await page.waitForTimeout(3000);
  const el = await page.evaluate(() => ({
    canvas: document.querySelectorAll('canvas').length,
    scene: document.querySelectorAll('flt-scene-host').length,
  }));
  console.log(`Wait ${(i+1)*3}s: canvas=${el.canvas} scene=${el.scene}`);
  if (el.canvas > 0) break;
}

console.log('\n=== Console ===');
for (const l of allLogs) console.log(l);

await page.screenshot({ path: '/tmp/navivox-headlessnew.png' });
console.log('Screenshot saved');
await browser.close();