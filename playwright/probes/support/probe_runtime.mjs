import {
  DEFAULT_BROWSER_LAUNCH_ARGS,
  DEFAULT_BROWSER_VIEWPORT,
  createBrowser,
  createBrowserPage,
  createBrowserSession,
} from '../../support/browser_session.mjs';

export {
  APP_URL,
  activateVisibleSemantics,
  clickSemantic,
  enableFlutterAccessibility,
  longPressSemantic,
} from '../../support/flutter_semantics.mjs';

export const DEFAULT_PROBE_LAUNCH_ARGS = DEFAULT_BROWSER_LAUNCH_ARGS;
export const DEFAULT_PROBE_VIEWPORT = DEFAULT_BROWSER_VIEWPORT;

export async function createProbeBrowser({ launchOptions = {} } = {}) {
  return createBrowser({ launchOptions, defaultLaunchArgs: DEFAULT_PROBE_LAUNCH_ARGS });
}

export async function createProbePage(browser, { pageOptions = {} } = {}) {
  return createBrowserPage(browser, { pageOptions, defaultViewport: DEFAULT_PROBE_VIEWPORT });
}

export async function openProbePage({ launchOptions = {}, pageOptions = {} } = {}) {
  return createBrowserSession({
    launchOptions,
    pageOptions,
    defaultLaunchArgs: DEFAULT_PROBE_LAUNCH_ARGS,
    defaultViewport: DEFAULT_PROBE_VIEWPORT,
  });
}
