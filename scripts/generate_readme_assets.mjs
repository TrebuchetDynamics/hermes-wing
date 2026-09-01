import { chromium } from "playwright";
import { spawn, spawnSync } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { enableFlutterAccessibility } from "../playwright/support/flutter_semantics.mjs";

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const assets = path.join(repo, "assets", "readme");
const scratch = path.join(repo, "build", "readme-assets");
const externalBaseUrl = process.env.README_ASSET_BASE_URL;
const port = Number(process.env.README_ASSET_PORT ?? 8871);
const baseUrl = externalBaseUrl ?? `http://127.0.0.1:${port}/`;
let server;

function runBuild() {
  const flutter = process.env.FLUTTER ?? "flutter";
  const result = spawnSync(
    flutter,
    ["build", "web", "--release", "-t", "lib/main_e2e.dart"],
    { cwd: repo, env: process.env, stdio: "inherit" },
  );
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`Flutter web build failed with exit code ${result.status}`);
  }
}

async function waitForServer() {
  for (let attempt = 0; attempt < 60; attempt += 1) {
    try {
      const response = await fetch(baseUrl);
      if (response.ok) return;
    } catch {
      // The local server is still starting.
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  throw new Error(`Timed out waiting for ${baseUrl}`);
}

async function seedPresentation() {
  const response = await fetch(`${baseUrl}e2e/hermes/presentation`, {
    method: "POST",
  });
  if (!response.ok) {
    throw new Error(`Presentation seed failed with HTTP ${response.status}`);
  }
}

async function openWingPage(browser, viewport) {
  const context = await browser.newContext({
    viewport,
    colorScheme: "dark",
    reducedMotion: "reduce",
    timezoneId: "UTC",
  });
  const page = await context.newPage();
  const failures = [];
  page.on("pageerror", (error) => failures.push(`pageerror: ${error.message}`));
  page.on("console", (message) => {
    if (message.type() === "error") {
      failures.push(`console: ${message.text()}`);
    }
  });
  page.on("response", (response) => {
    if (response.status() >= 400 && response.url().startsWith(baseUrl)) {
      failures.push(`http ${response.status()}: ${response.url()}`);
    }
  });
  await page.clock.setFixedTime(new Date("2026-01-15T09:41:00Z"));
  await page.goto(`${baseUrl}#/hermes`, { waitUntil: "networkidle" });
  await page.waitForFunction(
    () => typeof globalThis.wingE2EHermesConnect === "function",
  );
  await enableFlutterAccessibility(page, { delay: 500 });
  await page.evaluate(() => globalThis.wingE2EHermesConnect());
  await page.getByRole("heading", { name: "Gateway readiness" }).waitFor();
  return { context, failures, page };
}

async function assertCleanPresentation(capture) {
  const forbidden = [
    "_no_installed_skill_match_",
    "No installed skills match",
    "could not be loaded",
    "Authentication required",
    "Connection failed",
  ];
  const bodyText = await capture.page.locator("body").innerText();
  for (const text of forbidden) {
    if (bodyText.includes(text)) {
      throw new Error(`Refusing to capture presentation containing: ${text}`);
    }
  }
  if (capture.failures.length > 0) {
    throw new Error(capture.failures.join("\n"));
  }
}

async function captureProductFrames(browser) {
  await seedPresentation();
  const desktop = await openWingPage(browser, { width: 1280, height: 800 });
  await desktop.page.evaluate(() =>
    globalThis.wingE2EHermesSendText("Check gateway readiness."),
  );
  await desktop.page.getByRole("button", { name: "Approve once" }).click();
  await desktop.page
    .getByText("Gateway is healthy. Profiles, skills, and toolsets are ready.")
    .first()
    .waitFor();
  await desktop.page.evaluate(() => globalThis.wingE2EReduceMotion());
  await desktop.page.waitForTimeout(100);
  await desktop.page.mouse.move(0, 0);
  await desktop.page.waitForTimeout(600);
  await assertCleanPresentation(desktop);
  const desktopPath = path.join(scratch, "desktop.png");
  await desktop.page.screenshot({
    path: desktopPath,
    clip: { x: 0, y: 0, width: 1280, height: 754 },
    animations: "disabled",
  });
  await desktop.context.close();

  await seedPresentation();
  const mobile = await openWingPage(browser, { width: 390, height: 720 });
  await mobile.page.evaluate(() =>
    globalThis.wingE2EHermesSendText("Check gateway readiness."),
  );
  await mobile.page.getByRole("button", { name: "Review" }).click();
  await mobile.page.getByText("Review Hermes approval").waitFor();
  const approveOnce = mobile.page.getByRole("button", { name: "Approve once" });
  await approveOnce.waitFor();
  await approveOnce.scrollIntoViewIfNeeded();
  await mobile.page.evaluate(() => globalThis.wingE2EReduceMotion());
  await mobile.page.waitForTimeout(100);
  await mobile.page.mouse.move(0, 0);
  await mobile.page.waitForTimeout(600);
  await assertCleanPresentation(mobile);
  const mobilePath = path.join(scratch, "mobile.png");
  const mobileBytes = await mobile.page.screenshot({
    clip: { x: 0, y: 0, width: 390, height: 720 },
    animations: "disabled",
  });
  await Promise.all([
    fs.writeFile(mobilePath, mobileBytes),
    fs.writeFile(path.join(assets, "showcase-mobile.png"), mobileBytes),
  ]);
  await mobile.context.close();

  return { desktopPath, mobilePath };
}

async function composeShowcase(browser, desktopPath, mobilePath) {
  const [desktopBytes, mobileBytes] = await Promise.all([
    fs.readFile(desktopPath),
    fs.readFile(mobilePath),
  ]);
  const page = await browser.newPage({
    viewport: { width: 1200, height: 760 },
  });
  await page.setContent(`<!doctype html>
<html><head><style>
*{box-sizing:border-box}html,body{margin:0;width:1200px;height:760px;overflow:hidden}
body{background:#0c0e12;color:#f4f4f5;font-family:Arial,sans-serif}
.eyebrow{position:absolute;left:42px;top:35px;color:#7dd3fc;font:700 12px ui-monospace,monospace;letter-spacing:1.5px}
h1{position:absolute;left:42px;top:58px;margin:0;font-size:34px;line-height:1.1;letter-spacing:-.7px}
.meta{position:absolute;right:42px;top:39px;color:#8f96a3;font:12px ui-monospace,monospace;letter-spacing:1px}
.meta:before{content:"";display:inline-block;width:8px;height:8px;margin-right:9px;border-radius:50%;background:#20e6e6}
.frame{position:absolute;overflow:hidden;border:1px solid #343943;background:#111318;box-shadow:0 20px 60px rgba(0,0,0,.3)}
.frame img{display:block;width:100%;height:100%;object-fit:cover}
.desktop{left:42px;top:126px;width:790px;height:466px;border-radius:16px}
.mobile{right:42px;top:126px;width:282px;height:520px;border-radius:24px}
.label{position:absolute;z-index:2;top:111px;padding:7px 17px;border:1px solid #343943;border-radius:999px;background:#202329;color:#cbd1da;font:700 12px ui-monospace,monospace;letter-spacing:.6px}
.label.desktop-label{left:58px}.label.mobile-label{right:58px}
.proof{position:absolute;left:42px;bottom:88px;display:flex;gap:10px}
.proof span{padding:8px 14px;border:1px solid #343943;border-radius:999px;color:#cbd1da;font:700 11px ui-monospace,monospace;letter-spacing:.6px}
.proof span:before{content:"";display:inline-block;width:6px;height:6px;margin-right:8px;border-radius:50%;background:#3b82f6}
.caption{position:absolute;left:42px;bottom:35px;color:#8f96a3;font:13px ui-monospace,monospace;letter-spacing:.25px}
</style></head><body>
<div class="eyebrow">CURRENT UI · REPRODUCIBLE PRODUCT CAPTURE</div>
<h1>Follow the run. Step in from your phone.</h1>
<div class="meta">ONE FLUTTER CLIENT</div>
<div class="label desktop-label">DESKTOP · GATEWAY READINESS</div>
<div class="label mobile-label">MOBILE · APPROVAL</div>
<div class="frame desktop"><img alt="" src="data:image/png;base64,${desktopBytes.toString("base64")}"></div>
<div class="frame mobile"><img alt="" src="data:image/png;base64,${mobileBytes.toString("base64")}"></div>
<div class="proof"><span>LIVE RUN</span><span>TOOL ACTIVITY</span><span>APPROVAL ON MOBILE</span></div>
<div class="caption">The same Hermes session on desktop and mobile.</div>
</body></html>`);
  await page.screenshot({ path: path.join(assets, "showcase.png") });
  await page.close();
}

function heroSvg() {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="410" viewBox="0 0 1200 410" role="img" aria-labelledby="title desc">
  <title id="title">Control Hermes Agent from your phone</title>
  <desc id="desc">Hermes Wing keeps conversations, tool activity, and approvals within reach on Android, web, and desktop.</desc>
  <rect width="1200" height="410" rx="26" fill="#0c0e12"/>
  <path d="M670 32V378" stroke="#23262e"/>
  <g transform="translate(58 48)">
    <text x="0" y="0" dominant-baseline="hanging" fill="#7dd3fc" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="15" font-weight="700" letter-spacing="2.2">ANDROID-FIRST HERMES AGENT CLIENT</text>
    <text x="0" y="50" dominant-baseline="hanging" fill="#f4f4f5" font-family="-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif" font-size="72" font-weight="800" letter-spacing="-3">HERMES</text>
    <text x="0" y="119" dominant-baseline="hanging" fill="#20e6e6" font-family="-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif" font-size="72" font-weight="800" letter-spacing="-3">WING</text>
    <text x="2" y="220" dominant-baseline="hanging" fill="#f4f4f5" font-family="-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif" font-size="24" font-weight="650">Control Hermes Agent from your phone.</text>
    <text x="2" y="260" dominant-baseline="hanging" fill="#8f96a3" font-family="-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif" font-size="17">Continue conversations, review tools, and answer approvals.</text>
  </g>
  <g transform="translate(708 32)">
    <rect width="438" height="346" rx="20" fill="#13151a" stroke="#30343b"/>
    <circle cx="24" cy="22" r="5" fill="#20e6e6"/>
    <text x="40" y="15" dominant-baseline="hanging" fill="#c4c8cf" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="12" font-weight="700" letter-spacing="1.4">SESSION TRACE · HEALTHY</text>
    <text x="414" y="15" dominant-baseline="hanging" text-anchor="end" fill="#7dd3fc" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="12">ATTACHED</text>
    <path d="M0 44H438" stroke="#30343b"/><path d="M30 76V292" stroke="#30343b" stroke-width="2"/>
    <circle cx="30" cy="86" r="8" fill="#13151a" stroke="#20e6e6" stroke-width="2"/>
    <rect x="54" y="62" width="352" height="56" rx="12" fill="#1b1d21" stroke="#30343b"/>
    <text x="70" y="75" dominant-baseline="hanging" fill="#7dd3fc" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="11" font-weight="700" letter-spacing="1.2">CONNECTED</text>
    <text x="70" y="94" dominant-baseline="hanging" fill="#f4f4f5" font-family="-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif" font-size="14" font-weight="650">Hermes capability contract accepted</text>
    <circle cx="30" cy="166" r="8" fill="#3b82f6"/>
    <rect x="54" y="136" width="352" height="66" rx="12" fill="#1b1d21" stroke="#30343b"/>
    <text x="70" y="149" dominant-baseline="hanging" fill="#7dd3fc" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="11" font-weight="700" letter-spacing="1.2">TOOL COMPLETE</text>
    <text x="70" y="169" dominant-baseline="hanging" fill="#f4f4f5" font-family="-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif" font-size="14" font-weight="650">read_file · Gateway checks complete</text>
    <text x="390" y="169" dominant-baseline="hanging" text-anchor="end" fill="#8f96a3" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="12">verified</text>
    <circle cx="30" cy="260" r="8" fill="#20e6e6"/>
    <rect x="54" y="220" width="352" height="102" rx="12" fill="#102527" stroke="#208f94"/>
    <text x="70" y="235" dominant-baseline="hanging" fill="#9ff7f4" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="11" font-weight="700" letter-spacing="1.2">RUN COMPLETE</text>
    <text x="70" y="257" dominant-baseline="hanging" fill="#f4f4f5" font-family="-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif" font-size="14" font-weight="650">Healthy summary streamed to this session</text>
    <rect x="70" y="286" width="92" height="22" rx="11" fill="none" stroke="#20e6e6"/>
    <text x="116" y="291" dominant-baseline="hanging" text-anchor="middle" fill="#9ff7f4" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="10" font-weight="700">COMPLETED</text>
    <text x="390" y="291" dominant-baseline="hanging" text-anchor="end" fill="#7dd3fc" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="10" font-weight="700">REPLY STREAMED</text>
  </g>
  <g transform="translate(58 373)">
    <text x="0" y="0" dominant-baseline="hanging" fill="#5f6672" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="13" letter-spacing="1.2">ALPHA · ANDROID + WEB + DESKTOP</text>
    <text x="1088" y="0" dominant-baseline="hanging" text-anchor="end" fill="#8f96a3" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="13">YOUR AGENT · WITHIN REACH</text>
  </g>
</svg>\n`;
}

function runtimeFlowSvg() {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="340" viewBox="0 0 1200 340" role="img" aria-labelledby="title desc">
  <title id="title">Hermes Wing trusted runtime flow</title>
  <desc id="desc">Wing Link ends at setup and pairing. Wing then reviews a trusted HTTPS origin, fails closed on missing capabilities, opens a Hermes session, streams SSE events, and leaves approval to the operator.</desc>
  <rect width="1200" height="340" rx="26" fill="#111315"/>
  <text x="52" y="34" fill="#f4f4f5" font-family="-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif" font-size="31">Hermes owns the agent. Wing stays in reach.</text>
  <text x="52" y="82" fill="#8f96a3" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="13" letter-spacing="1.2">WING LINK: INSTALL + PAIR  ·  HTTPS API: COMMANDS  ·  SSE: RUN EVENTS</text>
  <path d="M184 181H1016" stroke="#363b43" stroke-width="4"/>
  <g fill="#3b82f6"><path d="M244 181l-12-8v16z"/><path d="M466 181l-12-8v16z"/><path d="M688 181l-12-8v16z"/><path d="M910 181l-12-8v16z"/></g>
  <g font-family="-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif" text-anchor="middle">
    <g transform="translate(144 181)"><circle r="43" fill="#1b1d21" stroke="#5b6470"/><path d="M-18 9h36v24h-36zM-12 9v-10a12 12 0 0124 0V9" fill="none" stroke="#7dd3fc" stroke-width="4"/><text y="63" fill="#f4f4f5" font-size="17" font-weight="700">Trusted HTTPS</text><text y="86" fill="#8f96a3" font-size="14">review one origin</text></g>
    <g transform="translate(366 181)"><circle r="43" fill="#1b1d21" stroke="#5b6470"/><path d="M-21-13h42M-21 0h32M-21 13h42" stroke="#7dd3fc" stroke-width="4" stroke-linecap="round"/><circle cx="21" cy="13" r="5" fill="#3b82f6"/><text y="63" fill="#f4f4f5" font-size="17" font-weight="700">Capabilities</text><text y="86" fill="#8f96a3" font-size="14">fail closed if absent</text></g>
    <g transform="translate(588 181)"><circle r="43" fill="#1b1d21" stroke="#3b82f6" stroke-width="2"/><path d="M-21-17h42v29h-25l-13 10V12h-4z" fill="none" stroke="#7dd3fc" stroke-width="3"/><text y="63" fill="#f4f4f5" font-size="17" font-weight="700">Hermes session</text><text y="86" fill="#8f96a3" font-size="14">authoritative context</text></g>
    <g transform="translate(810 181)"><circle r="43" fill="#1b1d21" stroke="#3b82f6" stroke-width="2"/><path d="M-26 4h14l9-25 14 42 10-25h13" fill="none" stroke="#7dd3fc" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><text y="63" fill="#f4f4f5" font-size="17" font-weight="700">SSE run events</text><text y="86" fill="#8f96a3" font-size="14">runs, tools, usage</text></g>
    <g transform="translate(1032 181)"><circle r="43" fill="#1b1d21" stroke="#3b82f6" stroke-width="2"/><path d="M-20 0l13 13 29-31" fill="none" stroke="#7dd3fc" stroke-width="4" stroke-linecap="round"/><text y="63" fill="#f4f4f5" font-size="17" font-weight="700">Approve or stop</text><text y="86" fill="#8f96a3" font-size="14">operator decides</text></g>
  </g>
  <text x="52" y="316" fill="#8f96a3" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="12.5">Wing Link ends at setup and pairing. Hermes owns profiles, providers, sessions, tools, schedules, and messages.</text>
</svg>\n`;
}

function runtimeFlowMobileSvg() {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="600" height="780" viewBox="0 0 600 780" role="img" aria-labelledby="title desc">
  <title id="title">Hermes Wing trusted runtime flow</title>
  <desc id="desc">Wing Link ends at setup and pairing. Wing reviews HTTPS, fails closed on missing capabilities, and streams Hermes SSE events under operator control.</desc>
  <rect width="600" height="780" rx="28" fill="#111315"/>
  <text x="40" y="52" fill="#f4f4f5" font-family="-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif" font-size="31">Hermes owns the agent.</text>
  <text x="40" y="90" fill="#8f96a3" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="13" letter-spacing="1.1">WING LINK: INSTALL + PAIR</text>
  <text x="40" y="114" fill="#8f96a3" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="13" letter-spacing="1.1">HTTPS COMMANDS · SSE EVENTS</text>
  <path d="M86 172V642" stroke="#363b43" stroke-width="4"/>
  <g fill="#3b82f6"><path d="M86 236l-8-12h16z"/><path d="M86 348l-8-12h16z"/><path d="M86 460l-8-12h16z"/><path d="M86 572l-8-12h16z"/></g>
  <g font-family="-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif">
    <g transform="translate(86 188)"><circle r="40" fill="#1b1d21" stroke="#5b6470"/><path d="M-17 7h34v23h-34zM-11 7v-10a11 11 0 0122 0V7" fill="none" stroke="#7dd3fc" stroke-width="4"/><text x="72" y="-3" fill="#f4f4f5" font-size="23" font-weight="700">Trusted HTTPS</text><text x="72" y="28" fill="#8f96a3" font-size="17">review one origin</text></g>
    <g transform="translate(86 300)"><circle r="40" fill="#1b1d21" stroke="#5b6470"/><path d="M-20-12h40M-20 0h30M-20 12h40" stroke="#7dd3fc" stroke-width="4" stroke-linecap="round"/><circle cx="20" cy="12" r="5" fill="#3b82f6"/><text x="72" y="-3" fill="#f4f4f5" font-size="23" font-weight="700">Capabilities</text><text x="72" y="28" fill="#8f96a3" font-size="17">fail closed if absent</text></g>
    <g transform="translate(86 412)"><circle r="40" fill="#1b1d21" stroke="#3b82f6" stroke-width="2"/><path d="M-20-16h40v28h-24l-12 9V12h-4z" fill="none" stroke="#7dd3fc" stroke-width="3"/><text x="72" y="-3" fill="#f4f4f5" font-size="23" font-weight="700">Hermes session</text><text x="72" y="28" fill="#8f96a3" font-size="17">authoritative context</text></g>
    <g transform="translate(86 524)"><circle r="40" fill="#1b1d21" stroke="#3b82f6" stroke-width="2"/><path d="M-25 4h13l9-24 13 40 10-24h12" fill="none" stroke="#7dd3fc" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><text x="72" y="-3" fill="#f4f4f5" font-size="23" font-weight="700">SSE run events</text><text x="72" y="28" fill="#8f96a3" font-size="17">runs, tools, and usage</text></g>
    <g transform="translate(86 636)"><circle r="40" fill="#1b1d21" stroke="#3b82f6" stroke-width="2"/><path d="M-19 0l12 12 28-30" fill="none" stroke="#7dd3fc" stroke-width="4" stroke-linecap="round"/><text x="72" y="-3" fill="#f4f4f5" font-size="23" font-weight="700">Approve or stop</text><text x="72" y="28" fill="#8f96a3" font-size="17">the operator decides</text></g>
  </g>
  <text x="40" y="734" fill="#8f96a3" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="12.5">Wing Link ends at setup and pairing.</text>
  <text x="40" y="756" fill="#8f96a3" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="12.5">Hermes remains authoritative for agent state.</text>
</svg>\n`;
}

async function writeVectorAssets() {
  await Promise.all([
    fs.writeFile(path.join(assets, "hero.svg"), heroSvg()),
    fs.writeFile(path.join(assets, "runtime-flow.svg"), runtimeFlowSvg()),
    fs.writeFile(
      path.join(assets, "runtime-flow-mobile.svg"),
      runtimeFlowMobileSvg(),
    ),
  ]);
}

try {
  await fs.mkdir(assets, { recursive: true });
  await fs.mkdir(scratch, { recursive: true });
  if (!externalBaseUrl) {
    runBuild();
    server = spawn(process.execPath, ["serve_web.mjs"], {
      cwd: repo,
      env: { ...process.env, PORT: String(port) },
      stdio: ["ignore", "inherit", "inherit"],
    });
    await waitForServer();
  }
  const browser = await chromium.launch({ headless: true });
  try {
    const frames = await captureProductFrames(browser);
    await composeShowcase(browser, frames.desktopPath, frames.mobilePath);
    await writeVectorAssets();
  } finally {
    await browser.close();
  }
  console.log("Regenerated README and landing assets.");
} finally {
  server?.kill("SIGTERM");
}
