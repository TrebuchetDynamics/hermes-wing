import {
  DEFAULT_BROWSER_LAUNCH_ARGS,
  DEFAULT_BROWSER_VIEWPORT,
  createBrowserSession,
} from '../../support/browser_session.mjs';
import { enableFlutterAccessibility as enableSharedFlutterAccessibility } from '../../support/flutter_semantics.mjs';

export const DEFAULT_APP_URL = process.env.NAVIVOX_DEBUG_URL ?? 'http://127.0.0.1:8767/';
export const DEFAULT_VIEWPORT = DEFAULT_BROWSER_VIEWPORT;
export const DEFAULT_LAUNCH_ARGS = DEFAULT_BROWSER_LAUNCH_ARGS;
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
  return createBrowserSession({
    launchOptions,
    pageOptions,
    defaultLaunchArgs: DEFAULT_LAUNCH_ARGS,
    defaultViewport: DEFAULT_VIEWPORT,
  });
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
  await enableSharedFlutterAccessibility(page, { delay: settleMs });
}

// Convenience: enable a11y with the shorter 2s settle used by most debug scripts.
export async function a11y(page) {
  await enableFlutterAccessibility(page, { settleMs: 2000 });
}
