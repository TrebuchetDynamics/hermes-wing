import { test, expect } from '@playwright/test';
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { APP_URL as APP, enableFlutterAccessibility } from '../../support/flutter_semantics.mjs';

async function actions(page, width) {
  if (width < 600) {
    await page.getByRole('button', { name: 'More actions' }).click();
    await page.getByRole('menuitem', { name: 'Copy transcript' }).click();
  } else {
    await page.getByRole('button', { name: 'Copy transcript' }).click();
  }
}

for (const width of [390, 1280]) {
  test(`real loaded-transcript text/Markdown downloads at ${width}px`, async ({ page, request }, testInfo) => {
    await page.setViewportSize({ width, height: 900 });
    expect(await (await request.post(`${APP}e2e/hermes/long-transcript`, { data: { count: 250 } })).json()).toEqual({ synthetic: true, count: 250 });
    const mutations = [];
    const historyReads = [];
    const errors = [];
    const downloads = [];
    page.on('request', req => {
      if (!['GET', 'OPTIONS'].includes(req.method())) mutations.push({ method: req.method(), route: new URL(req.url()).pathname });
      if (new URL(req.url()).pathname.endsWith('/messages')) historyReads.push(req.url());
    });
    page.on('pageerror', error => errors.push(error.message));
    page.on('download', download => downloads.push(download));
    await page.addInitScript(() => {
      const create = URL.createObjectURL.bind(URL);
      globalThis.transcriptDownloadBlobs = [];
      URL.createObjectURL = blob => {
        globalThis.transcriptDownloadBlobs.push({ type: blob.type, size: blob.size });
        return create(blob);
      };
    });
    await page.goto(`${APP}#/hermes`);
    await page.waitForFunction(() => typeof globalThis.wingE2ETranscriptProjection === 'function');
    await enableFlutterAccessibility(page, { delay: 500 });
    await page.evaluate(() => { globalThis.wingE2EReduceMotion(); globalThis.wingE2EHermesConnect(); });
    await expect.poll(async () => page.evaluate(() => JSON.parse(globalThis.wingE2ETranscriptProjection()).loaded)).toBe(250);
    expect(await page.evaluate(() => JSON.parse(globalThis.wingE2ETranscriptProjection()).allocated_rows)).toBe(100);
    const readCount = historyReads.length;
    const receipts = [];
    await page.context().grantPermissions(['clipboard-read', 'clipboard-write']);
    for (const format of ['text', 'Markdown']) {
      const expected = Buffer.from(Array.from({ length: 250 }, (_, i) => format === 'text'
        ? `${i % 2 ? 'Hermes' : 'You'}:\nSynthetic loaded turn ${i}`
        : `## ${i % 2 ? 'Hermes' : 'You'}\n\nSynthetic loaded turn ${i}`).join('\n\n'), 'utf8');
      await actions(page, width);
      await expect(page.getByText(/Older unfetched history is not included/)).toBeVisible();
      const downloadPromise = page.waitForEvent('download');
      // Real keyboard-activated product control, not a test save override.
      await page.getByRole('button', { name: `Save as ${format}`, exact: true }).press('Enter');
      const download = await downloadPromise;
      expect(await download.failure()).toBeNull();
      const filename = `hermes-transcript.${format === 'text' ? 'txt' : 'md'}`;
      expect(download.suggestedFilename()).toBe(filename);
      expect(download.url()).toMatch(/^blob:/);
      const bytes = await readFile(await download.path());
      expect(bytes.equals(expected)).toBeTruthy();
      await expect(page.locator('flt-semantics').getByText(/Transcript download requested/)).toBeVisible();
      await actions(page, width);
      await page.getByRole('button', { name: `Copy as ${format}`, exact: true }).click();
      await expect.poll(async () => page.evaluate(() => navigator.clipboard.readText())).toBe(expected.toString('utf8'));
      const blob = (await page.evaluate(() => globalThis.transcriptDownloadBlobs)).at(-1);
      expect(blob).toEqual({ type: format === 'text' ? 'text/plain;charset=utf-8' : 'text/markdown;charset=utf-8', size: bytes.length });
      receipts.push({ format, filename, mime: blob.type, bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex'), exact_expected_bytes: true, copy_matches: true });
      await testInfo.attach(filename, { body: bytes, contentType: blob.type });
    }
    // Dismissing the options must not trigger an additional download.
    await actions(page, width);
    await page.keyboard.press('Escape');
    await expect(page.getByRole('button', { name: 'Save as text', exact: true })).not.toBeVisible();
    expect(downloads.length).toBe(2);
    expect(historyReads.length).toBe(readCount);
    expect(mutations).toEqual([]);
    expect(errors).toEqual([]);
    const projection = await page.evaluate(() => JSON.parse(globalThis.wingE2ETranscriptProjection()));
    expect(projection.loaded).toBe(250);
    expect(projection.allocated_rows).toBe(100);
    await testInfo.attach('transcript-export-receipt.json', { body: JSON.stringify({ platform: 'compiled JS-release Chromium only', width, loaded: projection.loaded, allocated_rows: projection.allocated_rows, download_count: downloads.length, remote_mutations: mutations, implicit_history_reads: historyReads.length - readCount, receipts }, null, 2), contentType: 'application/json' });
  });
}
