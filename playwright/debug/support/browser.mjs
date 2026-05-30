import { chromium } from 'playwright';

export const DEFAULT_APP_URL = process.env.NAVIVOX_DEBUG_URL ?? 'http://127.0.0.1:8767/';
export const DEFAULT_VIEWPORT = { width: 1280, height: 900 };
export const DEFAULT_LAUNCH_ARGS = ['--no-sandbox', '--ignore-gpu-blocklist'];
export const SWIFTSHADER_LAUNCH_ARGS = [
  '--headless=new',
  '--no-sandbox',
  '--disable-setuid-sandbox',
  '--use-gl=angle',
  '--use-angle=swiftshader-webgl',
  '--enable-webgl',
  '--ignore-gpu-blocklist',
  '--enable-features=Vulkan',
];

export async function createDebugPage({ launchOptions = {}, pageOptions = {} } = {}) {
  const browser = await chromium.launch({
    headless: true,
    ...launchOptions,
    args: launchOptions.args ?? DEFAULT_LAUNCH_ARGS,
  });
  const page = await browser.newPage({
    ...pageOptions,
    viewport: pageOptions.viewport ?? DEFAULT_VIEWPORT,
  });
  return { browser, page };
}

export async function openDebugPage({
  appUrl = DEFAULT_APP_URL,
  gotoOptions = { waitUntil: 'load', timeout: 20000 },
  launchOptions = {},
  pageOptions = {},
  settleMs = 0,
  enableAccessibility = false,
  accessibilitySettleMs = 3000,
} = {}) {
  const { browser, page } = await createDebugPage({ launchOptions, pageOptions });

  await page.goto(appUrl, gotoOptions);
  if (settleMs > 0) await page.waitForTimeout(settleMs);
  if (enableAccessibility) {
    await enableFlutterAccessibility(page, { settleMs: accessibilitySettleMs });
  }

  return { browser, page };
}

export async function enableFlutterAccessibility(page, { settleMs = 3000 } = {}) {
  await page.evaluate(() => {
    document.querySelector('flt-semantics-placeholder')?.dispatchEvent(
      new MouseEvent('click', { bubbles: true, cancelable: true }),
    );
  });
  if (settleMs > 0) await page.waitForTimeout(settleMs);
}
