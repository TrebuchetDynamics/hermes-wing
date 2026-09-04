import { test } from 'node:test';
import assert from 'node:assert/strict';
import { TestResults, discoverTests } from '../../scripts/ci_test_receipt.mjs';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
function results(events = []) {
  const tracker = new TestResults(['test/a_test.dart']);
  for (const event of [
    { type: 'suite', suite: { id: 1, path: 'test/a_test.dart' } },
    { type: 'testStart', test: { id: 2, suiteID: 1 }, time: 0 },
    ...events,
  ]) tracker.event(event);
  return tracker;
}
const completed = { type: 'testDone', testID: 2, time: 25, result: 'success' };
const done = { type: 'done', success: true };
test('zero exit requires complete suite and terminal result inventory', () => {
  assert.equal(results([completed, done]).finish(0), 'success');
  assert.equal(results([completed]).finish(0), 'result-finalization-failure');
  assert.equal(results([done]).finish(0), 'result-finalization-failure');
  assert.equal(results([completed, completed, done]).finish(0), 'result-finalization-failure');
  assert.equal(results([completed, done, done]).finish(0), 'result-finalization-failure');
});
test('classifies assertion, infrastructure, timeout and missing suites', () => {
  assert.equal(results([{ ...completed, result: 'failure' }, done]).finish(1), 'assertion-failure');
  assert.equal(results().finish(1), 'infrastructure-failure');
  assert.equal(results().finish(1, true), 'timeout');
  const tracker = results([completed, done]); tracker.expected.add('test/new_test.dart');
  assert.equal(tracker.finish(0), 'result-finalization-failure');
  const loadFailure = new TestResults(['test/a_test.dart']);
  loadFailure.event({ type: 'suite', suite: { id: 1, path: 'test/a_test.dart' } });
  loadFailure.event({ type: 'testStart', test: { id: 2, suiteID: 1, name: 'loading test/a_test.dart' }, time: 0 });
  loadFailure.event({ type: 'error', testID: 2 });
  loadFailure.event({ type: 'done', success: false });
  assert.equal(loadFailure.finish(1), 'infrastructure-failure');
});
test('discovery excludes part fragments and finds newly added standalone tests', async t => {
  const root = await mkdtemp(join(tmpdir(), 'wing-test-discovery-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  assert.deepEqual(await discoverTests(root), []);
  await writeFile(join(root, 'fragment_test.dart'), "part of 'whole_test.dart';\n");
  await writeFile(join(root, 'whole_test.dart'), 'void main() {}\n');
  assert.deepEqual(await discoverTests(root), [join(root, 'whole_test.dart')]);
  await writeFile(join(root, 'new_test.dart'), 'void main() {}\n');
  assert.deepEqual(await discoverTests(root), [join(root, 'new_test.dart'), join(root, 'whole_test.dart')]);
});
test('empty, duplicate and unknown suite inventories fail closed', () => {
  assert.equal(new TestResults([]).finish(0), 'result-finalization-failure');
  for (const suite of [{ id: 1, path: 'test/a_test.dart' }, { id: 9, path: 'test/a_test.dart' }, { id: 9, path: 'test/unknown_test.dart' }]) {
    const tracker = results([completed, done]); tracker.event({ type: 'suite', suite });
    assert.equal(tracker.finish(0), 'result-finalization-failure');
  }
});
