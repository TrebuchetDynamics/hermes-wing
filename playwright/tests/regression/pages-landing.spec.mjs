import { expect, test } from "@playwright/test";
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { writeFile } from "node:fs/promises";
import { cpus } from "node:os";
import { enableFlutterAccessibility } from "../../support/flutter_semantics.mjs";

test.skip(
  !process.env.PAGES_BASE_URL,
  "PAGES_BASE_URL is required for the assembled Pages artifact smoke",
);

const root = process.env.PAGES_BASE_URL ?? "http://127.0.0.1:8769/hermes-wing/";

// Explicit input in CI; local smoke binds to the checked-out candidate, not the old public site.
const revision = process.env.PAGES_EXPECTED_REVISION ?? (process.env.PAGES_BASE_URL
  ? execFileSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" }).trim()
  : "");

function collectPageFailures(page) {
  const failures = [];
  page.on("pageerror", (error) => failures.push(`pageerror: ${error.message}`));
  page.on("console", (message) => {
    if (message.type() === "error") {
      failures.push(`console: ${message.text()}`);
    }
  });
  page.on("response", (response) => {
    if (response.status() >= 400 && new URL(response.url()).origin === new URL(root).origin) {
      failures.push(`http ${response.status()}: ${response.url()}`);
    }
  });
  page.on("requestfailed", (request) => {
    if (new URL(request.url()).origin === new URL(root).origin) {
      failures.push(`requestfailed: ${request.url()}: ${request.failure()?.errorText}`);
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

test("assembled entrypoints and proof assets belong to this exact candidate", async ({ request }) => {
  const response = await request.get(`${root}artifact.json`);
  expect(response.ok()).toBeTruthy();
  const manifest = await response.json();
  expect(manifest.revision).toBe(revision);
  expect(Object.keys(manifest.files)).toEqual(expect.arrayContaining([
    "index.html", "styles.css", "assets/app-icon.png", "assets/showcase.png",
    "assets/showcase-mobile.png", "app/index.html", "app/flutter_bootstrap.js", "app/main.dart.js",
  ]));
  for (const [path, expected] of Object.entries(manifest.files)) {
    const asset = await request.get(new URL(path, root).href);
    expect(asset.ok(), path).toBeTruthy();
    const bytes = await asset.body();
    expect(bytes.length, path).toBe(expected.bytes);
    expect(createHash("sha256").update(bytes).digest("hex"), path).toBe(expected.sha256);
  }
});

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

test("assembled setup, proof and local navigation destinations resolve", async ({ page, request }) => {
  const failures = collectPageFailures(page);
  await page.goto(root, { waitUntil: "networkidle" });
  const links = await page.locator("a[href]").evaluateAll((links) => links.map((link) => link.href));
  for (const href of new Set(links)) {
    const target = new URL(href);
    if (target.origin !== new URL(root).origin) continue; // Repository anchors are checked offline by the tooling contract.
    expect(target.pathname.startsWith(new URL(root).pathname), href).toBeTruthy();
    if (target.hash) {
      expect(await page.locator(`[id="${target.hash.slice(1)}"]`).count(), href).toBe(1);
    } else {
      expect((await request.get(href)).ok(), href).toBeTruthy();
    }
  }
  const share = new URL(await page.locator('meta[property="og:image"]').getAttribute("content"));
  const localShare = new URL(`assets/${share.pathname.split("/").at(-1)}`, root);
  expect((await request.get(localShare.href)).ok()).toBeTruthy();
  await expect(page.locator(".product-frame img")).toHaveAttribute("loading", "lazy");
  await expect(page.locator(".flow-frame img")).toHaveAttribute("loading", "lazy");
  expect(failures).toEqual([]);
});

test("landing exposes named semantic content and readable theme pairs", async ({ page }) => {
  const failures = collectPageFailures(page);
  await page.goto(root, { waitUntil: "networkidle" });
  await expect(page.locator("html")).toHaveAttribute("lang", "en");
  await expect(page.getByRole("heading", { level: 1 })).toHaveCount(1);
  await expect(page.getByRole("main")).toHaveCount(1);
  const headings = await page.locator("h1,h2,h3,h4,h5,h6").evaluateAll((elements) => elements.map((element) => Number(element.tagName[1])));
  headings.forEach((level, index) => expect(level).toBeLessThanOrEqual((headings[index - 1] ?? 0) + 1));
  for (const link of await page.getByRole("link").all()) await expect(link).toHaveAccessibleName(/\S/);
  for (const image of await page.locator("main img").all()) await expect(image).toHaveAttribute("alt", /\S/);
  // Focused theme-pair guard, not a full WCAG/gradient/image contrast audit.
  const contrast = await page.evaluate(() => {
    const luminance = (color) => color.match(/[\d.]+/g).slice(0, 3).map(Number).map((value) => {
      const s = value / 255;
      return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
    }).reduce((sum, value, index) => sum + value * [0.2126, 0.7152, 0.0722][index], 0);
    return [".hero-lede", ".release-note", "#connect p", ".trust-note", ".product-frame figcaption", ".status-copy", ".hero-actions .button-primary"].map((selector) => {
      const element = document.querySelector(selector);
      const style = getComputedStyle(element);
      const foreground = luminance(style.color);
      // Brightest theme surface bounds these dark text backgrounds; primary CTA is opaque.
      const background = luminance(element.matches(".button-primary") ? style.backgroundColor : "rgb(16, 24, 39)");
      return { selector, ratio: (Math.max(foreground, background) + 0.05) / (Math.min(foreground, background) + 0.05) };
    });
  });
  for (const { selector, ratio } of contrast) expect(ratio, selector).toBeGreaterThanOrEqual(4.5);
  expect(failures).toEqual([]);
});

test("cold mobile landing stays within controlled lab budgets", async ({ page, context, browser }, testInfo) => {
  await page.setViewportSize({ width: 390, height: 844 });
  const cdp = await context.newCDPSession(page);
  await cdp.send("Network.enable");
  await cdp.send("Network.setCacheDisabled", { cacheDisabled: true });
  await cdp.send("Network.setBypassServiceWorker", { bypass: true });
  await cdp.send("Network.emulateNetworkConditions", {
    offline: false, latency: 150, downloadThroughput: 200000, uploadThroughput: 93750,
  });
  await cdp.send("Emulation.setCPUThrottlingRate", { rate: 4 });
  await page.addInitScript(() => {
    window.pagesLab = { lcp: 0, cls: 0 };
    new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) window.pagesLab.lcp = entry.startTime;
    }).observe({ type: "largest-contentful-paint", buffered: true });
    new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) if (!entry.hadRecentInput) window.pagesLab.cls += entry.value;
    }).observe({ type: "layout-shift", buffered: true });
  });
  const failures = collectPageFailures(page);
  const requests = [];
  page.on("request", (request) => requests.push(request.url()));
  await page.goto(root, { waitUntil: "networkidle" });
  await expect.poll(() => page.evaluate(() => window.pagesLab.lcp)).toBeGreaterThan(0);
  // A fixed post-load observation window, without scrolling or simulated interaction/INP claims.
  await page.waitForTimeout(1000);
  const metrics = await page.evaluate(() => ({
    ...window.pagesLab,
    decodedBytes: performance.getEntriesByType("navigation")[0].decodedBodySize +
      performance.getEntriesByType("resource").reduce((sum, entry) => sum + entry.decodedBodySize, 0),
    observationMs: performance.now(),
  }));
  const lab = JSON.stringify({
    kind: "single-run lab regression; not field Core Web Vitals or INP",
    browser: browser.version(), node: process.version, viewport: "390x844",
    device: "desktop Chromium emulation, not physical mobile",
    host: { platform: process.platform, architecture: process.arch, cpu: cpus()[0]?.model },
    devicePixelRatio: await page.evaluate(() => window.devicePixelRatio),
    cpuSlowdown: 4, latencyMs: 150, downloadBytesPerSecond: 200000, uploadBytesPerSecond: 93750,
    cache: "fresh context, cache disabled, service worker bypassed", metrics, requests,
  }, null, 2);
  await writeFile(testInfo.outputPath("landing-lab.json"), lab);
  await testInfo.attach("landing-lab.json", { contentType: "application/json", path: testInfo.outputPath("landing-lab.json") });
  console.log(`Pages lab: ${lab}`);
  expect(metrics.lcp).toBeLessThanOrEqual(2500);
  expect(metrics.cls).toBeLessThanOrEqual(0.1);
  expect(metrics.decodedBytes).toBeLessThanOrEqual(350000);
  expect(requests.every((url) => new URL(url).origin === new URL(root).origin && !new URL(url).pathname.includes("/app/"))).toBeTruthy();
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
  await expect(page.locator("base")).toHaveAttribute("href", "/hermes-wing/app/");
  // The production welcome must render, not just mount an empty Flutter engine.
  await enableFlutterAccessibility(page, { delay: 0 });
  await expect(page.getByRole("heading", { name: "Welcome to Hermes Wing" })).toBeVisible();
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
    expect(await cta.evaluate((element) => {
      const style = getComputedStyle(element);
      return style.outlineStyle !== "none" && parseFloat(style.outlineWidth) >= 2;
    })).toBeTruthy();
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
    if (width === 1280) {
      // 1280/2 CSS pixels models desktop 200% zoom reflow; it is not browser-chrome zoom qualification.
      await page.evaluate(() => {
        for (const element of document.querySelectorAll("body, body *")) element.style.removeProperty("font-size");
      });
      await page.setViewportSize({ width: 640, height: 450 });
      await expectLanding(page);
      await page.screenshot({ path: test.info().outputPath("landing-desktop-200-zoom-reflow.png"), fullPage: true });
    }
    await context.close();
  });
}
