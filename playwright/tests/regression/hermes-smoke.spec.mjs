import { test, expect } from "@playwright/test";
import {
  APP_URL as APP,
  enableFlutterAccessibility as a11y,
} from "../../support/flutter_semantics.mjs";

function semanticLabel(page, text) {
  const escaped = text.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
  return page.locator(`flt-semantics[aria-label*="${escaped}"]`).first();
}

function semanticText(page, text) {
  return page.getByRole("group", { name: text, exact: true });
}

test.beforeEach(async ({ request }) => {
  const response = await request.post(`${APP}e2e/hermes/reset`);
  expect(response.ok()).toBeTruthy();
});

test("Hermes route opens manual enrollment from the agent empty state", async ({
  page,
}) => {
  await page.goto(`${APP}#/hermes`, { timeout: 15000 });
  await page.waitForTimeout(2000);
  await a11y(page);

  await page
    .getByRole("button", { name: "Add gateway or profile" })
    .first()
    .click();
  await expect(
    page.getByRole("heading", { name: "Connect to Hermes" }),
  ).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Connect one profile manually" }),
  ).toBeVisible();
});

test("mobile Hermes chat keeps secondary actions in an accessible overflow menu", async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto(`${APP}#/hermes`, { timeout: 15000 });
  await page.waitForTimeout(2000);
  await a11y(page);

  await page.evaluate(() => globalThis.wingE2EHermesConnect());

  await expect(
    page.getByRole("button", { name: "Attachments/media status" }),
  ).toHaveCount(0);
  await expect(
    page.getByRole("button", { name: "Files/context folders status" }),
  ).toHaveCount(0);

  await page.getByRole("button", { name: "More actions" }).click();
  await expect(page.getByRole("menuitem", { name: "Sessions" })).toBeVisible();
  await expect(
    page.getByRole("menuitem", { name: "New session" }),
  ).toBeVisible();
  await expect(
    page.getByRole("menuitem", { name: "Diagnostics" }),
  ).toBeVisible();
  await expect(
    page.getByRole("menuitem", { name: "Disconnect" }),
  ).toBeVisible();
});

