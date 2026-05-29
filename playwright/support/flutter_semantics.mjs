export const APP_URL = process.env.NAVIVOX_APP_URL ?? 'http://127.0.0.1:8767/';

export const INTERACTIVE_SEMANTIC_ROLES = [
  'button',
  'menuitem',
  'checkbox',
  'link',
  'switch',
  'tab',
];

export async function enableFlutterAccessibility(page, { delay = 2000 } = {}) {
  await page.evaluate(() => {
    document
      .querySelector('flt-semantics-placeholder')
      ?.dispatchEvent(new MouseEvent('click', { bubbles: true }));
  });
  if (delay > 0) await page.waitForTimeout(delay);
}

export async function activateVisibleSemantics(page, { delay = 200 } = {}) {
  await page.evaluate(async (roles) => {
    for (const role of roles) {
      for (const element of document.querySelectorAll(`flt-semantics[role="${role}"]`)) {
        if (element.getAttribute('aria-label') || element.textContent) {
          element.dispatchEvent(new MouseEvent('click', { bubbles: true }));
        }
      }
    }
    await new Promise((resolve) => setTimeout(resolve, 200));
  }, INTERACTIVE_SEMANTIC_ROLES);
  if (delay > 0) await page.waitForTimeout(delay);
}

export async function clickSemantic(page, text, { delay = 1000, selectorTimeout = 8000 } = {}) {
  await page
    .waitForSelector('flt-semantics[role="button"]', { timeout: selectorTimeout })
    .catch(() => {});
  await page.evaluate(
    ({ roles, text }) => {
      for (const role of roles) {
        for (const element of document.querySelectorAll(`flt-semantics[role="${role}"]`)) {
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
    { roles: INTERACTIVE_SEMANTIC_ROLES, text },
  );
  if (delay > 0) await page.waitForTimeout(delay);
}

export async function longPressSemantic(page, text, { duration = 1200, delay = 1000 } = {}) {
  await page.evaluate(
    ({ text, duration }) => {
      for (const button of document.querySelectorAll('flt-semantics[role="button"]')) {
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
    { text, duration },
  );
  if (delay > 0) await page.waitForTimeout(delay);
}
