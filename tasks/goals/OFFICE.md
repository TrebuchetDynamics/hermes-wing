+++
schema = 1
id = "OFFICE"
title = "Retire non-reference Office while preserving official Agent access"
priority = 4
source = "docs/adr/product.md#official-desktop-features-only"
status = "met"
focus = false
depends_on = []
+++

- Evidence: executed: flutter test --no-pub --concurrency=1 (947 affected regressions) and compiled Chromium browser-surfaces/desktop-navigation-groups (13 passed); independent native review approved exact 3fb1b2976ea2ef5d695c5a929fb25465178b5e6b; docs/quality/office-retirement.md; integration 2d7cd8c45fe52fb4838e2e168c0aaa7ebe760720 preserves tested product tree; native/live/full-parity NOT_CHECKED (pass)
- Evidence: inspection: docs/product/hermes-desktop-parity.md#statuses (pass)
- Evidence: inspection: docs/quality/office-contact-session-reference.md (pass)
