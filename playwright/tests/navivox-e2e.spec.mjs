// Navivox Full App Playwright E2E — complete coverage
// Run: node serve_web.mjs && npx playwright test --config=playwright.config.mjs
import { test, expect } from '@playwright/test';
import {
  APP_URL as APP,
  clickSemantic as click,
  enableFlutterAccessibility as a11y,
  longPressSemantic as longPress,
} from '../support/flutter_semantics.mjs';

// ─── 1. Profile Contacts ─────────────────────────────────────────────
test.describe('1. Profile Contacts', () => {
  test.beforeEach(async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
  });
  test('1a seeded profiles + count', async ({page}) => {
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
  test('1d filter chips + click filter + All reset', async ({page}) => {
    await expect(page.locator('flt-semantics[role="checkbox"][aria-label="All"]')).toBeVisible();
    await expect(page.locator('flt-semantics[role="checkbox"][aria-label="Local Gormes"]')).toBeVisible();
    await expect(page.locator('flt-semantics[role="checkbox"][aria-label="Office Gormes"]')).toBeVisible();
    await click(page, 'Office Gormes'); await page.waitForTimeout(1000);
    await expect(page.getByText('1 profile').first()).toBeVisible();
    await expect(page.getByText('Mineru Builder').first()).not.toBeVisible();
    await click(page, 'All'); await page.waitForTimeout(1000);
    await expect(page.getByText('3 profiles').first()).toBeVisible();
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
  });
  test('1e search toggle: type Mineru filters profile list', async ({page}) => {
    // Click search button to activate search mode
    await click(page, 'Search profiles'); await page.waitForTimeout(1000);
    // Type in the search input
    const searchInput = page.locator('input[aria-label="Search Profiles"]');
    await expect(searchInput).toBeVisible();
    await page.locator('input[aria-label="Search Profiles"]').fill('Mineru');
    await page.waitForTimeout(1500);
    // Only Mineru should show (Support and Voice filtered out)
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
    await expect(page.getByText('Support Triage').first()).not.toBeVisible();
    await expect(page.getByText('Voice Agent').first()).not.toBeVisible();
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
  test('2b different profile: Mineru', async ({page}) => {
    await longPress(page, 'Mineru Builder');
    await expect(page.getByText('Display name: Mineru Builder').first()).toBeVisible();
  });
  test('2c dismiss', async ({page}) => {
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
    await page.keyboard.type('hello pw'); await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    await expect(page.getByText('hello pw').first()).toBeVisible();
    await expect(page.getByText('Echo: hello pw').first()).toBeVisible();
  });
  test('3b multiple messages', async ({page}) => {
    await click(page, 'Voice Agent'); await page.waitForTimeout(2000);
    for (const m of ['msg 1','msg 2']) {
      await page.locator('[aria-label="Message Gormes"]').first().click({force:true});
      await page.keyboard.type(m); await page.keyboard.press('Enter');
      await page.waitForTimeout(1500);
    }
    await expect(page.getByText('msg 1').first()).toBeVisible();
    await expect(page.getByText('msg 2').first()).toBeVisible();
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
  test('4b Agents', async ({page}) => {
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
  test('5a Gateways', async ({page}) => {
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
    await expect(page.getByText('Active profile').first()).toBeVisible();
  });
  test('5c Memory degraded', async ({page}) => {
    await page.goto(APP+'#/memory', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.getByText('Memory').first()).toBeVisible();
    await expect(page.getByText('Gormes memory API is unavailable.').first()).toBeVisible();
  });
  test('5d Config unavailable', async ({page}) => {
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

// ─── 6. Settings Lines ────────────────────────────────────────────
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

// ─── 7. Settings Voice Toggles ─────────────────────────────────────
test.describe('7. Voice Toggles', () => {
  test('7a continuous voice switch exists and is checked', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    const sw = page.locator('[aria-label*="Continuous voice"]');
    await expect(sw).toBeVisible();
    await expect(sw).toHaveAttribute('aria-checked', 'true');
  });
  test('7b voice profile switching switch exists', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    const sw = page.locator('[aria-label*="Voice profile switching"]');
    await expect(sw).toBeVisible();
    await expect(sw).toHaveAttribute('aria-checked', 'true');
  });
  test('7c trust server switch exists and is unchecked', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    const sw = page.locator('[aria-label*="Trust Local Gormes"]');
    await expect(sw).toBeVisible();
    await expect(sw).toHaveAttribute('aria-checked', 'false');
  });
});

// ─── 8. Profile Selection (Agents + Chat) ─────────────────────────
test.describe('8. Profile Selection', () => {
  test('8a agents: click Voice Agent selects it', async ({page}) => {
    await page.goto(APP+'#/agents', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Voice Agent'); await page.waitForTimeout(1000);
    // Voice Agent should show active profile state
    await expect(page.getByText('Status: online').first()).toBeVisible();
  });
  test('8b miners -> agents -> select profile cycle works', async ({page}) => {
    await page.goto(APP+'#/agents', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    // Click Mineru
    await click(page, 'Mineru Builder'); await page.waitForTimeout(1000);
    await expect(page.getByText('Voice Agent').first()).toBeVisible();
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
  });
});

// ─── 9. FAB Bottom Sheet ──────────────────────────────────────────
test.describe('9. FAB', () => {
  test.beforeEach(async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
  });
  test('9a options visible', async ({page}) => {
    await click(page, 'Add profile'); await page.waitForTimeout(2000);
    await expect(page.getByText('Create from seed').first()).toBeVisible();
    await expect(page.getByText('New profile').first()).toBeVisible();
    await expect(page.getByText('Add server').first()).toBeVisible();
  });
  test('9b add server navigates', async ({page}) => {
    await click(page, 'Add profile'); await page.waitForTimeout(1500);
    await click(page, 'Add server'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/servers');
  });
});

// ─── 10. Gateway Management ──────────────────────────────────────
test.describe('10. Gateway', () => {
  test('10a manage modal shows details', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Manage Local Gormes'); await page.waitForTimeout(2000);
    await expect(page.getByText('Manage gateway').first()).toBeVisible();
    await expect(page.getByText('Profiles on this gateway').first()).toBeVisible();
    await expect(page.getByText('Disconnect current session').first()).toBeVisible();
    // Should show the profiles on this gateway
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
    await expect(page.getByText('Voice Agent').first()).toBeVisible();
  });
  test('10b dismiss with Escape', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Manage Local Gormes'); await page.waitForTimeout(1500);
    await page.keyboard.press('Escape'); await page.waitForTimeout(1000);
    await expect(page.getByText('Manage gateway').first()).not.toBeVisible();
  });
  test('10c register gateway opens bottom sheet', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    // Click the FAB via mouse coordinates
    const btn = await page.evaluate(() => {
      const sems = document.querySelectorAll('flt-semantics[role="button"]');
      for (const e of sems) {
        if ((e.textContent||'').includes('Register gateway')) {
          const r = e.getBoundingClientRect();
          return {x: r.x + r.width/2, y: r.y + r.height/2};
        }
      }
      return null;
    });
    if (btn) {
      await page.mouse.click(btn.x, btn.y);
      await page.waitForTimeout(2000);
    }
    // Register gateway opens a bottom sheet with instructions and test button
    await expect(page.getByText('connect-info --json').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Test connection').first()).toBeVisible({timeout:5000});
  });
});

// ─── 11. Mobile Viewport ─────────────────────────────────────────
test.describe('11. Mobile', () => {
  test('11a bottom tab nav visible with 5 tabs', async ({page}) => {
    await page.setViewportSize({width:390,height:844});
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.locator('flt-semantics[role="tablist"]')).toBeVisible();
    await expect(page.locator('flt-semantics[role="tab"]')).toHaveCount(5);
  });
  test('11b desktop has no tablist', async ({page}) => {
    await page.setViewportSize({width:1280,height:900});
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.locator('flt-semantics[role="tablist"]')).toHaveCount(0);
  });
  test('11c mobile tab click navigates', async ({page}) => {
    await page.setViewportSize({width:390,height:844});
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    // Click Memory tab (index 2) via mouse coords
    const tabX = await page.evaluate(() => {
      const tabs = document.querySelectorAll('flt-semantics[role="tab"]');
      if (tabs.length >= 3) {
        const r = tabs[2].getBoundingClientRect();
        return r.x + r.width/2;
      }
      return null;
    });
    if (tabX) {
      await page.mouse.click(tabX, 800);
      await page.waitForTimeout(2000);
      expect(page.url()).toContain('/memory');
    }
  });
});

// ─── 12. Back Navigation ─────────────────────────────────────────
test.describe('12. Back', () => {
  test('12a chat → back → profiles', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Support Triage'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/chats/office/support');
    await page.goBack(); await page.waitForTimeout(2000); await a11y(page);
    expect(page.url()).toContain('/chats');
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
  });
});

// ─── 13. Screenshots ─────────────────────────────────────────────
test.describe('13. Screenshots', () => {
  test('13a profiles', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/profiles.png',fullPage:true});
  });
  test('13b chat', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Support Triage'); await page.waitForTimeout(1500);
    await page.locator('[aria-label="Message Gormes"]').first().click({force:true});
    await page.keyboard.type('e2e'); await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    await page.screenshot({path:'playwright/screenshots/chat.png',fullPage:true});
  });
  test('13c servers', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/servers.png',fullPage:true});
  });
  test('13d agents', async ({page}) => {
    await page.goto(APP+'#/agents', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/agents.png',fullPage:true});
  });
  test('13e memory', async ({page}) => {
    await page.goto(APP+'#/memory', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/memory.png',fullPage:true});
  });
  test('13f config', async ({page}) => {
    await page.goto(APP+'#/config', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/config.png',fullPage:true});
  });
  test('13g settings', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/settings.png',fullPage:true});
  });
  test('13h profile detail', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await longPress(page, 'Support Triage');
    await page.screenshot({path:'playwright/screenshots/profile-detail.png',fullPage:true});
    await page.keyboard.press('Escape');
  });
  test('13i FAB sheet', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Add profile');
    await page.screenshot({path:'playwright/screenshots/fab-sheet.png',fullPage:true});
  });
  test('13j gateway modal', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Manage Local Gormes');
    await page.screenshot({path:'playwright/screenshots/gateway-modal.png',fullPage:true});
    await page.keyboard.press('Escape');
  });
  test('13k mobile', async ({page}) => {
    await page.setViewportSize({width:390,height:844});
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/mobile.png',fullPage:true});
  });
});

