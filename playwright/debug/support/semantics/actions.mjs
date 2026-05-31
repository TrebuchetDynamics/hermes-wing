import {
  NATIVE_INPUT_VALUE_EVENT_TYPES,
  SEMANTIC_BUTTON_SELECTOR,
  SEMANTIC_CLICK_EVENT_TYPES,
} from './contracts.mjs';

export async function clickSemanticButtonContaining(page, text, eventOptions = {}) {
  return page.evaluate(({ selector, text, eventOptions, clickEventTypes }) => {
    const buttons = document.querySelectorAll(selector);
    for (const button of buttons) {
      if ((button.textContent || '').includes(text)) {
        const [pointerDown, pointerUp, click] = clickEventTypes;
        button.dispatchEvent(new PointerEvent(pointerDown, { bubbles: true, ...eventOptions }));
        button.dispatchEvent(new PointerEvent(pointerUp, { bubbles: true, ...eventOptions }));
        button.dispatchEvent(new MouseEvent(click, { bubbles: true, ...eventOptions }));
        return true;
      }
    }
    return false;
  }, { selector: SEMANTIC_BUTTON_SELECTOR, text, eventOptions, clickEventTypes: SEMANTIC_CLICK_EVENT_TYPES });
}

export async function setNativeInputValue(page, selector, value) {
  return page.evaluate(({ selector, value, eventTypes }) => {
    const input = document.querySelector(selector);
    if (!input) return false;

    const setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value')?.set;
    setter?.call(input, value);
    for (const eventType of eventTypes) {
      input.dispatchEvent(new Event(eventType, { bubbles: true }));
    }
    return true;
  }, { selector, value, eventTypes: NATIVE_INPUT_VALUE_EVENT_TYPES });
}
