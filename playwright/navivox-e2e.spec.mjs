// Navivox Full App Playwright E2E — all screens, all features
// Run: node serve_web.mjs && npx playwright test --config=playwright.config.mjs
import { test, expect } from '@playwright/test';
const APP = 'http://127.0.0.1:8767/';

async function a11y(p) {
  await p.evaluate(() => document.querySelector('flt-semantics-placeholder')?.dispatchEvent(new MouseEvent('click', {bubbles:true})));
  await p.waitForTimeout(2000);
}
async function click(p, t) {
  await p.waitForSelector('flt-semantics[role="button"]', {timeout:8000}).catch(()=>{});
  await p.evaluate((text) => {
    for (const role of ['button','menuitem','checkbox','link','switch']) {
      for (const e of document.querySelectorAll(`flt-semantics[role="${role}"]`)) {
        if (((e.textContent||'')+'|'+(e.getAttribute('aria-label')||'')).includes(text)) {
          e.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true}));
          e.dispatchEvent(new PointerEvent('pointerup',{bubbles:true}));
          e.dispatchEvent(new MouseEvent('click',{bubbles:true}));
          return;
        }
      }
    }
  }, t);
  await p.waitForTimeout(1000);
}
async function longPress(p, t) {
  await p.evaluate((text) => {
    for (const b of document.querySelectorAll('flt-semantics[role="button"]')) {
      if (((b.textContent||'')+'|'+(b.getAttribute('aria-label')||'')).includes(text)) {
        const r = b.getBoundingClientRect();
        b.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true, clientX:r.x+r.width/2, clientY:r.y+r.height/2}));
        return new Promise(resolve => setTimeout(() => { b.dispatchEvent(new PointerEvent('pointerup',{bubbles:true, clientX:r.x+r.width/2, clientY:r.y+r.height/2})); resolve(true); }, 1200));
      }
    }
    return Promise.resolve(false);
  }, t);
  await p.waitForTimeout(1000);
}

// ─── 1. Profile Contacts ─────────────────────────────────────────────
test.describe('1. Profile Contacts', () => {
  test.beforeEach(async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
  });
  test('1a seeded profiles present', async ({page}) => {
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
    await expect(page.getByText('Support Triage').first()).toBeVisible();
    await expect(page.getByText('Voice Agent').first()).toBeVisible();
    await expect(page.getByText('3 profiles').first()).toBeVisible();
    await expect(page.getByText('Navivox').first()).toBeVisible();
  });
  test('1b previews + health + attention', async ({page}) => {
    await expect(page.getByText('Ready to work on mineru').first()).toBeVisible();
    await expect(page.getByText('Waiting for auth').first()).toBeVisible();
    await expect(page.getByText('Voice ready').first()).toBeVisible();
    await expect(page.getByText('auth required').first()).toBeVisible();
    await expect(page.getByText('1 attention item').first()).toBeVisible();
  });
  test('1c UI: search, menu, FAB', async ({page}) => {
    await expect(page.getByText('Search profiles').first()).toBeVisible();
    await expect(page.getByText('Open profile list menu').first()).toBeVisible();
    await expect(page.getByText('Add profile').first()).toBeVisible();
  });
  test('1d filter chips', async ({page}) => {
    await expect(page.locator('flt-semantics[role="checkbox"][aria-label="All"]')).toBeVisible();
    await expect(page.locator('flt-semantics[role="checkbox"][aria-label="Local Gormes"]')).toBeVisible();
    await expect(page.locator('flt-semantics[role="checkbox"][aria-label="Office Gormes"]')).toBeVisible();
  });
  test('1e filter click narrows + All resets', async ({page}) => {
    await click(page, 'Office Gormes'); await page.waitForTimeout(1000);
    await expect(page.getByText('Support Triage').first()).toBeVisible();
    await expect(page.getByText('1 profile').first()).toBeVisible();
    await click(page, 'All'); await page.waitForTimeout(1000);
    await expect(page.getByText('3 profiles').first()).toBeVisible();
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
  });
});

// ─── 2. Profile Detail (Long Press) ────────────────────────────────
test.describe('2. Profile Detail', () => {
  test.beforeEach(async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
  });
  test('2a diagnostics + identity + channels', async ({page}) => {
    await longPress(page, 'Support Triage');
    await expect(page.getByText('Profile diagnostics').first()).toBeVisible();
    await expect(page.getByText('Health: auth required').first()).toBeVisible();
    await expect(page.getByText('Display name: Support Triage').first()).toBeVisible();
    await expect(page.getByText('Profile ID: support').first()).toBeVisible();
    await expect(page.getByText('Connected channels').first()).toBeVisible();
  });
  test('2b different profiles have correct data', async ({page}) => {
    await longPress(page, 'Mineru Builder');
    await expect(page.getByText('Display name: Mineru Builder').first()).toBeVisible();
  });
  test('2c dismiss with Escape', async ({page}) => {
    await longPress(page, 'Support Triage');
    await page.keyboard.press('Escape'); await page.waitForTimeout(1000);
    await expect(page.getByText('Profile diagnostics').first()).not.toBeVisible();
  });
});

