"""Dispatch/preflight regressions; stubbed tools are not Android evidence."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
APPROVALS = "scripts/maestro/fixture/approvals_recovery.yaml"
ATTACHMENT = "scripts/maestro/fixture/attachment_picker_race.yaml"


class FeatureWrapperTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.log = self.root / "calls"
        for name in ("adb", "flutter", "maestro"):
            tool = self.root / name
            tool.write_text(
                '#!/usr/bin/env bash\n'
                'printf "%s\\n" "$(basename "$0") $*" >> "$CALL_LOG"\n'
                'if [[ "$*" == *get-state* ]]; then\n'
                '  printf "%s\\n" "$STUB_STATE"\n'
                '  exit "${STUB_STATE_EXIT:-0}"\n'
                'fi\n'
            )
            tool.chmod(0o700)
        self.env = {
            **os.environ,
            "PATH": f"{self.root}:{os.environ['PATH']}",
            "WING_QA_DEVICE": "disposable-test-serial",
            "WING_QA_OUTPUT_DIR": str(self.root / "output"),
            "MAESTRO_BIN": str(self.root / "maestro"),
            "CALL_LOG": str(self.log),
            "STUB_STATE": "device",
        }

    def run_wrapper(self, *flows):
        return subprocess.run(
            ["bash", "scripts/run_android_maestro_features.sh", *flows],
            cwd=ROOT, env=self.env, text=True, capture_output=True, timeout=10,
        )

    def test_unknown_flow_rejected_before_tools(self):
        result = self.run_wrapper("scripts/maestro/live.yaml")
        self.assertEqual(result.returncode, 2)
        self.assertFalse(self.log.exists())
        self.assertFalse((self.root / "output").exists())

    def test_unreachable_or_unauthorized_target_never_builds_or_installs(self):
        for state in ("offline", "unauthorized", ""):
            with self.subTest(state=state):
                self.env["STUB_STATE"] = state
                result = self.run_wrapper(APPROVALS)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("flutter", self.log.read_text())
                self.assertNotIn("install", self.log.read_text())
                self.assertNotIn("maestro", self.log.read_text())
                self.assertFalse((self.root / "output").exists())

    def test_failed_state_command_cannot_claim_device(self):
        self.env["STUB_STATE_EXIT"] = "1"
        result = self.run_wrapper(APPROVALS)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("flutter", self.log.read_text())

    def test_subset_dispatches_only_selected_flows_on_explicit_serial(self):
        result = self.run_wrapper(APPROVALS, ATTACHMENT)
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.log.read_text().splitlines()
        self.assertEqual(calls[0], "adb -s disposable-test-serial get-state")
        syntax = [line for line in calls if "check-syntax" in line]
        self.assertEqual(syntax, [
            f"maestro check-syntax {APPROVALS}",
            f"maestro check-syntax {ATTACHMENT}",
        ])
        self.assertIn("integration_test/hermes_features_maestro_main.dart", calls[3])
        self.assertTrue(calls[4].startswith("adb -s disposable-test-serial install -r "))
        self.assertTrue(calls[5].startswith("maestro --device disposable-test-serial test "))
        self.assertTrue(calls[5].endswith(f"{APPROVALS} {ATTACHMENT}"))


if __name__ == "__main__":
    unittest.main()
