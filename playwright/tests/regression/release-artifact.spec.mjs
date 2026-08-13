import { expect, test } from "@playwright/test";

const root = process.env.RELEASE_ARTIFACT_BASE_URL;

test("packaged Flutter web release initializes", async ({ page }) => {
  expect(root, "RELEASE_ARTIFACT_BASE_URL is required").toBeTruthy();
  const failures = [];
  page.on("pageerror", (error) => failures.push(`pageerror: ${error.message}`));
  page.on("console", (message) => {
    if (message.type() === "error") failures.push(`console: ${message.text()}`);
  });
  page.on("response", (response) => {
    if (response.status() >= 400 && response.url().startsWith(root)) {
      failures.push(`http ${response.status()}: ${response.url()}`);
    }
  });

  await page.goto(root, { waitUntil: "networkidle", timeout: 60000 });
  await page.waitForSelector("flt-glass-pane", {
    state: "attached",
    timeout: 30000,
  });
  await expect(page).toHaveTitle("Hermes Wing");
  expect(failures).toEqual([]);
});