// ─── 3. Chat & Text Entry ──────────────────────────────────────────
test.describe('3. Chat & Text', () => {
  test.beforeEach(async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
  });
  test('3a type + send + echo', async ({page}) => {
    await click(page, 'Support Triage'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/chats/office/support');
    await page.locator('[aria-label="Message Gormes"]').first().click({force:true});
    await page.keyboard.type('hello playwright'); await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    await expect(page.getByText('hello playwright').first()).toBeVisible();
    await expect(page.getByText('Echo: hello playwright').first()).toBeVisible();
  });
  test('3b send multiple messages', async ({page}) => {
    await click(page, 'Voice Agent'); await page.waitForTimeout(2000);
    for (const msg of ['first msg', 'second msg']) {
      await page.locator('[aria-label="Message Gormes"]').first().click({force:true});
      await page.keyboard.type(msg); await page.keyboard.press('Enter');
      await page.waitForTimeout(1500);
    }
    await expect(page.getByText('first msg').first()).toBeVisible();
    await expect(page.getByText('second msg').first()).toBeVisible();
  });
});

// ─── 4. Menu → Screen Navigation ───────────────────────────────────
test.describe('4. Menu → Screens', () => {
  test.beforeEach(async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Open profile list menu'); await page.waitForTimeout(1500);
  });
  test('4a Gateways', async ({page}) => {
    await click(page, 'Manage gateways'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/servers');
    await expect(page.getByText('Gateways').first()).toBeVisible({timeout:5000});
  });
  test('4b Profiles', async ({page}) => {
    await click(page, 'Manage profiles'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/agents');
    await expect(page.getByText('Profiles').first()).toBeVisible({timeout:5000});
  });
  test('4c Memory', async ({page}) => {
    await click(page, 'Memory'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/memory');
  });
  test('4d Config', async ({page}) => {
    await click(page, 'Config'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/config');
  });
  test('4e Settings', async ({page}) => {
    await click(page, 'Settings'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/settings');
    await expect(page.getByText('Settings').first()).toBeVisible({timeout:5000});
  });
});

// ─── 5. Screen Content ──────────────────────────────────────────────
test.describe('5. Screen Content', () => {
  test('5a Gateways list', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.getByText('Gateways').first()).toBeVisible();
    await expect(page.getByText('Local Gormes').first()).toBeVisible();
    await expect(page.getByText('Office Gormes').first()).toBeVisible();
    await expect(page.getByText('Register gateway').first()).toBeVisible();
  });
  test('5b Agents details', async ({page}) => {
    await page.goto(APP+'#/agents', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
    await expect(page.getByText('Voice Agent').first()).toBeVisible();
    await expect(page.getByText('Status: online').first()).toBeVisible();
    await expect(page.getByText('Refresh profiles').first()).toBeVisible();
  });
  test('5c Memory degraded', async ({page}) => {
    await page.goto(APP+'#/memory', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.getByText('Memory').first()).toBeVisible();
    await expect(page.getByText('Gormes memory API is unavailable.').first()).toBeVisible();
  });
  test('5d Config scope + unavailable', async ({page}) => {
    await page.goto(APP+'#/config', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.getByText('Config').first()).toBeVisible();
    await expect(page.getByText('Local Gormes').first()).toBeVisible();
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
    await expect(page.getByText('No config available').first()).toBeVisible();
  });
  test('5e Settings overview', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.getByText('Voice settings').first()).toBeVisible();
    await expect(page.getByText('Global app settings').first()).toBeVisible();
    await expect(page.getByText('navi').first()).toBeVisible();
    await expect(page.getByText('2 Gormes gateways').first()).toBeVisible();
    await expect(page.getByText('3 profile contacts').first()).toBeVisible();
  });
});

// ─── 6. Settings Lines → Navigation ─────────────────────────────────
test.describe('6. Settings Lines', () => {
  test('6a manage gateways', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Manage gateways'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/servers');
  });
  test('6b manage profiles', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Manage profile contacts'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/agents');
  });
  test('6c active gateway', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Active Gormes gateway'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/servers');
  });
  test('6d active profile', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Active profile contact'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/agents');
  });
  test('6e command word sheet', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Command word'); await page.waitForTimeout(2000);
    await expect(page.getByText('Say "navi" before local commands').first()).toBeVisible({timeout:5000});
  });
});

