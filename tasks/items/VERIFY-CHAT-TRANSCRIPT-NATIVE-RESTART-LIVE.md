+++
schema = 1
id = "VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART-LIVE"
title = "Live checks for VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART"
short = "Live checks for VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART"
status = "open"
goal = "CHAT-FIDELITY"
section = "Needs decision"
rank = 70000
depends_on = ["VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART left pending."
acceptance = ["Each check passes on the real target: - Live unmodified Hermes Agent authentication, provider/tool execution and real approvals/Stop remain unqualified; no credentials, inference, upstream edits or live operations were used. - Physical mobile/Android, physical keyboard and screen-reader qualification remain separate. Native coverage here is Linux x86_64 GTK/Xvfb with injected key events and programmatic viewport preparation, not an entirely keyboard-only scrolling journey. - Full application saved-endpoint startup and OS secure-storage recovery are not qualified by this isolated Chat target; Linux selection preferences are real, while the run-lease store and HTTP/SSE transports are synthetic test seams."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [accepted port scope](ROADMAP.md#flutter-port-execution-roadmap), [retained VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART parent and qualifications](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
