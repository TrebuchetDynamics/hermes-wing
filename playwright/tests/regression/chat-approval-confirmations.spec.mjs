import { test, expect } from "@playwright/test";
import {
  APP_URL as APP,
  enableFlutterAccessibility as a11y,
} from "../../support/flutter_semantics.mjs";

async function screenshot(page, testInfo, name) {
  await page.mouse.move(0, 0);
  await page.waitForTimeout(200);
  await page.screenshot({
    path: testInfo.outputPath(`${name}.png`),
    fullPage: true,
  });
}

async function open(page, route) {
  await page.goto(`${APP}#${route}`, { timeout: 15000 });
  await page.waitForFunction(
    () => typeof globalThis.wingE2EHermesConnect === "function",
    null,
    { timeout: 30000 },
  );
  await a11y(page, { delay: 500 });
}

async function connect(page) {
  await page.evaluate(() => globalThis.wingE2EHermesConnect());
  await expect(
    page.getByRole("heading", { name: /E2E Hermes Session/ }),
  ).toBeVisible();
}

async function submitComposer(page, text) {
  const composer = page.locator('textarea[data-semantics-role="text-field"]');
  await composer.click();
  await page.waitForTimeout(100);
  await composer.fill(text);
  await page.getByRole("button", { name: "Send", exact: true }).click();
}

test.beforeEach(async ({ request }) => {
  const response = await request.post(`${APP}e2e/hermes/reset`);
  expect(response.ok()).toBeTruthy();
});

test("scoped approval confirmations can be cancelled before they are committed", async ({
  page,
  request,
}, testInfo) => {
  await open(page, "/hermes");
  await connect(page);
  const decisionsUrl = `${APP}e2e/hermes/decisions`;

  await submitComposer(page, "session approval browser turn");
  await page.getByRole("button", { name: "Review" }).click();
  await page.getByRole("button", { name: "Allow for session" }).click();
  await expect(page.getByRole("alertdialog")).toContainText(
    "Allow this for the session?",
  );
  await screenshot(page, testInfo, "session-approval-confirmation");
  await page.getByRole("button", { name: "Cancel" }).click();
  await expect(page.getByText("Review Hermes approval")).toBeVisible();
  await screenshot(page, testInfo, "session-approval-cancelled");
  expect((await (await request.get(decisionsUrl)).json()).decisions).toEqual(
    [],
  );

  await page.getByRole("button", { name: "Allow for session" }).click();
  await page.getByRole("button", { name: "Allow for session" }).click();
  await expect(
    page.getByText("Hermes echo: session approval browser turn"),
  ).toBeVisible();
  await screenshot(page, testInfo, "session-approval-completed");

  await submitComposer(page, "always approval browser turn");
  await page.getByRole("button", { name: "Always allow" }).click();
  await expect(page.getByRole("alertdialog")).toContainText(
    "Always allow this Hermes approval?",
  );
  await screenshot(page, testInfo, "always-approval-confirmation");
  await page.getByRole("button", { name: "Cancel" }).click();
  await expect(
    page.getByRole("button", { name: "Always allow" }),
  ).toBeVisible();
  await screenshot(page, testInfo, "always-approval-cancelled");

  await page.getByRole("button", { name: "Always allow" }).click();
  await page.getByRole("button", { name: "Always allow" }).click();
  await expect(
    page.getByText("Hermes echo: always approval browser turn"),
  ).toBeVisible();
  await expect
    .poll(
      async () => (await (await request.get(decisionsUrl)).json()).decisions,
    )
    .toEqual(["session", "always"]);
  await screenshot(page, testInfo, "always-approval-completed");
});
