import { test, expect } from '@playwright/test';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

async function projection(page) {
  return page.evaluate(() => JSON.parse(globalThis.wingE2ETranscriptProjection()));
}

for (const width of [390, 1280]) {
  for (const count of [250, 1000]) {
    test(`synthetic ${count} loaded turns at ${width}px: bounded reading, recovery, copy and approval`, async ({ page, request }, testInfo) => {
      await page.setViewportSize({ width, height: 900 });
      const seeded = await request.post(`${APP}e2e/hermes/long-transcript`, { data: { count } });
      expect(await seeded.json()).toEqual({ synthetic: true, count });
      await page.goto(`${APP}#/hermes`);
      await page.waitForFunction(() => typeof globalThis.wingE2ETranscriptProjection === 'function');
      await enableFlutterAccessibility(page, { delay: 500 });
      await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
      if (count === 1000) {
        await expect.poll(async () => (await projection(page)).loaded).toBe(500);
        await page.evaluate(() => globalThis.wingE2EHermesLoadEarlier());
      }
      await expect.poll(async () => (await projection(page)).loaded).toBe(count);
      await expect.poll(async () => (await projection(page)).allocated_rows).toBe(100);
      const initial = await projection(page);
      expect(initial.mounted_synthetic.every(row => row.index >= count - 100)).toBeTruthy();
      const reveal = page.getByRole('button', { name: /Show up to 100 earlier loaded turns/ });
      await expect(reveal).toBeVisible();
      // Scroll actual Flutter viewport upward before output arrives.
      await page.mouse.move(width / 2, 420);
      await page.mouse.wheel(0, -350);
      await expect.poll(async () => (await projection(page)).offset).toBeGreaterThan(80);
      await expect(page.getByRole('button', { name: 'Latest activity' })).toBeVisible();
      const browsed = await projection(page);
      const anchor = browsed.mounted_synthetic.find(row => row.y > 180 && row.y < 440);
      expect(anchor).toBeTruthy();
      const appended = await request.post(`${APP}e2e/hermes/append-transcript`);
      expect((await appended.json()).count).toBe(count + 1);
      await page.evaluate(() => globalThis.wingE2EHermesReconcile());
      if (count === 1000) {
        await expect.poll(async () => (await projection(page)).loaded).toBe(500);
        await page.evaluate(() => globalThis.wingE2EHermesLoadEarlier());
        await expect.poll(async () => (await projection(page)).loaded).toBe(1000);
        await page.evaluate(() => globalThis.wingE2EHermesLoadEarlier());
      }
      await expect.poll(async () => (await projection(page)).loaded).toBe(count + 1);
      await expect.poll(async () => (await projection(page)).allocated_rows).toBe(100);
      await expect.poll(async () => {
        const row = (await projection(page)).mounted_synthetic.find(row => row.index === anchor.index);
        return row ? Math.abs(row.y - anchor.y) : 999;
      }).toBeLessThanOrEqual(1);
      await reveal.press('Enter');
      await expect.poll(async () => (await projection(page)).allocated_rows).toBe(200);
      const revealed = await projection(page);
      expect(Math.abs(revealed.mounted_synthetic.find(row => row.index === anchor.index).y - anchor.y)).toBeLessThanOrEqual(1);
      await page.getByRole('button', { name: 'Latest activity' }).click();
      await expect.poll(async () => (await projection(page)).allocated_rows).toBe(100);
      await expect.poll(async () => (await projection(page)).offset).toBe(0);
      await page.context().grantPermissions(['clipboard-read', 'clipboard-write']);
      if (width < 600) {
        await page.getByRole('button', { name: 'More actions' }).click();
        await page.getByRole('menuitem', { name: 'Copy transcript' }).click();
      } else {
        await page.getByRole('button', { name: 'Copy transcript' }).click();
      }
      await page.getByRole('button', { name: 'Copy as text' }).click();
      await expect.poll(async () => page.evaluate(async () => (await navigator.clipboard.readText()).includes('Synthetic loaded turn 0'))).toBeTruthy();
      const copiedCount = await page.evaluate(async () => (await navigator.clipboard.readText()).match(/Synthetic loaded turn \d+/g)?.length ?? 0);
      expect(copiedCount).toBe(count + 1);
      // Existing deterministic run/approval path, never real provider generation.
      await page.mouse.move(width / 2, 420);
      await page.mouse.wheel(0, -350);
      await expect(page.getByRole('button', { name: 'Latest activity' })).toBeVisible();
      await page.evaluate(() => globalThis.wingE2EHermesSendText('Synthetic window approval journey'));
      // Pending actions are not projected out: explicit recovery remains available.
      await page.getByRole('button', { name: 'Latest activity' }).click();
      await expect(page.getByRole('button', { name: 'Review', exact: true })).toBeVisible();
      await page.getByRole('button', { name: 'Review', exact: true }).click();
      await expect(page.getByText('Review Hermes approval', { exact: true })).toBeVisible();
      await testInfo.attach('synthetic-window-receipt.json', { body: JSON.stringify({ platform: 'Chromium deterministic Flutter app only', width, count, initial_allocated: initial.allocated_rows, browse_allocated: browsed.allocated_rows, revealed_allocated: revealed.allocated_rows, anchor_delta: revealed.mounted_synthetic.find(row => row.index === anchor.index).y - anchor.y, copied_count: copiedCount }), contentType: 'application/json' });
    });
  }
}
