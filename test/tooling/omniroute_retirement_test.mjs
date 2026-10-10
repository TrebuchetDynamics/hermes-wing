import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import test from 'node:test';

const root = new URL('../../', import.meta.url);
test('Wing ships no OmniRoute runtime, client control, release entry or CI installer', () => {
  assert.equal(existsSync(new URL('wing_link/internal/app/omniroute_assets/package.json', root)), false);
  const paths = execFileSync('git', ['ls-files', 'lib', '.github', 'wing_link/internal/release', 'wing_link/internal/app', 'wing_link/internal/protocol'], { cwd: root, encoding: 'utf8' }).trim().split('\n');
  for (const path of paths) {
    if (path.endsWith('_test.go') || !existsSync(new URL(path, root))) continue;
    // Preserve the dependency-review citation to historical license evidence.
    const active = readFileSync(new URL(path, root), 'utf8').replace(/^.*# for these exact versions is in docs\/quality\/omniroute-install-review\.md\.\n/m, '');
    assert.equal(/omniroute/i.test(active), false, path);
  }
  const workflow = readFileSync(new URL('.github/workflows/hermes-platform-smoke.yml', root), 'utf8');
  assert.match(workflow, /npm audit --audit-level=high/);
  assert.match(workflow, /flutter analyze/);
});
