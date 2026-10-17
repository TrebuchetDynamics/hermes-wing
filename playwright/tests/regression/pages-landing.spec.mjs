import { expect, test } from "@playwright/test";

test.skip(
  !process.env.PAGES_BASE_URL,
  "PAGES_BASE_URL is required for the assembled Pages artifact smoke",
);

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
  await expect(
    page.getByRole("navigation", { name: "Main navigation" }),
  ).toBeVisible();
  await expect(
    page.getByRole("link", { name: "Preview the connection screen" }),
  ).toHaveAttribute("href", "app/");
  for (const link of await page.getByRole("link", { name: "Connect my Agent" }).all()) {
    await expect(link).toHaveAttribute("href", "#connect");
  }
  const connect = page.locator("#connect");
  await expect(connect.locator(".connection-steps > li")).toHaveCount(4);
  for (const text of ["Enable the Agent HTTP API", "/v1/capabilities", "CORS", "First-reply success:"]) {
    await expect(connect).toContainText(text);
  }
  await expect(connect.getByRole("link", { name: "browser guide" })).toHaveAttribute("href", /docs\/getting-started\.md#browser$/);
  await expect(connect.getByRole("link", { name: "Follow your native route" })).toHaveAttribute("href", /docs\/getting-started\.md#direct-agent-connection$/);
  await expect(connect.getByRole("link", { name: "Troubleshoot safely" })).toHaveAttribute("href", /docs\/getting-started\.md#need-help$/);
  await expect(page.locator(".hero-visual figcaption")).toContainText("DEMO DATA · SIMULATED SESSION");
  await expect(page.locator(".product-frame figcaption")).toContainText("not live-provider testing");
  await expect(
    page.getByRole("heading", { name: "Hermes stays in charge." }),
  ).toBeVisible();
  await expect(
    page.getByRole("table", { name: "Platform status" }),
  ).toBeVisible();
  await expect(page.locator("img")).toHaveCount(5);
  for (const image of await page.locator("img").all()) {
    await image.scrollIntoViewIfNeeded();
  }
  await expect
    .poll(() =>
      page
        .locator("img")
        .evaluateAll((images) =>
          images.every((image) => image.complete && image.naturalWidth > 0),
        ),
    )
    .toBeTruthy();
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    ),
  ).toBeTruthy();
}

test("Pages root is a responsive Hermes Wing landing page", async ({
  page,
}) => {
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
        return (
          heading.getBoundingClientRect().top >=
          header.getBoundingClientRect().bottom
        );
      }),
    )
    .toBeTruthy();
  expect(failures).toEqual([]);
});

test("landing page remains usable at a compact mobile viewport", async ({
  page,
}) => {
  const failures = collectPageFailures(page);
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto(root, { waitUntil: "networkidle" });
  await expectLanding(page);
  expect(
    await page
      .locator(".product-frame img")
      .evaluate((image) =>
        image.currentSrc.endsWith("/assets/showcase-mobile.png"),
      ),
  ).toBeTruthy();
  expect(
    await page
      .locator(".flow-frame img")
      .evaluate((image) =>
        image.currentSrc.endsWith("/assets/runtime-flow-mobile.svg"),
      ),
  ).toBeTruthy();
  await expect(
    page
      .getByRole("navigation", { name: "Main navigation" })
      .getByRole("link", { name: "Connect my Agent" }),
  ).toBeVisible();
  expect(failures).toEqual([]);
});

