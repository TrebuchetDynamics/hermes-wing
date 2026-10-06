import { expect } from '@playwright/test';

// Read-only focus observation. All user actions in these journeys are keys;
// Flutter's initialization/accessibility hooks are confined to bootstrap.
export async function focusedNode(page) {
  return page.evaluate(() => {
    let node = document.activeElement;
    while (node?.shadowRoot?.activeElement) node = node.shadowRoot.activeElement;
    const rect = node?.getBoundingClientRect();
    return {
      documentHasFocus: document.hasFocus(),
      tag: node?.tagName,
      role: node?.getAttribute('role') ?? (['INPUT', 'TEXTAREA'].includes(node?.tagName) ? 'textbox' : null),
      name: node?.matches('flt-semantics,input,textarea')
        ? (node.getAttribute('aria-label') ?? node.textContent ?? '').replace(/\s+/g, ' ').trim()
        : '',
      disabled: node?.getAttribute('aria-disabled'),
      tabIndex: node?.tabIndex,
      rect: rect ? { x: rect.x, y: rect.y, width: rect.width, height: rect.height } : null,
    };
  });
}

export function keyboardActor(page, testInfo, trace) {
  const control = (role, name) => page.getByRole(role, { name, exact: true });
  const matchesFocus = locator => locator.evaluate(node => {
    let active = document.activeElement;
    while (active?.shadowRoot?.activeElement) active = active.shadowRoot.activeElement;
    return document.hasFocus() && (node === active || node.contains(active));
  });
  const record = async action => trace.push({ action, focused: await focusedNode(page) });
  const press = async key => {
    expect(['Tab', 'Shift+Tab', 'Enter', 'Space']).toContain(key);
    await page.keyboard.press(key);
    // Allow Flutter's native editor and rendered semantics to settle after keys.
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    await record(key);
  };
  const assertFocus = async (role, name) => {
    const locator = control(role, name);
    await expect(locator).toHaveCount(1);
    await expect.poll(() => matchesFocus(locator)).toBe(true);
    await expect(locator).toBeVisible();
    const current = await focusedNode(page);
    expect(current.role).toBe(role);
    expect(current.name).toBe(name);
    expect(current.disabled).not.toBe('true');
    expect(current.rect.width).toBeGreaterThan(0);
    expect(current.rect.height).toBeGreaterThan(0);
    const viewport = page.viewportSize();
    expect(current.rect.x).toBeGreaterThanOrEqual(0);
    expect(current.rect.y).toBeGreaterThanOrEqual(0);
    expect(current.rect.x + current.rect.width).toBeLessThanOrEqual(viewport.width);
    expect(current.rect.y + current.rect.height).toBeLessThanOrEqual(viewport.height);
    trace.push({ assertion: 'exact named focus in viewport', role, name, focused: current });
    return locator;
  };
  const reach = async (role, name, direction = 'Tab') => {
    const locator = control(role, name);
    await expect(locator).toHaveCount(1);
    for (let step = 0; step < 32; step++) {
      if (await matchesFocus(locator)) return assertFocus(role, name);
      await press(direction);
    }
    throw new Error(`Keyboard could not reach ${role} ${name} within 32 ${direction} keys: ${JSON.stringify(trace)}`);
  };
  const type = async (name, value) => {
    await assertFocus('textbox', name);
    await page.keyboard.type(value);
    await record(`type ${JSON.stringify(value)}`);
    await expect(control('textbox', name)).toHaveValue(value);
  };
  const visibleFocus = async (role, name, slug, direction = 'Tab') => {
    const locator = await assertFocus(role, name);
    const bounds = await locator.boundingBox();
    const viewport = page.viewportSize();
    const clip = { x: Math.max(0, bounds.x - 4), y: Math.max(0, bounds.y - 4),
      width: Math.min(viewport.width, bounds.x + bounds.width + 4) - Math.max(0, bounds.x - 4),
      height: Math.min(viewport.height, bounds.y + bounds.height + 4) - Math.max(0, bounds.y - 4) };
    const focused = await page.screenshot({ clip, animations: 'disabled' });
    let steps = 0;
    do {
      await press(direction);
      steps++;
    } while (await matchesFocus(locator) && steps < 4);
    expect(await matchesFocus(locator)).toBe(false);
    const unfocused = await page.screenshot({ clip, animations: 'disabled' });
    // The compiled renderer, not just its invisible semantic overlay, must change.
    expect(focused.equals(unfocused), `${name} needs a visible keyboard focus change`).toBe(false);
    await testInfo.attach(`${slug}-focused.png`, { body: focused, contentType: 'image/png' });
    await testInfo.attach(`${slug}-unfocused.png`, { body: unfocused, contentType: 'image/png' });
    for (let step = 0; step < steps; step++) await press(direction === 'Tab' ? 'Shift+Tab' : 'Tab');
    await assertFocus(role, name);
    trace.push({ assertion: 'rendered focus pixels differ; keyboard escape and inverse return', direction, steps, role, name });
  };
  return { control, press, reach, assertFocus, type, visibleFocus, record };
}

export function inventoryReceipts(page, paths) {
  const requests = [], readbacks = [], pending = [], errors = [];
  page.on('pageerror', error => errors.push(error.message));
  page.on('request', request => {
    const url = new URL(request.url());
    if (url.pathname.startsWith('/api/') || url.pathname.startsWith('/v1/')) {
      requests.push({ method: request.method(), path: url.pathname,
        query: Object.fromEntries(url.searchParams), profile: url.searchParams.get('profile') });
    }
  });
  page.on('response', response => {
    const url = new URL(response.url());
    if (paths.includes(url.pathname)) pending.push(response.json().then(body => {
      readbacks.push({ path: url.pathname, query: Object.fromEntries(url.searchParams),
        profile: url.searchParams.get('profile'), status: response.status(), body });
    }));
  });
  return { requests, readbacks, errors, settle: () => Promise.all(pending) };
}

export async function scopedInventory(page, operations) {
  await page.route(url => url.pathname === '/v1/capabilities', async route => {
    const response = await route.fetch();
    const catalog = await response.json();
    catalog.profile_context = { type: 'query', name: 'profile', required: true, default_profile_id: 'default' };
    for (const operation of operations) catalog.endpoints[operation].profile_scoped = true;
    await route.fulfill({ response, json: catalog });
  });
}
