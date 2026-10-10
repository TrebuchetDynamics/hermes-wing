"""Receipt admission must reject incomplete or replaying native journeys."""
import importlib.util
import pathlib
import json
import tempfile
import unittest

PATH = pathlib.Path(__file__).resolve().parents[2] / 'scripts/support/local_setup_enrollment_native.py'


class ReceiptTest(unittest.TestCase):
    def test_replayed_setup_is_rejected(self):
        spec = importlib.util.spec_from_file_location('local_native', PATH)
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        value = dict(native_pid=123, width=390.0, text_scale=2.0,
                     inspect=9, setup=7, cancel=4, management=0, mutations=0,
                     forbidden_reads=0, route='/hermes', consent=True,
                     explicit_continue=True, late_results_fenced=True,
                     inspection_only_retry=True, direct_without_management=True)
        with self.assertRaises(ValueError):
            module.validate_receipt(value)

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
