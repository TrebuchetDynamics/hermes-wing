export const APP_URL = process.env.NAVIVOX_APP_URL ?? 'http://127.0.0.1:8767/';

export const INTERACTIVE_SEMANTIC_ROLES = ['button', 'checkbox', 'menuitem', 'switch', 'textbox'];
export const SEMANTIC_BUTTON_SELECTOR = 'flt-semantics[role="button"],flt-semantics[role="menuitem"]';
export const INTERACTIVE_SEMANTIC_SELECTORS = [
  'flt-semantics[role="button"]',
  'flt-semantics[role="checkbox"]',
  'flt-semantics[role="menuitem"]',
  'flt-semantics[role="switch"]',
  'flt-semantics[role="textbox"]',
];

export async function enableFlutterAccessibility(page, { delay = 2000 } = {}) {
  await page
    .waitForSelector('flt-semantics-placeholder, text=Enable accessibility', { timeout: 10000 })
    .catch(() => {});
  await page.evaluate(() => {
    document
      .querySelector('flt-semantics-placeholder')
      ?.dispatchEvent(new MouseEvent('click', { bubbles: true }));
  });
  await page.getByText('Enable accessibility').click({ timeout: 1000 }).catch(() => {});
  await page.waitForSelector('flt-semantics', { timeout: 10000 }).catch(() => {});
  if (delay > 0) await page.waitForTimeout(delay);
}

export async function activateVisibleSemantics(page, { delay = 200 } = {}) {
  await page.evaluate(async (selectors) => {
    for (const selector of selectors) {
      for (const element of document.querySelectorAll(selector)) {
        if (element.getAttribute('aria-label') || element.textContent) {
          element.dispatchEvent(new MouseEvent('click', { bubbles: true }));
        }
      }
    }
    await new Promise((resolve) => setTimeout(resolve, 200));
  }, INTERACTIVE_SEMANTIC_SELECTORS);
  if (delay > 0) await page.waitForTimeout(delay);
}

export async function clickSemantic(page, text, { delay = 1000, selectorTimeout = 8000 } = {}) {
  await page
    .waitForSelector(SEMANTIC_BUTTON_SELECTOR, { timeout: selectorTimeout })
    .catch(() => {});
  await page.evaluate(
    ({ selectors, text }) => {
      for (const selector of selectors) {
        for (const element of document.querySelectorAll(selector)) {
          const content = `${element.textContent || ''}|${element.getAttribute('aria-label') || ''}`;
          if (content.includes(text)) {
            element.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
            element.dispatchEvent(new PointerEvent('pointerup', { bubbles: true }));
            element.dispatchEvent(new MouseEvent('click', { bubbles: true }));
            return;
          }
        }
      }
    },
    { selectors: INTERACTIVE_SEMANTIC_SELECTORS, text },
  );
  if (delay > 0) await page.waitForTimeout(delay);
}

export async function longPressSemantic(page, text, { duration = 1200, delay = 1000 } = {}) {
  await page.evaluate(
    ({ text, duration, selector }) => {
      for (const button of document.querySelectorAll(selector)) {
        const content = `${button.textContent || ''}|${button.getAttribute('aria-label') || ''}`;
        if (content.includes(text)) {
          const rect = button.getBoundingClientRect();
          const clientX = rect.x + rect.width / 2;
          const clientY = rect.y + rect.height / 2;
          button.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, clientX, clientY }));
          return new Promise((resolve) =>
            setTimeout(() => {
              button.dispatchEvent(new PointerEvent('pointerup', { bubbles: true, clientX, clientY }));
              resolve(true);
            }, duration),
          );
        }
      }
      return Promise.resolve(false);
    },
    { text, duration, selector: SEMANTIC_BUTTON_SELECTOR },
  );
  if (delay > 0) await page.waitForTimeout(delay);
}