// ─── 14. Chat Feature Details ─────────────────────────────────────
test.describe('14. Chat Features', () => {
  test.beforeEach(async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    // Enter chat with Support Triage
    const btn = await page.evaluate(() => {
      const s = document.querySelectorAll('flt-semantics[role="button"]');
      for (const e of s) {
        if ((e.textContent||'').includes('Support Triage')) {
          const r = e.getBoundingClientRect();
          return {x: r.x + r.width/2, y: r.y + r.height/2};
        }
      }
      return null;
    });
    if (btn) {
      await page.mouse.click(btn.x, btn.y);
      await page.waitForTimeout(2000);
    }
  });
  test('14a chat voice banner: trust server button visible', async ({page}) => {
    await expect(page.locator('[aria-label*="Continuous voice unavailable"]').first()).toBeVisible({timeout:5000});
    await expect(page.locator('[aria-label*="trust office"]').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Trust server').first()).toBeVisible({timeout:5000});
  });
  test('14b chat info sheet opens from toolbar', async ({page}) => {
    await click(page, 'Chat info'); await page.waitForTimeout(1500);
    await expect(page.getByText('Profile').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Server').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Status').first()).toBeVisible({timeout:5000});
    await page.keyboard.press('Escape'); await page.waitForTimeout(1000);
  });
  test('14c composer buttons: emoji, attach, voice, send', async ({page}) => {
    await expect(page.getByText('Emoji').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Attach').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Voice unavailable').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Start a conversation').first()).toBeVisible({timeout:5000});
  });
  test('14d attach sheet shows options', async ({page}) => {
    await click(page, 'Attach'); await page.waitForTimeout(1500);
    await expect(page.getByText('Upload file').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Photo or video').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Workspace file').first()).toBeVisible({timeout:5000});
    await page.keyboard.press('Escape'); await page.waitForTimeout(1000);
  });
});

