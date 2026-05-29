import { chromium } from 'playwright';

// Use system Chromium with proper swiftshader for headless WebGL rendering
// The key is '--headless=new' (new headless mode) and '--use-gl=angle' with '--use-angle=swiftshader-webgl'
const browser = await chromium.launch({ 
  headless: true,
  args: [
    '--headless=new',
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--use-gl=angle',
    '--use-angle=swiftshader-webgl',
    '--enable-webgl',
    '--ignore-gpu-blocklist',
    '--enable-features=Vulkan',
  ],
});

const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

const allLogs = [];
page.on('console', msg => allLogs.push(`[${msg.type()}] ${msg.text()}`));
page.on('pageerror', err => allLogs.push(`[PAGE_ERROR] ${err.message}`));

await page.goto('http://127.0.0.1:8767/', { waitUntil: 'load', timeout: 30000 });

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