// ─── 7. FAB Bottom Sheet ───────────────────────────────────────────
test.describe('7. FAB Bottom Sheet', () => {
  test.beforeEach(async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
  });
  test('7a options visible', async ({page}) => {
    await click(page, 'Add profile'); await page.waitForTimeout(2000);
    await expect(page.getByText('Create from seed').first()).toBeVisible();
    await expect(page.getByText('New profile').first()).toBeVisible();
    await expect(page.getByText('Add server').first()).toBeVisible();
  });
  test('7b add server navigates', async ({page}) => {
    await click(page, 'Add profile'); await page.waitForTimeout(1500);
    await click(page, 'Add server'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/servers');
  });
});

// ─── 8. Gateway Management Modal ──────────────────────────────────
test.describe('8. Gateway Management', () => {
  test('8a manage gateways modal shows detail', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Manage Local Gormes'); await page.waitForTimeout(2000);
    await expect(page.getByText('Manage gateway').first()).toBeVisible();
    await expect(page.getByText('Local Gormes').first()).toBeVisible();
    await expect(page.getByText('Profiles on this gateway').first()).toBeVisible();
    await expect(page.getByText('Disconnect current session').first()).toBeVisible();
  });
  test('8b dismiss gateway modal', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Manage Local Gormes'); await page.waitForTimeout(1500);
    await page.keyboard.press('Escape'); await page.waitForTimeout(1000);
    await expect(page.getByText('Manage gateway').first()).not.toBeVisible();
  });
});

// ─── 9. Mobile Viewport ─────────────────────────────────────────────
test.describe('9. Mobile Viewport', () => {
  test('9a mobile bottom tab navigation visible', async ({page}) => {
    await page.setViewportSize({width:390,height:844});
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    // Mobile NavigationBar renders as tablist role
    const tablist = page.locator('flt-semantics[role="tablist"]');
    await expect(tablist).toBeVisible();
    // Should have 5 tabs (bottom nav destinations: Chats, Agents, Memory, Settings, More)
    const tabs = page.locator('flt-semantics[role="tab"]');
    await expect(tabs).toHaveCount(5);
  });
  test('9b desktop has no tablist', async ({page}) => {
    await page.setViewportSize({width:1280,height:900});
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    // On desktop, there should be no mobile tablist
    const tablist = page.locator('flt-semantics[role="tablist"]');
    await expect(tablist).toHaveCount(0);
  });
});

// ─── 10. Back Navigation ──────────────────────────────────────────
test.describe('10. Back Navigation', () => {
  test('10a chat back to profiles', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Support Triage'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/chats/office/support');
    await page.goBack(); await page.waitForTimeout(2000); await a11y(page);
    expect(page.url()).toContain('/chats');
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
  });
});

// ─── 11. Screenshots ─────────────────────────────────────────────
test.describe('11. Screenshots', () => {
  test('11a profiles', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/profiles.png', fullPage:true});
  });
  test('11b chat with typed message', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Support Triage'); await page.waitForTimeout(1500);
    await page.locator('[aria-label="Message Gormes"]').first().click({force:true});
    await page.keyboard.type('e2e test message'); await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    await page.screenshot({path:'playwright/screenshots/chat.png', fullPage:true});
  });
  test('11c servers', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/servers.png', fullPage:true});
  });
  test('11d agents', async ({page}) => {
    await page.goto(APP+'#/agents', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/agents.png', fullPage:true});
  });
  test('11e memory', async ({page}) => {
    await page.goto(APP+'#/memory', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/memory.png', fullPage:true});
  });
  test('11f config', async ({page}) => {
    await page.goto(APP+'#/config', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/config.png', fullPage:true});
  });
  test('11g settings', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/settings.png', fullPage:true});
  });
  test('11h profile detail', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await longPress(page, 'Support Triage');
    await page.screenshot({path:'playwright/screenshots/profile-detail.png', fullPage:true});
    await page.keyboard.press('Escape');
  });
  test('11i FAB sheet', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Add profile');
    await page.screenshot({path:'playwright/screenshots/fab-sheet.png', fullPage:true});
  });
  test('11j gateway modal', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Manage Local Gormes');
    await page.screenshot({path:'playwright/screenshots/gateway-modal.png', fullPage:true});
    await page.keyboard.press('Escape');
  });
  test('11k mobile layout', async ({page}) => {
    await page.setViewportSize({width:390,height:844});
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/mobile.png', fullPage:true});
  });
});