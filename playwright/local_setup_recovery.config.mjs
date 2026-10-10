import { defineConfig } from '@playwright/test';
import { fileURLToPath } from 'node:url';

export default defineConfig({
  testDir: './tests/regression',
  testMatch: 'local-setup-recovery.spec.mjs',
  timeout: 90000,
  expect: { timeout: 10000 },
  retries: 0,
  workers: 1,
  outputDir: '../.dart_tool/local-setup-recovery-evidence',
  reporter: [['list'], ['json', { outputFile: fileURLToPath(new URL('../.dart_tool/local-setup-recovery-evidence/results.json', import.meta.url)) }]],
  use: {
    headless: true,
    baseURL: 'http://127.0.0.1:18997',
    launchOptions: { executablePath: process.env.CHROME_EXECUTABLE ?? '/usr/bin/chromium', args: ['--no-sandbox'] },
  },
  webServer: {
    cwd: fileURLToPath(new URL('../', import.meta.url)),
    command: 'python -m http.server 18997 --bind 127.0.0.1 --directory .dart_tool/local-setup-recovery/build/web',
    url: 'http://127.0.0.1:18997',
    reuseExistingServer: false,
    timeout: 10000,
  },
});
