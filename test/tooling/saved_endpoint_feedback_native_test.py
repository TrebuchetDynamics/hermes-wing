"""Saved-edit launcher admission and source/receipt boundaries."""
import importlib.util
import json
import os
import pathlib
import tempfile
import unittest
from typing import Any
from unittest import mock

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('saved_edit', ROOT / 'scripts/support/saved_endpoint_feedback_native.py')
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class SavedEditNativeTests(unittest.TestCase):
    def test_arguments_refuse_before_preparation(self):
        with mock.patch.object(module, 'run') as run:
            self.assertEqual(module.main(['--credential']), 2)
            run.assert_not_called()

    def test_environment_discards_shared_state(self):
        first, _ = module.helpers()
        with tempfile.TemporaryDirectory() as tmp:
            with mock.patch.dict(os.environ, {'DISPLAY': ':shared', 'HOME': '/private',
                 'DBUS_SESSION_BUS_ADDRESS': 'private', 'WING_LIVE_AUTH': 'forbidden',
                 'HTTPS_PROXY': 'private'}, clear=True), mock.patch.object(first.subprocess, 'check_output', return_value=b'/packages\n'):
                env = first.isolated_environment(pathlib.Path(tmp))
            for key in ('DISPLAY', 'DBUS_SESSION_BUS_ADDRESS', 'WING_LIVE_AUTH', 'HTTPS_PROXY'):
                self.assertNotIn(key, env)
            self.assertEqual(env['HOME'], tmp + '/home')
            self.assertEqual(env['CMAKE_BUILD_PARALLEL_LEVEL'], '2')

    def test_freeze_attributes_owned_without_replacing_inherited_inputs(self):
        _, snapshot = module.helpers()
        self.assertEqual(snapshot.OVERLAYS, ())
        identity = {'inputs': {module.OWNED[0]: {'dirty': True}, module.EDITOR: {'dirty': True}, 'lib/a.dart': {'dirty': True}}}
        with mock.patch.object(snapshot, 'freeze', return_value=identity), mock.patch.object(snapshot, 'digest', return_value='baseline'):
            value = module.freeze(ROOT, ROOT / 'unused', snapshot)
        self.assertEqual(value['inputs'][module.OWNED[0]]['owner'], module.CARD)
        self.assertEqual(value['inputs']['lib/a.dart']['owner'], 'preexisting-worktree')

    def test_receipt_requires_exact_discovery_only_and_all_journeys(self):
        value: dict[str, Any] = dict(native_pid=1, width=390.0, text_scale=2.0,
            physical_keychain='NOT_CHECKED', connect_delta=0, disconnect_delta=0,
            mutation_attempts=0, active_read_delta=0, save_commits=1, save_attempts=3,
            requests=[{'method': 'GET', 'path': '/v1/capabilities', 'query': {}, 'status': n}
                      for n in (403, 200, 500, 500)])
        for key in ('public_entry', 'keyboard_retry', 'cancel_no_mutation',
                    'pending_cancel_fenced', 'exact_id_peer_preserved',
                    'reopened_key_blank', 'owner_unchanged', 'feedback_readable',
                    'guidance_readable', 'bounded_keyboard_pages', 'draft_retained'):
            value[key] = True
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / 'receipt.json'
            path.write_text(json.dumps(value))
            self.assertEqual(module.read_receipt(path), value)
            for key, changed in [('mutation_attempts', 1), ('connect_delta', 1),
                                 ('pending_cancel_fenced', False), ('width', 800),
                                 ('physical_keychain', 'PASS'), ('save_commits', 2),
                                 ('feedback_readable', False), ('save_attempts', 4), ('requests', []), ('active_read_delta', 1)]:
                path.write_text(json.dumps(value | {key: changed}))
                with self.assertRaises(ValueError):
                    module.read_receipt(path)
            for method, route, query in [('POST', '/v1/capabilities', {}),
                                         ('GET', '/health', {}),
                                         ('GET', '/v1/capabilities', {'secret': 'synthetic'})]:
                changed = [dict(value['requests'][0], method=method, path=route, query=query), *value['requests'][1:]]
                path.write_text(json.dumps(value | {'requests': changed}))
                with self.assertRaises(ValueError):
                    module.read_receipt(path)
            path.unlink()
            path.symlink_to('missing')
            with self.assertRaises(ValueError):
                module.read_receipt(path)


if __name__ == '__main__':
    unittest.main()
