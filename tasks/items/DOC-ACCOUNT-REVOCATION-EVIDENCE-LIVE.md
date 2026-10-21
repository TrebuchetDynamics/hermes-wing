+++
schema = 1
id = "DOC-ACCOUNT-REVOCATION-EVIDENCE-LIVE"
title = "Live checks for DOC-ACCOUNT-REVOCATION-EVIDENCE"
short = "Live checks for DOC-ACCOUNT-REVOCATION-EVIDENCE"
status = "open"
goal = "ACCOUNT"
section = "Needs decision"
rank = 59000
depends_on = ["DOC-ACCOUNT-REVOCATION-EVIDENCE"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-ACCOUNT-REVOCATION-EVIDENCE left pending."
acceptance = ["Each check passes on the real target: - Separately authorized isolated-provider qualification of actual access-token expiry, rejected refresh and provider-side invalidation scope/acknowledgement; none executed here. - Separately authorized logout followed by authoritative root/pool/CLI resolution checks, in-flight login/refresh and cross-process races, and other-profile/device effects; source findings do not establish post-logout closure. - Current deployed Agent exact lifecycle capabilities/grants and named-platform secure-storage/end-to-end behavior remain unverified; no Wing account lifecycle operation is admitted by this study."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](../../docs/product/hermes-desktop-parity.md#statuses), [retained parent and qualifications](../../todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