test("Hermes route renders connected session/capabilities in a real browser e2e build", async ({
  page,
}) => {
  await page.goto(`${APP}#/hermes`, { timeout: 15000 });
  await page.waitForTimeout(2000);
  await a11y(page);

  await page.evaluate(() => globalThis.wingE2EHermesConnect());
  await page.waitForTimeout(1000);

  await expect(semanticLabel(page, "E2E Hermes is ready.")).toBeVisible();
  await expect(
    page
      .locator("flt-semantics")
      .filter({ hasText: "Active Hermes session" })
      .last(),
  ).toContainText("hermes-agent");
  await expect(page.getByText("Sessions").first()).toBeVisible();

  await page.getByRole("button", { name: "Diagnostics" }).first().click();
  await expect(semanticLabel(page, "Runs SSE enabled")).toBeVisible();
  await expect(semanticLabel(page, "Voice: device STT → Hermes")).toBeVisible();
  await expect(semanticLabel(page, "Version: 0.16.0")).toBeVisible();
  await expect(semanticLabel(page, "Gateway: running")).toBeVisible();
  await expect(semanticLabel(page, "Models: hermes-agent")).toBeVisible();
  await expect(semanticLabel(page, "Skills: 2")).toBeVisible();
  await expect(semanticLabel(page, "Toolsets enabled: 1")).toBeVisible();
  await expect(semanticLabel(page, "Jobs: 1")).toBeVisible();
  await page.getByRole("button", { name: "Close" }).click();

  await page.getByRole("button", { name: "Sessions" }).click();
  await page.getByRole("button", { name: "Session actions" }).first().click();
  await page.getByRole("menuitem", { name: "Rename" }).click();
  await page
    .getByRole("textbox", { name: "Session title" })
    .fill("Renamed e2e session");
  await page.getByRole("button", { name: "Save" }).click();
  await expect(
    page.getByRole("heading", { name: "Renamed e2e session" }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Sessions" }).click();
  await page.getByRole("button", { name: "Session actions" }).first().click();
  await page.getByRole("menuitem", { name: "Branch" }).click();
  await expect(page.getByRole("alertdialog")).toContainText(
    "Branch this session?",
  );
  await page.getByRole("button", { name: "Create branch" }).click();
  await expect(
    page.getByRole("heading", { name: "Renamed e2e session fork" }),
  ).toBeVisible();

  await page.evaluate(() =>
    globalThis.wingE2EHermesSendText("hello hermes browser"),
  );
  await expect(
    page.getByRole("group", { name: "hello hermes browser", exact: true }),
  ).toBeVisible();
  await expect(semanticLabel(page, "Approve e2e browser run")).toBeVisible();
  await expect(semanticLabel(page, "Risk: low")).toBeVisible();
  await page.getByRole("button", { name: "Approve once" }).click();
  await expect(
    semanticLabel(page, "Approve e2e browser run"),
  ).not.toBeVisible();
  await expect(
    semanticText(page, "Hermes echo: hello hermes browser"),
  ).toBeVisible();

  await page.getByRole("button", { name: "New session" }).click();
  await page.waitForTimeout(1000);
  await expect(
    page.getByRole("heading", { name: /E2E Hermes Session \d+/ }),
  ).toBeVisible();
  await expect(
    page.getByText("How can Hermes help today?").first(),
  ).toBeVisible();
  await expect(
    page.getByRole("checkbox", { name: "Summarize what you can help me do." }),
  ).toBeVisible();
  await page.evaluate(() =>
    globalThis.wingE2EHermesSendText("new session browser"),
  );
  await expect(
    page.getByRole("group", { name: "new session browser", exact: true }),
  ).toBeVisible();
  await expect(semanticLabel(page, "Approve e2e browser run")).toBeVisible();
  await page.getByRole("button", { name: "Approve once" }).click();
  await expect(
    semanticLabel(page, "Approve e2e browser run"),
  ).not.toBeVisible();
  await expect(
    semanticText(page, "Hermes echo: new session browser"),
  ).toBeVisible();
  const reconnect = page.getByRole("button", { name: "Reconnect" });
  await reconnect.waitFor({ state: "visible", timeout: 5000 }).catch(() => {});
  if (await reconnect.isVisible()) {
    await reconnect.click();
    await expect(reconnect).not.toBeVisible();
  }

  await page.evaluate(() =>
    globalThis.wingE2EHermesSubmitVoice("voice browser turn"),
  );
  await expect(
    page.getByRole("group", { name: "voice browser turn", exact: true }),
  ).toBeVisible();
  await expect(semanticLabel(page, "Approve e2e browser run")).toBeVisible();
  await page.getByRole("button", { name: "Approve once" }).click();
  await expect(
    semanticLabel(page, "Approve e2e browser run"),
  ).not.toBeVisible();
  await expect(
    semanticText(page, "Hermes echo: voice browser turn"),
  ).toBeVisible();

  await page.getByRole("button", { name: "Sessions" }).click();
  await page.getByRole("button", { name: "Session actions" }).first().click();
  await page.getByRole("menuitem", { name: "Delete" }).click();
  await page.getByRole("button", { name: "Delete" }).click();
  await expect(
    page.getByRole("heading", { name: "Renamed e2e session" }),
  ).toBeVisible();

  await page.evaluate(() =>
    globalThis.wingE2EHermesSendText("slow browser turn"),
  );
  await expect(
    page.getByRole("group", { name: "slow browser turn", exact: true }),
  ).toBeVisible();
  await expect(semanticLabel(page, "Approve e2e browser run")).toBeVisible();
  await page.getByRole("button", { name: "Approve once" }).click();
  await expect(
    semanticText(page, "Hermes echo: slow browser turn"),
  ).toBeVisible();
});
