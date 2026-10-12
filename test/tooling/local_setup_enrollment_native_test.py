"""Receipt admission must reject incomplete or replaying native journeys."""
import importlib.util
import pathlib
import json
import tempfile
import unittest

PATH = pathlib.Path(__file__).resolve().parents[2] / 'scripts/support/local_setup_enrollment_native.py'


class ReceiptTest(unittest.TestCase):
    def test_direct_receipt_requires_explicit_retry_and_zero_mutations(self):
        spec = importlib.util.spec_from_file_location('local_native', PATH)
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        value = dict(native_pid=123, width=390.0, text_scale=2.0,
                     inspect=3, mutations=0, forbidden_reads=0, route='/hermes',
                     direct_retry=True, no_automatic_replay=True,
                     direct_without_management=True)
        self.assertEqual(module.validate_receipt(value), value)
        for key, changed in [('inspect', 4), ('mutations', 1),
                             ('forbidden_reads', 1), ('no_automatic_replay', False),
                             ('direct_retry', False)]:
            with self.assertRaises(ValueError):
                module.validate_receipt(value | {key: changed})

    def test_packages_are_copied_and_plugin_paths_rebound(self):
        spec = importlib.util.spec_from_file_location('local_native', PATH)
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            app, sdk, package = root / 'app', root / 'sdk', root / 'original'
            (app / '.dart_tool').mkdir(parents=True)
            sdk.mkdir()
            package.mkdir()
            (package / 'sample.dart').write_text('original')
            config = {'packages': [{'name': 'sample', 'rootUri': package.as_uri()}]}
            (app / '.dart_tool/package_config.json').write_text(json.dumps(config))
            (app / '.flutter-plugins-dependencies').write_text(json.dumps({'plugins': {'linux': [{'path': str(package)}]}}))
            module.freeze_packages(app, root, sdk)
            (package / 'sample.dart').write_text('changed')
            self.assertEqual((root / 'packages/sample/sample.dart').read_text(), 'original')
            plugins = json.loads((app / '.flutter-plugins-dependencies').read_text())
            self.assertEqual(plugins['plugins']['linux'][0]['path'], str(root / 'packages/sample') + '/')


if __name__ == '__main__':
    unittest.main()
