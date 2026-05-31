import test from 'node:test';
import assert from 'node:assert/strict';

import { clickSemanticButtonContaining, setNativeInputValue } from '../semantic_actions.mjs';
import { NATIVE_INPUT_VALUE_EVENT_TYPES, SEMANTIC_CLICK_EVENT_TYPES } from './contracts.mjs';

function withGlobals(globals, run) {
  const previous = new Map(Object.keys(globals).map(key => [key, globalThis[key]]));
  Object.assign(globalThis, globals);
  try {
    return run();
  } finally {
    for (const [key, value] of previous) {
      if (value === undefined) delete globalThis[key];
      else globalThis[key] = value;
    }
  }
}

function fakePage() {
  return {
    evaluate(callback, arg) {
      return callback(arg);
    },
  };
}

test('clickSemanticButtonContaining dispatches pointer and mouse events on the matching semantics button', async () => {
  const events = [];
  const matchingButton = {
    textContent: 'Support Triage',
    dispatchEvent(event) {
      events.push(event.type);
    },
  };

  const clicked = await withGlobals({
    document: { querySelectorAll: () => [{ textContent: 'Other', dispatchEvent() {} }, matchingButton] },
    PointerEvent: class PointerEvent { constructor(type) { this.type = type; } },
    MouseEvent: class MouseEvent { constructor(type) { this.type = type; } },
  }, () => clickSemanticButtonContaining(fakePage(), 'Support Triage'));

  assert.equal(clicked, true);
  assert.deepEqual(events, SEMANTIC_CLICK_EVENT_TYPES);
});

test('setNativeInputValue uses the native input setter and dispatches input/change events', async () => {
  const events = [];
  class FakeInput {
    set value(next) { this._value = next; }
    get value() { return this._value; }
    dispatchEvent(event) { events.push(event.type); }
  }
  const input = new FakeInput();

  const fakeWindow = { HTMLInputElement: FakeInput };
  const updated = await withGlobals({
    document: { querySelector: () => input },
    window: fakeWindow,
    HTMLInputElement: FakeInput,
    Event: class Event { constructor(type) { this.type = type; } },
  }, () => setNativeInputValue(fakePage(), 'input[aria-label="Gateway address field"]', '10.0.0.1'));

  assert.equal(updated, true);
  assert.equal(input.value, '10.0.0.1');
  assert.deepEqual(events, NATIVE_INPUT_VALUE_EVENT_TYPES);
});