// ─── 15. FAB Create from Seed ────────────────────────────────────
test.describe('15. FAB Create from Seed', () => {
  test.beforeEach(async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
  });
  test('15a create from seed sheet content', async ({page}) => {
    await click(page, 'Add profile'); await page.waitForTimeout(1500);
    await expect(page.getByText('Create from seed').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Ask Gormes to draft a profile').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('New profile').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Server-validated profile creation').first()).toBeVisible({timeout:5000});
  });
  test('15b create from seed opens seed sheet with input field', async ({page}) => {
    await click(page, 'Add profile'); await page.waitForTimeout(1500);
    await click(page, 'Create from seed'); await page.waitForTimeout(1500);
    await expect(page.getByText('Gormes drafts profile config').first()).toBeVisible({timeout:5000});
    // Verify seed input exists
    const seedInput = page.locator('[aria-label*="seed"]');
    await expect(seedInput).toBeVisible({timeout:5000});
    await expect(page.getByText('Create from seed').first()).toBeVisible({timeout:5000});
    await page.keyboard.press('Escape'); await page.waitForTimeout(1000);
  });
});

// ─── 16. Config Screen Scopes ────────────────────────────────────
test.describe('16. Config Screen', () => {
  test('16a config scope card shows server and profile', async ({page}) => {
    await page.goto(APP+'#/config', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.getByText('Profile config scope').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('No config available').first()).toBeVisible({timeout:5000});
  });
});

