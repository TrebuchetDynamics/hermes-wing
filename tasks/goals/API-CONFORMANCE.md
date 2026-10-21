+++
schema = 1
id = "API-CONFORMANCE"
title = "Verify owned code-first HTTP contract against handlers"
priority = 107
source = "docs/api/wing-link.openapi.yaml"
status = "unverified"
focus = false
depends_on = []
+++

- Evidence: executed: python3 .task-evidence/t_f2b5c61e/check_discovery.py; receipt: .task-evidence/t_f2b5c61e/validation.json and docs/quality/2026-10-06-wing-link-api-conformance.md (GET /meta and GET /healthz only; all 20 source hashes match; full API conformance unverified) (pass)
- Evidence: inspection: docs/api/wing-link.openapi.yaml (pass)
