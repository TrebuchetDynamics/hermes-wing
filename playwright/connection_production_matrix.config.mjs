import { defineConfig } from '@playwright/test';
import { fileURLToPath } from 'node:url';

export default defineConfig({
  name: 'connection-production-matrix',
  testDir: './tests/regression',
  testMatch: 'connection-production-matrix.spec.mjs',
  timeout: 120000,
  expect: { timeout: 15000 },
  retries: 0,
  workers: 1,
  outputDir: './.matrix-results',
  reporter: [['list'], ['json', { outputFile: './.matrix-results/results.json' }]],
  use: { headless: true, baseURL: 'http://127.0.0.1:18995', reducedMotion: 'reduce',
    launchOptions: { executablePath: process.env.CHROME_EXECUTABLE ?? '/usr/bin/chromium', args: ['--no-sandbox'] } },
  webServer: {
    cwd: fileURLToPath(new URL('../', import.meta.url)),
    command: 'PORT=18995 HERMES_E2E_PORT=18996 node serve_web.mjs',
    url: 'http://127.0.0.1:18995',
    reuseExistingServer: false,
    timeout: 10000,
  },
});