// ─── 17. Additional Regression Coverage ──────────────────────────
test.describe('17. Additional Regression Coverage', () => {
  test('17a office profile filter opens support chat with office scope', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Office Gormes'); await page.waitForTimeout(1000);
    await expect(page.getByText('1 profile').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Support Triage').first()).toBeVisible({timeout:5000});
    await click(page, 'Support Triage'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/chats/office/support');
    await expect(page.getByText('Start a conversation').first()).toBeVisible({timeout:5000});
    await expect(page.locator('[aria-label*="trust office"]').first()).toBeVisible({timeout:5000});
  });

  test('17b settings trust switch toggles with accessible checked state', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    const trustSwitch = page.locator('[aria-label*="Trust Local Gormes"]');
    await expect(trustSwitch).toBeVisible({timeout:5000});
    await expect(trustSwitch).toHaveAttribute('aria-checked', 'false');
    await trustSwitch.click(); await page.waitForTimeout(1000);
    await expect(trustSwitch).toHaveAttribute('aria-checked', 'true');
  });

  test('17c config screen shows scoped fallback boundaries', async ({page}) => {
    await page.goto(APP+'#/config', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.getByText('Server: Local Gormes').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Profile: Mineru Builder').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Profile ID: mineru').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Voice profile').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('Text chat remains available when voice providers are unavailable.').first()).toBeVisible({timeout:5000});
    await expect(page.getByText('No config available').first()).toBeVisible({timeout:5000});
  });

  test('17d gateway cards expose profile and auth chips to accessibility tree', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.locator('flt-semantics[role="checkbox"][aria-label="2 profiles"]')).toBeVisible({timeout:5000});
    await expect(page.locator('flt-semantics[role="checkbox"][aria-label="1 profile"]')).toBeVisible({timeout:5000});
    await expect(page.locator('flt-semantics[role="checkbox"][aria-label="1 auth"]')).toBeVisible({timeout:5000});
  });
});
