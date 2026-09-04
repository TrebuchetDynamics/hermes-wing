import { test, expect } from "@playwright/test";
import {
  APP_URL as APP,
  enableFlutterAccessibility as a11y,
} from "../../support/flutter_semantics.mjs";

const hermesPort = process.env.HERMES_E2E_PORT ?? "8768";
const hermesOrigin = `http://127.0.0.1:${hermesPort}`;

function semanticLabel(page, text) {
  const escaped = text.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
  return page.locator(`flt-semantics[aria-label*="${escaped}"]`).first();
}

test.beforeEach(async ({ request }) => {
  const response = await request.post(`${hermesOrigin}/e2e/hermes/reset`);
  expect(response.ok()).toBeTruthy();
});

test("cross-origin Agent SSE works with the advertised CORS headers", async ({
  page,
}) => {
  await page.goto(`${APP}#/hermes`, { timeout: 15000 });
  await page.waitForFunction(
    () => typeof globalThis.wingE2EHermesConnect === "function",
    null,
    { timeout: 30000 },
  );
  await a11y(page, { delay: 500 });

  await page.evaluate(
    ({ baseUrl, apiKey }) => globalThis.wingE2EHermesConnect(baseUrl, apiKey),
    { baseUrl: hermesOrigin, apiKey: "cors-test-key" },
  );
  await expect(page.getByRole("button", { name: "Sessions" })).toBeVisible();

  await page.evaluate(() =>
    globalThis.wingE2EHermesSendText("cross-origin stream turn"),
  );
  await expect(semanticLabel(page, "Approve e2e browser run")).toBeVisible();
});

test("Agent approval streams survive the ordinary request deadline", async ({
  page,
}) => {
  const streamFailures = [];
  page.on("requestfailed", (request) => {
    if (/\/v1\/runs\/[^/]+\/events$/.test(request.url())) {
      streamFailures.push(request.failure()?.errorText);
    }
  });
  await page.goto(`${APP}#/hermes`);
  await page.waitForFunction(
    () => typeof globalThis.wingE2EHermesConnect === "function",
  );
  await a11y(page, { delay: 500 });
  await page.evaluate(
    (baseUrl) => globalThis.wingE2EHermesConnect(baseUrl, "cors-test-key"),
    hermesOrigin,
  );
  await expect(page.getByRole("button", { name: "Sessions" })).toBeVisible();
  await page.evaluate(() =>
    globalThis.wingE2EHermesSendText("delayed approval stream"),
  );
  await expect(semanticLabel(page, "Approve e2e browser run")).toBeVisible();
  // XHR deadlines use wall time, even while an SSE response remains open.
  await page.waitForTimeout(21000);
  expect(streamFailures).toEqual([]);
  await page.getByRole("button", { name: "Approve once" }).click();
  await expect(
    semanticLabel(page, "Hermes echo: delayed approval stream"),
  ).toBeVisible();
});
