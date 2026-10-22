+++
schema = 1
id = "LIVE-PARITY"
title = "Live qualifications for PARITY"
short = "Live qualifications"
status = "open"
goal = "PARITY"
section = "Needs decision"
rank = 1001
depends_on = ["LINUXQA-001-e41e98e5"]
touches = ["scripts/run_linux_feature_qualification.py", "test/tooling/linux_feature_qualification_runner_test.py", "integration_test/run_linux_shell_compact_return.py", "integration_test/run_linux_local_serve_reads.py", "integration_test/run_linux_transcript_keyboard.py"]
resources = []
kind = "implementation"
ownership = "owner"
scope = "Owner-authorized live checks accumulated from offline task closures in this goal."
acceptance = ["LINUXQA-001-e41e98e5: Actual Agent/SSH/OAuth/provider compatibility remains unrun on separately admitted disposable targets under PARITY-NATIVE-LINUX-LIVE and the existing live-workflow gates.", "LINUXQA-001-e41e98e5: Physical keyboard/window resize, Wayland/IME, screen reader, microphone/audio and exact packaged-artifact installation/update/removal qualification remain unrun on their existing target-specific gates."]
checks = ["Live qualification by an authorized person"]
exclusions = ["Offline evidence does not count"]
+++
