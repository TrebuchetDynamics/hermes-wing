import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import assert from 'node:assert/strict';

test('native artifact producers and receipt consumers agree exactly once', () => {
  const expected = ['wing-ios-simulator-app', 'wing-macos-debug-app', 'wing-windows-debug-bundle'];
  const workflow = readFileSync('.github/workflows/hermes-platform-smoke.yml', 'utf8');
  const names = [...workflow.matchAll(/uses: actions\/upload-artifact[^\n]*\n\s+with:\n\s+name: ([^\n]+)/g)]
    .map(match => match[1]).filter(name => /windows|ios|macos/.test(name)).sort();
  assert.deepEqual(names, expected);
  for (const path of ['scripts/run_hermes_platform_workflow.sh', 'scripts/audit_hermes_readiness.sh']) {
    const source = readFileSync(path, 'utf8');
    const block = source.match(/(?:required_native_artifacts =|for artifact in) \[([\s\S]*?)\]/)[1];
    assert.deepEqual([...block.matchAll(/'([^']+)'/g)].map(match => match[1]).sort(), expected);
  }
});
