import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./playwright/tests",
  timeout: 60000,
  expect: { timeout: 10000 },
  retries: 1,
  preserveOutput: "always",
  // The local Hermes API mock is intentionally stateful across each user flow.
  workers: 1,
  use: {
    headless: true,
    viewport: { width: 1280, height: 900 },
    actionTimeout: 8000,
    launchOptions: {
      ...(process.env.CHROME_EXECUTABLE
        ? { executablePath: process.env.CHROME_EXECUTABLE }
        : {}),
      args: [
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--ignore-gpu-blocklist",
      ],
    },
  },
  projects: [
    {
      name: "chromium",
      use: { browserName: "chromium" },
    },
  ],
  reporter: [["list"], ["json", { outputFile: "playwright/results.json" }]],
});
