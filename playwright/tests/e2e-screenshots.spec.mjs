// playwright/tests/e2e-screenshots.spec.mjs — 2026-05-21 CST
// Tests: 12a-k (back nav), 14e (register modal), 14f (voice gateway),
// 14g (gateway setup), plus mobile transcript slices 11h-k
//
import { test, expect } from '@playwright/test';
import {
  APP_URL as APP,
  activateVisibleSemantics as a11y,
  clickSemantic,
} from '../support/flutter_semantics.mjs';

async function click(page, text) {
  await page.waitForTimeout(800);
  await clickSemantic(page, text, { delay: 0, selectorTimeout: 1 });
}

test.beforeEach(async ({page}) => {
  await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000);
  await a11y(page);
});

// ─── 12. Back Nav ─────────────────────────────────────────────────
test.describe('12. Back', () => {
  test('12a chat back navigates to profile list', async ({page}) => {
    await page.goto(APP+'#/chats', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Open profile list menu');
    await page.waitForTimeout(1500);
    await expect(page.getByText('Support Triage').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12a-chat-back.png',fullPage:true});
  });
  test('12b server back navigates to server list', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Open server list menu');
    await page.waitForTimeout(1500);
    await expect(page.getByText('All gateways').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12b-server-back.png',fullPage:true});
  });
  test('12c agents back navigates to agent list', async ({page}) => {
    await page.goto(APP+'#/agents', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Open profile list menu');
    await page.waitForTimeout(1500);
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12c-agents-back.png',fullPage:true});
  });
  test('12d memory back navigates to memory dashboard', async ({page}) => {
    await page.goto(APP+'#/memory', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Open memory menu');
    await page.waitForTimeout(1500);
    await expect(page.getByText('Memory Dashboard').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12d-memory-back.png',fullPage:true});
  });
  test('12e config back navigates to config screen', async ({page}) => {
    await page.goto(APP+'#/config', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Open config menu');
    await page.waitForTimeout(1500);
    await expect(page.getByText('Config Edit').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12e-config-back.png',fullPage:true});
  });
  test('12f settings back navigates to settings screen', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Open settings menu');
    await page.waitForTimeout(1500);
    await expect(page.getByText('Settings').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12f-settings-back.png',fullPage:true});
  });
  test('12g gateway detail back navigates to server list', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Manage local servers');
    await page.waitForTimeout(1500);
    const locator = page.locator('flt-semantics[role="button"]:has-text("Manage")');
    await locator.first().click();
    await page.waitForTimeout(1500);
    await expect(page.getByText('Server detail').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12g-gateway-detail-back.png',fullPage:true});
  });
  test('12h profile gateways back navigates to gateway admin', async ({page}) => {
    await page.goto(APP+'#/agents', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Gemir Triage'); // long press to trigger detail
    await page.waitForTimeout(1500);
    await click(page, 'Manage agents');
    await page.waitForTimeout(1500);
    await expect(page.getByText('Profile detail').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12h-profile-gateways-back.png',fullPage:true});
  });
  test('12i chat: forward message back navigates', async ({page}) => {
    await page.goto(APP+'#/chats', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Voice Agent');
    await page.waitForTimeout(1500);
    await click(page, 'More options');
    await page.waitForTimeout(1000);
    await click(page, 'Forward to?...');
    await page.waitForTimeout(1500);
    await expect(page.getByText('navivox-chat').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12i-forward-back.png',fullPage:true});
  });
  test('12j scrollable memory sheet back navigates', async ({page}) => {
    await page.goto(APP+'#/memory', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Memory detail');
    await page.waitForTimeout(1500);
    await expect(page.getByText('Memory overview').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12j-memory-sheet-back.png',fullPage:true});
  });
  test('12k external link back navigates to browser', async ({page}) => {
    await page.goto(APP+'#/config', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'External links');
    await page.waitForTimeout(1500);
    await expect(page.getByText('term').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12k-external-link-back.png',fullPage:true});
  });
});

// ─── 14. Gateway screenshots (slice 14e/f/g) ─────────────────────
test.describe('14. Gateway', () => {
  test('14e register gateway modal', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Register gateway');
    await page.waitForTimeout(1500);
    await expect(page.getByText('Register gateway').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/14e-register-gateway-modal.png',fullPage:true});
  });
  test('14f voice agent gateway', async ({page}) => {
    await page.goto(APP+'#/agents', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Voice Agent');
    await page.waitForTimeout(1500);
    await expect(page.getByText('Voice agent detail').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/14f-voice-agent-gateway.png',fullPage:true});
  });
  test('14g gateway setup screen', async ({page}) => {
    await page.goto(APP+'#/setup', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await expect(page.getByText('Setup').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/14g-gateway-setup-screen.png',fullPage:true});
  });
});

// ─── 11. Mobile transcript selection (11h-k) ─────────────────────
test.describe('11. Mobile transcript selection', () => {
  test.beforeEach(async ({page}) => {
    await page.setViewportSize({width:390,height:844});
    await page.goto(APP+'#/chats', {timeout:15000}); await page.waitForTimeout(2000);
  });
  test('11h transcript tap long press show menu', async ({page}) => {
    await click(page, 'Transcript composer');
    await page.waitForTimeout(2000);
    const transcriptLocator = page.locator('flt-semantics[role="button"]:has-text("Menu")');
    await transcriptLocator.first().click();
    await page.waitForTimeout(1000);
    await expect(page.getByText('Transcript actions').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/11h-transcript-menu.png',fullPage:true});
  });
  test('11i transcript menu items visible', async ({page}) => {
    await click(page, 'Transcript composer');
    await page.waitForTimeout(2000);
    await click(page, 'Menu');
    await page.waitForTimeout(1000);
    await expect(page.getByText('Copy').first()).toBeVisible();
    await expect(page.getByText('Copy text').first()).toBeVisible();
    await expect(page.getByText('Pin').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/11i-transcript-menu-items.png',fullPage:true});
  });
  test('11j transcript action view works', async ({page}) => {
    await click(page, 'Transcript composer');
    await page.waitForTimeout(2000);
    await click(page, 'Menu');
    await page.waitForTimeout(1000);
    await click(page, 'View');
    await page.waitForTimeout(1000);
    await expect(page.getByText('Detail view').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/11j-transcript-view.png',fullPage:true});
  });
  test('11k transcript action run works', async ({page}) => {
    await click(page, 'Transcript composer');
    await page.waitForTimeout(2000);
    await click(page, 'Menu');
    await page.waitForTimeout(1000);
    await click(page, 'Run');
    await page.waitForTimeout(1000);
    await expect(page.getByText('Run status').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/11k-transcript-run.png',fullPage:true});
  });
});

// ─── 12l-n additional coverage ────────────────────────────────────
test.describe('12. Additional coverage', () => {
  test('12l gateway server list nav bar', async ({page}) => {
    await page.goto(APP+'#/config', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Gateway list');
    await page.waitForTimeout(1500);
    await expect(page.getByText('Server list').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12l-gateway-list-nav.png',fullPage:true});
  });
  test('12m gateway admin health', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Server admin health');
    await page.waitForTimeout(1500);
    await expect(page.getByText('Server health').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12m-gateway-admin-health.png',fullPage:true});
  });
  test('12n agent detail contact tile', async ({page}) => {
    await page.goto(APP+'#/agents', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Open profile list menu');
    await page.waitForTimeout(1500);
    const locator = page.locator('flt-semantics[role="listitem"]').first();
    await locator.click();
    await page.waitForTimeout(1500);
    await expect(page.getByText('Contact detail').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12n-agent-detail-contact.png',fullPage:true});
  });
  test('12o agent detail chat tile', async ({page}) => {
    await page.goto(APP+'#/agents', {timeout:15000}); await page.waitForTimeout(1000); await a11y(page);
    await click(page, 'Voice Agent').first();
    await page.waitForTimeout(1500);
    const locator = page.locator('flt-semantics[role="listitem"]').first();
    await locator.click();
    await page.waitForTimeout(1500);
    await expect(page.getByText('Chat detail').first()).toBeVisible();
    await page.screenshot({path:'playwright/screenshots/12o-agent-detail-chat.png',fullPage:true});
  });
});
