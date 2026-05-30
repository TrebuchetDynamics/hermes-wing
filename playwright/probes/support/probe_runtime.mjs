import { chromium } from 'playwright';

export {
  APP_URL,
  activateVisibleSemantics,
  clickSemantic,
  enableFlutterAccessibility,
  longPressSemantic,
} from '../../support/flutter_semantics.mjs';

export const DEFAULT_PROBE_LAUNCH_ARGS = ['--no-sandbox', '--ignore-gpu-blocklist'];
export const DEFAULT_PROBE_VIEWPORT = { width: 1280, height: 900 };

export async function createProbeBrowser({ launchOptions = {} } = {}) {
  return chromium.launch({
    headless: true,
    ...launchOptions,
    args: launchOptions.args ?? DEFAULT_PROBE_LAUNCH_ARGS,
  });
}

export async function createProbePage(browser, { pageOptions = {} } = {}) {
  return browser.newPage({
    ...pageOptions,
    viewport: pageOptions.viewport ?? DEFAULT_PROBE_VIEWPORT,
  });
}

export async function openProbePage({ launchOptions = {}, pageOptions = {} } = {}) {
  const browser = await createProbeBrowser({ launchOptions });
  const page = await createProbePage(browser, { pageOptions });
  return { browser, page };
}
