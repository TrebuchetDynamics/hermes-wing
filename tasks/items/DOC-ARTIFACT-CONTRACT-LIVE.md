+++
schema = 1
id = "DOC-ARTIFACT-CONTRACT-LIVE"
title = "Live checks for DOC-ARTIFACT-CONTRACT"
short = "Live checks for DOC-ARTIFACT-CONTRACT"
status = "open"
goal = "ARTIFACTS"
section = "Needs decision"
rank = 34000
depends_on = ["DOC-ARTIFACT-CONTRACT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-ARTIFACT-CONTRACT left pending."
acceptance = ["Each check passes on the real target: - No application/platform or live Agent artifact retrieval/preview/save was exercised. Any future implementation needs separate named-platform/live authentication, hostile-content and persistence qualification; the artifact operation remains unavailable in Wing."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](../../docs/product/hermes-desktop-parity.md#statuses), [retained offline task history](../../todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
