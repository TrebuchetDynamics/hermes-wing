"""Remote launcher boundary tests, no GTK or personal state."""
import importlib.util
import json
import os
import pathlib
import tarfile
import tempfile
import unittest
from unittest import mock

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('retry_native', ROOT / 'scripts/support/remote_connection_retry_native.py')
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class RemoteRetryNativeTests(unittest.TestCase):
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

    def test_freeze_attributes_owned_and_inherited_without_overlay(self):
        _, snapshot = module.helpers()
        self.assertEqual(snapshot.OVERLAYS, ())
        identity = {'inputs': {module.OWNED[0]: {'dirty': True}, 'lib/a.dart': {'dirty': True}}}
        with mock.patch.object(snapshot, 'freeze', return_value=identity):
            value = module.freeze(ROOT, ROOT / 'unused', snapshot)
        self.assertEqual(value['inputs'][module.OWNED[0]]['owner'], module.CARD)
        self.assertEqual(value['inputs']['lib/a.dart']['owner'], 'preexisting-worktree')

    def test_go_closure_is_copied_archived_and_fenced_from_shared_cache(self):
        _, snapshot = module.helpers()
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            shared, root, evidence = base / 'shared', base / 'owned', base / 'evidence'
            root.mkdir()
            evidence.mkdir()
            directory = shared / 'example.org/module@v1.0.0'
            directory.mkdir(parents=True)
            (directory / 'source.go').write_text('package example')
            directory.chmod(0o500)
            metadata = shared / 'cache/download/example.org/module/@v'
            metadata.mkdir(parents=True)
            (metadata / 'v1.0.0.mod').write_text('module example.org/module')
            (metadata / 'v0.9.0.mod').write_text('module example.org/module')
            (metadata / 'v1.0.0.lock').touch()
            row = dict(Path='example.org/module', Version='v1.0.0',
                       Dir=str(directory), GoMod=str(metadata / 'v1.0.0.mod'),
                       Sum='synthetic', GoModSum='synthetic')
            env = dict(GOMODCACHE=str(shared), GOPROXY='off', GOSUMDB='off')
            def output(command, **kwargs):
                if command[1] == 'mod':
                    self.assertEqual(command, ['go', 'mod', 'download', '-json'])
                    return json.dumps(row).encode()
                self.assertEqual(kwargs['env']['GOMODCACHE'], str(root / 'go-modules'))
                return b'go version synthetic' if command[1] == 'version' else b'example.org/module'
            with mock.patch.object(module.subprocess, 'check_output', side_effect=output):
                value = module.go_dependencies(ROOT, root, evidence, env, snapshot)
            self.assertTrue(value['isolated_module_cache'])
            self.assertEqual(env['GOFLAGS'], '-p=2 -mod=readonly')
            self.assertEqual((root / 'go-modules/example.org/module@v1.0.0').stat().st_mode & 0o777, 0o700)
            manifest = json.loads((evidence / 'go-dependencies.json').read_text())
            self.assertEqual(len(manifest), 3)
            with tarfile.open(evidence / 'executed-go-modules.tar.gz') as archive:
                self.assertEqual(set(archive.getnames()), set(manifest))
                for name, checksum in manifest.items():
                    member = archive.extractfile(name)
                    assert member is not None
                    self.assertEqual(module.hashlib.sha256(member.read()).hexdigest(), checksum)
            directory.chmod(0o700)
            (directory / 'source.go').write_text('shared mutation')
            module.verify_go_dependencies(root, evidence, snapshot)
            (root / 'go-modules/example.org/module@v1.0.0/source.go').write_text('owned mutation')
            with self.assertRaises(ValueError):
                module.verify_go_dependencies(root, evidence, snapshot)

    def test_go_closure_rejects_missing_or_external_module_source(self):
        _, snapshot = module.helpers()
        for row in ({'Error': 'offline missing'},
                    {'Dir': '/outside', 'GoMod': '/outside/module.mod'}):
            with tempfile.TemporaryDirectory() as tmp:
                root = pathlib.Path(tmp)
                with mock.patch.object(module.subprocess, 'check_output', return_value=json.dumps(row).encode()):
                    with self.assertRaises(ValueError):
                        module.go_dependencies(ROOT, root, root, {'GOMODCACHE': str(root / 'shared')}, snapshot)

    def test_receipt_requires_every_recovery_and_zero_forbidden_operations(self):
        value = dict(native_pid=1, width=390.0, text_scale=2.0, profile='synthetic-qa',
            session='synthetic-history', management_attempts=0, mutation_attempts=0, forbidden_read_attempts=0,
            auth_connects=1, auth_saves=0, retry_connects=1, retry_saves=1, save_attempts=6, save_commits=3,
            auth_profile='default', auth_session='synthetic-history',
            physical_keychain='NOT_CHECKED',
            late_cases=[{'reject': reject, 'replacement': replacement, 'fenced': True}
                for reject in (False, True) for replacement in (False, True)],
            requests=[{'method': 'GET', 'path': '/health', 'query': {}}],
            denied_reads=[{'status': 401, 'path': '/v1/capabilities', 'profile': None}])
        for key in ('public_entry', 'denial_sanitized', 'explicit_keyboard_retry', 'connected_draft_retained'):
            value[key] = True
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / 'receipt.json'
            path.write_text(json.dumps(value))
            self.assertEqual(module.read_receipt(path), value)
            for key, changed in [('mutation_attempts', 1), ('management_attempts', 1),
                                 ('late_cases', []), ('width', 800), ('retry_saves', 2),
                                 ('physical_keychain', 'PASS'),
                                 ('requests', [{'method': 'POST', 'path': '/health', 'query': {}}])]:
                path.write_text(json.dumps(value | {key: changed}))
                with self.assertRaises(ValueError):
                    module.read_receipt(path)
            path.unlink()
            path.symlink_to('missing')
            with self.assertRaises(ValueError):
                module.read_receipt(path)


if __name__ == '__main__':
    unittest.main()
