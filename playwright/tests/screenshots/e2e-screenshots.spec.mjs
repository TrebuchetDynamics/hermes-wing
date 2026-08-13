import { test, expect } from "@playwright/test";
import {
  APP_URL as APP,
  enableFlutterAccessibility as a11y,
} from "../../support/flutter_semantics.mjs";

async function open(page, route) {
  await page.goto(APP + route, { timeout: 15000 });
  await page.waitForTimeout(1500);
  await a11y(page, { delay: 1000 });
}

test("Hermes connect screen screenshot", async ({ page }, testInfo) => {
  await open(page, "#/hermes");
  await page
    .getByRole("button", { name: "Add gateway or profile" })
    .first()
    .click();
  await expect(
    page.getByRole("heading", { name: "Connect to Hermes" }),
  ).toBeVisible();
  await page.screenshot({
    path: testInfo.outputPath("hermes-connect.png"),
    fullPage: true,
  });
});

test("settings screen screenshot", async ({ page }, testInfo) => {
  await open(page, "#/settings");
  await expect(page.getByText("Connect another gateway").first()).toBeVisible();
  await page.screenshot({
    path: testInfo.outputPath("settings.png"),
    fullPage: true,
  });
});
