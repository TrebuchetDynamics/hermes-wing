+++
schema = 1
id = "DOC-VOICE-QUALIFICATION-LIVE"
title = "Live checks for DOC-VOICE-QUALIFICATION"
short = "Live checks for DOC-VOICE-QUALIFICATION"
status = "open"
goal = "VOICE"
section = "Needs decision"
rank = 44000
depends_on = ["DOC-VOICE-QUALIFICATION"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-VOICE-QUALIFICATION left pending."
acceptance = ["Each check passes on the real target: - Obtain separately approved physical Android target and capture consent, including OS recognizer processing and any permission denial/revoke testing; name actual device, recognizer package/version, effective locale and built-in microphone route. No device was selected or operated. - After isolated QA authentication, provider budget and exact installed-artifact identification are available, execute actual capture -> reviewed draft -> explicit Send plus cancel, permission/no-speech failure, explicit recovery and diagnostic privacy observations. No audio, recognized words or observation receipt was collected; all physical outcomes remain NOT_CHECKED. - Output cancellation/TTS, provider reply, hands-free/re-arm, broader ownership scenarios, wired/Bluetooth routes and acoustic behavior require separately approved named-target execution. This input-only preparation cannot satisfy the existing sanitized physical-voice recorder's broader gates or close VOICE acceptance."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](../../docs/product/prd.md#core-journeys), [retained offline task history](../../todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