test("landing shares truthful alpha proof and explains trust before connecting", async ({ page }) => {
  const failures = collectPageFailures(page);
  await page.goto(root, { waitUntil: "networkidle" });
  const canonical = "https://trebuchetdynamics.github.io/hermes-wing/";
  await expect(page.locator('link[rel="canonical"]')).toHaveAttribute("href", canonical);
  await expect(page.locator('meta[property="og:url"]')).toHaveAttribute("content", canonical);
  for (const [attribute, prefix] of [["property", "og"], ["name", "twitter"]]) {
    await expect(page.locator(`meta[${attribute}="${prefix}:description"]`)).toHaveAttribute("content", /Alpha client.*your own authenticated Agent/);
    await expect(page.locator(`meta[${attribute}="${prefix}:image"]`)).toHaveAttribute("content", `${canonical}assets/showcase.png`);
    await expect(page.locator(`meta[${attribute}="${prefix}:image:alt"]`)).toHaveAttribute("content", /SIMULATED SESSION.*not live synchronization/);
  }
  await expect(page.locator('meta[name="twitter:card"]')).toHaveAttribute("content", "summary_large_image");
  await expect(page.locator('meta[property="og:image:width"]')).toHaveAttribute("content", "1200");
  await expect(page.locator('meta[property="og:image:height"]')).toHaveAttribute("content", "760");
  await expect(page.locator("form, input, textarea")).toHaveCount(0);
  await expect(page.locator(".trust-note")).toContainText("This page collects no credentials");
  await expect(page.locator(".trust-note")).toContainText("provider may charge");
  const faq = page.getByRole("region", { name: "Before you connect" });
  await expect(faq.getByRole("heading", { level: 3 })).toHaveCount(3);
  await expect(faq).toContainText("Browser SSH and OAuth are unsupported");
  await expect(faq).toContainText("computer must stay on and reachable");
  await expect(faq.getByRole("link", { name: "First-chat guide" })).toHaveAttribute("href", /docs\/getting-started\.md#start-the-conversation$/);
  expect(failures).toEqual([]);
});

test("nested Flutter web alpha initializes under the app route", async ({
  page,
}) => {
  const failures = collectPageFailures(page);
  await page.goto(`${root}app/`, { waitUntil: "networkidle", timeout: 60000 });
  await page.waitForSelector("flt-glass-pane", {
    state: "attached",
    timeout: 30000,
  });
  await expect(page).toHaveTitle("Hermes Wing");
  expect(failures).toEqual([]);
});

for (const width of [1280, 390]) {
  test(`connection entry works without JavaScript at ${width}px and 200% text`, async ({ browser }) => {
    const context = await browser.newContext({ javaScriptEnabled: false, reducedMotion: "reduce", viewport: { width, height: 900 } });
    const page = await context.newPage();
    const failures = collectPageFailures(page);
    await page.goto(root, { waitUntil: "networkidle" });
    await expectLanding(page);
    expect(await page.evaluate(() => matchMedia('(prefers-reduced-motion: reduce)').matches)).toBe(true);
    expect(await page.evaluate(() => getComputedStyle(document.documentElement).scrollBehavior)).toBe("auto");
    await page.keyboard.press("Tab");
    await expect(page.getByRole("link", { name: "Skip to content" })).toBeFocused();
    await page.keyboard.press("Enter");
    const cta = page.locator(".hero-actions").first().getByRole("link", { name: "Connect my Agent" });
    // Pixel-based type must scale too; changing the root rem would miss it.
    await page.evaluate(() => {
      const sizes = [...document.querySelectorAll("body, body *")].map(element => [element, parseFloat(getComputedStyle(element).fontSize)]);
      for (const [element, size] of sizes) element.style.fontSize = `${size * 2}px`;
    });
    for (let stop = 0; stop < 20 && !(await cta.evaluate(element => element === document.activeElement)); stop++) {
      await page.keyboard.press("Tab");
    }
    await expect(cta).toBeFocused();
    await page.keyboard.press("Enter");
    await expect(page).toHaveURL(`${root}#connect`);
    await expect(page.getByRole("heading", { name: "From connection to first reply." })).toBeInViewport();
    await expect.poll(() => page.evaluate(() =>
      document.querySelector("#connect-title").getBoundingClientRect().top >=
      document.querySelector(".site-header").getBoundingClientRect().bottom,
    )).toBeTruthy();
    const routeLinks = page.locator("#connect a");
    await page.keyboard.press("Tab");
    for (const link of await routeLinks.all()) {
      await expect(link).toBeFocused();
      await expect(link).toBeInViewport();
      await page.keyboard.press("Tab");
    }
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBeTruthy();
    expect(failures).toEqual([]);
    await page.screenshot({ path: test.info().outputPath(`landing-${width}-200.png`), fullPage: true });
    await context.close();
  });
}
