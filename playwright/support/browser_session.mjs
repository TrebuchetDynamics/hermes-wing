import { chromium } from 'playwright';

export const DEFAULT_BROWSER_VIEWPORT = { width: 1280, height: 900 };
export const DEFAULT_BROWSER_LAUNCH_ARGS = ['--no-sandbox', '--ignore-gpu-blocklist'];

export async function createBrowser({ launchOptions = {}, defaultLaunchArgs = DEFAULT_BROWSER_LAUNCH_ARGS } = {}) {
  return chromium.launch({
    headless: true,
    ...launchOptions,
    args: launchOptions.args ?? defaultLaunchArgs,
  });
}

export async function createBrowserPage(
  browser,
  { pageOptions = {}, defaultViewport = DEFAULT_BROWSER_VIEWPORT } = {},
) {
  return browser.newPage({
    ...pageOptions,
    viewport: pageOptions.viewport ?? defaultViewport,
  });
}

export async function createBrowserSession({
  launchOptions = {},
  pageOptions = {},
  defaultLaunchArgs = DEFAULT_BROWSER_LAUNCH_ARGS,
  defaultViewport = DEFAULT_BROWSER_VIEWPORT,
} = {}) {
  const browser = await createBrowser({ launchOptions, defaultLaunchArgs });
  const page = await createBrowserPage(browser, { pageOptions, defaultViewport });
  return { browser, page };
}
