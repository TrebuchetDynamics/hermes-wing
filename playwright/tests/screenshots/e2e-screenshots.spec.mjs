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
  await expect(
    page.getByRole("heading", { name: "Welcome to Hermes Wing", exact: true }),
  ).toBeVisible();
  await page.screenshot({
    path: testInfo.outputPath("hermes-connect.png"),
    fullPage: true,
  });
});

test("settings screen screenshot", async ({ page }, testInfo) => {
  await open(page, "#/settings");
  await expect(page.getByRole("button", { name: /^Connect another gateway/ })).toHaveCount(0);
  await expect(page.getByRole("button", { name: "Connections", exact: true }).last()).toBeVisible();
  await page.screenshot({
    path: testInfo.outputPath("settings.png"),
    fullPage: true,
  });
  await page.getByRole("button", { name: "Connections", exact: true }).last().click();
  await expect(page.getByRole("button", { name: /^Connect another gateway/ })).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath("connections.png"), fullPage: true });
});
