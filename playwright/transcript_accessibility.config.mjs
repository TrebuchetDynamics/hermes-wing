import { defineConfig } from '@playwright/test';

// Dedicated stateful fixture; never shares a listener or output with other suites.
export default defineConfig({
  testDir: './tests',
  testMatch: '**/chat-transcript-accessibility.spec.mjs',
  workers: 1,
  retries: 0,
  timeout: 180000,
  expect: { timeout: 10000 },
  preserveOutput: 'always',
  outputDir: '../.dart_tool/transcript-accessibility/observations',
  reporter: [['list']],
  use: { headless: true, actionTimeout: 8000 },
  projects: [{ name: 'chromium', use: { browserName: 'chromium' } }],
});
