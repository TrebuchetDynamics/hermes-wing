import { spawn } from 'node:child_process';
import { readdir, readFile, mkdir, writeFile, rm } from 'node:fs/promises';
import { resolve, relative, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createInterface } from 'node:readline';
import { createWriteStream } from 'node:fs';

export async function discoverTests(root = 'test') {
  const result = [];
  async function visit(directory) {
    for (const item of await readdir(directory, { withFileTypes: true })) {
      const path = join(directory, item.name);
      if (item.isDirectory()) await visit(path);
      else if (item.isFile() && path.endsWith('_test.dart') && !/^\s*part of\s/m.test(await readFile(path, 'utf8'))) result.push(resolve(path));
    }
  }
  await visit(root);
  return result.sort();
}
export class TestResults {
  constructor(expected) {
    this.expected = new Set(expected);
    this.suites = new Map(); this.active = new Map(); this.completed = new Set();
    this.done = null; this.errors = false; this.infrastructureError = false; this.invalid = false;
  }
  event(event) {
    if (event.type === 'suite') {
      const { id, path } = event.suite;
      if (this.suites.has(id) || !this.expected.has(path) || [...this.suites.values()].some(suite => suite.path === path)) this.invalid = true;
      this.suites.set(id, { path, elapsed_ms: 0, tests: 0 });
    } else if (event.type === 'testStart') {
      if (this.active.has(event.test.id) || this.completed.has(event.test.id) || !this.suites.has(event.test.suiteID)) this.invalid = true;
      this.active.set(event.test.id, { suiteID: event.test.suiteID, start: event.time,
        loading: event.test.name?.startsWith('loading ') === true });
    } else if (event.type === 'testDone') {
      const active = this.active.get(event.testID);
      if (!active || this.completed.has(event.testID)) { this.invalid = true; return; }
      const suite = this.suites.get(active.suiteID);
      if (!suite || !Number.isFinite(event.time) || event.time < active.start) { this.invalid = true; return; }
      suite.elapsed_ms += event.time - active.start; suite.tests++;
      this.completed.add(event.testID); this.active.delete(event.testID);
      if (event.result !== 'success') this.errors = true;
    } else if (event.type === 'error') {
      if (this.active.get(event.testID)?.loading) this.infrastructureError = true;
      else this.errors = true;
    }
    else if (event.type === 'done') {
      if (this.done !== null) this.invalid = true;
      this.done = event.success;
    }
  }
  finish(exitCode, timedOut = false) {
    if (timedOut) return 'timeout';
    if (this.infrastructureError) return 'infrastructure-failure';
    if (this.errors || this.done === false) return 'assertion-failure';
    if (exitCode !== 0) return 'infrastructure-failure';
    if (this.invalid || this.done !== true || this.active.size || !this.completed.size ||
        this.expected.size !== this.suites.size || [...this.suites.values()].some(suite => !suite.tests)) return 'result-finalization-failure';
    return 'success';
  }
}
async function main() {
  await rm('build/receipts/flutter-ci-timing.json', { force: true });
  const expected = await discoverTests();
  if (!expected.length) throw new Error('No standalone tests discovered');
  const results = new TestResults(expected);
  const start = Date.now();
  await mkdir('build/receipts', { recursive: true });
  const log = createWriteStream('build/flutter-ci-test.log', { flags: 'w', mode: 0o600 });
  const child = spawn('flutter', ['test', '--machine', '--coverage', '--concurrency=1'], { stdio: ['ignore', 'pipe', 'pipe'] });
  child.stdout.pipe(log, { end: false });
  child.stderr.pipe(log, { end: false });
  let timedOut = false;
  let killTimer;
  const timeout = setTimeout(() => {
    timedOut = true; child.kill('SIGTERM');
    killTimer = setTimeout(() => child.kill('SIGKILL'), 10000);
  }, 30 * 60 * 1000);
  const lines = createInterface({ input: child.stdout });
  lines.on('line', line => {
    if (!line.trim()) return;
    try {
      const event = JSON.parse(line);
      results.event(event);
      if (event.type === 'error') console.error(`Flutter test error: ${event.error}`);
    } catch { results.invalid = true; }
  });
  const progress = setInterval(() => {
    console.log(`Flutter tests: ${results.completed.size} completed; ${results.suites.size}/${expected.length} suites discovered; ${Math.round((Date.now() - start) / 1000)}s.`);
  }, 30000);
  // Full diagnostics stay in ignored build output, never the public timing receipt.
  const code = await new Promise(resolveExit => {
    child.on('error', () => resolveExit(-1)); child.on('close', resolveExit);
  });
  clearTimeout(timeout); clearTimeout(killTimer); clearInterval(progress);
  await new Promise(resolveLog => log.end(resolveLog));
  const outcome = results.finish(code, timedOut);
  await mkdir('build/receipts', { recursive: true });
  await writeFile('build/receipts/flutter-ci-timing.json', JSON.stringify({
    schema_version: 1, outcome, elapsed_ms: Date.now() - start,
    expected_suites: expected.length, completed_tests: results.completed.size,
    suites: [...results.suites.values()].filter(suite => results.expected.has(suite.path))
      .map(suite => ({ ...suite, path: relative(process.cwd(), suite.path).replaceAll('\\', '/') })),
  }, null, 2) + '\n');
  console.log(`Flutter tests: ${outcome}; ${results.completed.size} completed results; ${results.suites.size}/${expected.length} suites.`);
  console.log('Full Flutter diagnostics: build/flutter-ci-test.log (local/CI log, not a qualification receipt).');
  if (outcome !== 'success') process.exitCode = 1;
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch(() => { console.error('Flutter test receipt failed.'); process.exitCode = 1; });
}
