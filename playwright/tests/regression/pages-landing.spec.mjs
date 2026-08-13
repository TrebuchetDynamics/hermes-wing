import { expect, test } from "@playwright/test";

const root = process.env.PAGES_BASE_URL ?? "http://127.0.0.1:8769/hermes-wing/";

function collectPageFailures(page) {
  const failures = [];
  page.on("pageerror", (error) => failures.push(`pageerror: ${error.message}`));
  page.on("console", (message) => {
    if (message.type() === "error") {
      failures.push(`console: ${message.text()}`);
    }
  });
  page.on("response", (response) => {
    if (response.status() >= 400 && response.url().startsWith(root)) {
      failures.push(`http ${response.status()}: ${response.url()}`);
    }
  });
  return failures;
}

async function expectLanding(page) {
  await expect(page).toHaveTitle("Hermes Wing — Hermes Agent everywhere");
  await expect(
    page.getByRole("heading", { name: "Your agent. Within reach." }),
  ).toBeVisible();
  await expect(page.getByRole("main")).toBeVisible();
  await expect(page.getByRole("navigation", { name: "Main navigation" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Try the web alpha" })).toHaveAttribute(
    "href",
    "app/",
  );
  await expect(page.getByRole("heading", { name: "Hermes stays in charge." })).toBeVisible();
  await expect(page.getByRole("table", { name: "Platform status" })).toBeVisible();
  await expect(page.locator("img")).toHaveCount(5);
  for (const image of await page.locator("img").all()) {
    await image.scrollIntoViewIfNeeded();
  }
  await expect
    .poll(() =>
      page.locator("img").evaluateAll((images) =>
        images.every((image) => image.complete && image.naturalWidth > 0),
      ),
    )
    .toBeTruthy();
  expect(
    await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth),
  ).toBeTruthy();
}

test("Pages root is a responsive Hermes Wing landing page", async ({ page }) => {
  const failures = collectPageFailures(page);
  await page.goto(root, { waitUntil: "networkidle" });
  await expectLanding(page);
  await page
    .getByRole("navigation", { name: "Main navigation" })
    .getByRole("link", { name: "Status" })
    .click();
  await expect
    .poll(() =>
      page.evaluate(() => {
        const heading = document.querySelector("#status-title");
        const header = document.querySelector(".site-header");
        return heading.getBoundingClientRect().top >= header.getBoundingClientRect().bottom;
      }),
    )
    .toBeTruthy();
  expect(failures).toEqual([]);
});

test("landing page remains usable at a compact mobile viewport", async ({ page }) => {
  const failures = collectPageFailures(page);
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto(root, { waitUntil: "networkidle" });
  await expectLanding(page);
  expect(
    await page.locator(".product-frame img").evaluate((image) =>
      image.currentSrc.endsWith("/assets/showcase-mobile.png"),
    ),
  ).toBeTruthy();
  expect(
    await page.locator(".flow-frame img").evaluate((image) =>
      image.currentSrc.endsWith("/assets/runtime-flow-mobile.svg"),
    ),
  ).toBeTruthy();
  await expect(
    page
      .getByRole("navigation", { name: "Main navigation" })
      .getByRole("link", { name: "Open web alpha" }),
  ).toBeVisible();
  expect(failures).toEqual([]);
});

test("nested Flutter web alpha initializes under the app route", async ({ page }) => {
  const failures = collectPageFailures(page);
  await page.goto(`${root}app/`, { waitUntil: "networkidle", timeout: 60000 });
  await page.waitForSelector("flt-glass-pane", {
    state: "attached",
    timeout: 30000,
  });
  await expect(page).toHaveTitle("Hermes Wing");
  expect(failures).toEqual([]);
});
