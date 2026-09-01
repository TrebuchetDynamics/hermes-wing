import { test, expect } from "@playwright/test";
import {
  APP_URL as APP,
  enableFlutterAccessibility as a11y,
} from "../../support/flutter_semantics.mjs";

async function open(page, route) {
  await page.goto(`${APP}#${route}`, { timeout: 15000 });
  await page.waitForFunction(
    () => typeof globalThis.wingE2EHermesConnect === "function",
    null,
    { timeout: 30000 },
  );
  await a11y(page, { delay: 500 });
}

async function openConnected(page, route) {
  await open(page, route);
  await page.evaluate(() => globalThis.wingE2EHermesConnect());
}

test("Hermes empty state opens secure web enrollment", async ({ page }) => {
  await open(page, "/hermes");
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
  await expect(page.getByRole("textbox", { name: "Access token" })).toHaveCount(
    0,
  );
});

test("unknown routes render a bounded not-found screen", async ({ page }) => {
  await open(page, "/does-not-exist");

  await expect(page.getByText("Hermes Wing").first()).toBeVisible();
  await expect(
    page.getByText("Route not found: /does-not-exist"),
  ).toBeVisible();
});

test("Office renders its connected empty state and settings recovery action", async ({
  page,
}) => {
  await openConnected(page, "/office");

  await expect(
    page.getByRole("group", { name: /No Hermes profiles available/ }),
  ).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Open settings" }),
  ).toBeVisible();
});

test("Profiles fail closed when profile administration is not advertised", async ({
  page,
}) => {
  await openConnected(page, "/profiles");

  await expect(page.getByText("Profiles unavailable")).toBeVisible();
  await expect(
    page.getByText(
      "Update Hermes Agent and reconnect this gateway with profile permissions.",
    ),
  ).toBeVisible();
  await expect(page.getByText("New Agent")).toHaveCount(0);
});

test("Standalone persona route stays explicit without a selected profile", async ({
  page,
}) => {
  await openConnected(page, "/soul");

  await expect(page.getByText("No profiles available")).toBeVisible();
  await expect(page.getByRole("textbox", { name: "Persona" })).toHaveCount(0);
});

test("Providers exposes runtime models without unsupported mutation controls", async ({
  page,
}) => {
  await openConnected(page, "/providers");

  await expect(page.getByText("Providers unavailable")).toBeVisible();
  const modelSelection = page.getByRole("group", { name: "Model selection" });
  await expect(modelSelection).toContainText("Runtime models");
  await expect(modelSelection).toContainText("hermes-agent");
  await expect(page.getByText("Manage credential")).toHaveCount(0);
  await expect(page.getByRole("button", { name: "Choose model" })).toHaveCount(
    0,
  );
});

test("Tools inventory supports search and resolved-tool disclosure", async ({
  page,
}) => {
  await openConnected(page, "/tools");

  const skillSearch = page.getByRole("textbox", {
    name: "Search installed skills",
  });
  await expect(skillSearch).toBeVisible();
  const skills = page.getByRole("group", { name: "Installed skills" });
  await expect(skills).toContainText("ascii-art");
  await expect(skills).toContainText("github");

  await skillSearch.click();
  await page.waitForTimeout(100);
  await skillSearch.fill("no_matching_skill_98765");
  await expect(
    page.getByRole("textbox", {
      name: /No installed skills match this search/,
    }),
  ).toBeVisible();
  await page.getByRole("textbox", { name: /Search installed skills/ }).fill("");

  await page.getByRole("button", { name: /Default Tools/ }).click();
  await expect(
    page.getByRole("group", { name: /Resolved tools/ }),
  ).toBeVisible();
  await expect(page.getByRole("checkbox", { name: "read_file" })).toBeVisible();
});

test("Schedules renders and refreshes read-only jobs", async ({ page }) => {
  await openConnected(page, "/tasks");

  await expect(
    page.getByText("Read-only schedule inventory.", { exact: false }),
  ).toBeVisible();
  const job = page.getByRole("group", { name: /Morning check/ });
  await expect(job).toHaveAccessibleName(/Every day at 09:00/);
  await expect(page.getByRole("checkbox", { name: "Enabled" })).toBeVisible();
  await page.getByRole("button", { name: "Refresh schedules" }).click();
  await expect(
    page.getByRole("group", { name: /Morning check/ }),
  ).toBeVisible();
});

test("Gateway status renders and refreshes bounded health", async ({
  page,
}) => {
  await openConnected(page, "/gateway");

  const status = page.getByRole("group").filter({ hasText: "Healthy" }).last();
  await expect(status).toContainText("hermes-agent");
  await expect(status).toContainText("0.16.0");
  await page.getByRole("button", { name: "Refresh gateway status" }).click();
  await expect(status).toContainText("Healthy");
});

test("Voice settings exposes keyboard-accessible local preference switches", async ({
  page,
}) => {
  await openConnected(page, "/settings/voice");

  const speakReplies = page.getByRole("switch", {
    name: /Speak replies aloud/,
  });
  await expect(speakReplies).not.toBeChecked();
  await speakReplies.press("Space");
  await expect(speakReplies).toBeChecked();
});

test("Diagnostics reports connected inventory and confirms redacted export", async ({
  page,
}) => {
  await openConnected(page, "/settings/diagnostics");

  await expect(page.getByRole("heading", { name: "Connection" })).toBeVisible();
  await expect(
    page.getByText("Status Connected", { exact: true }),
  ).toBeVisible();
  await expect(
    page.getByText("Runs SSE enabled", { exact: false }),
  ).toBeVisible();
  await expect(
    page.getByRole("group", {
      name: "Resources 1 models • 2 skills • 1 toolsets • 1 jobs",
    }),
  ).toBeVisible();
  await page.context().grantPermissions(["clipboard-read", "clipboard-write"]);
  await page.getByRole("button", { name: /Copy diagnostics/ }).click();
  await expect(
    page.getByText("Hermes diagnostics copied").last(),
  ).toBeVisible();
});
