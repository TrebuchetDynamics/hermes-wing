+++
schema = 1
id = "M1-MOBILE-AWAY-STATUS-LIVE"
title = "Live checks for M1-MOBILE-AWAY-STATUS"
short = "Live checks for M1-MOBILE-AWAY-STATUS"
status = "open"
goal = "M1"
section = "Needs decision"
rank = 21000
depends_on = ["M1-MOBILE-AWAY-STATUS"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for M1-MOBILE-AWAY-STATUS left pending."
acceptance = ["Each check passes on the real target: - Android acceptance remains NOT_CHECKED. Reestablish authenticated access to the selected isolated Waydroid QA target; verify Android release/API/ABI and existing QA APK/source/entrypoint digest, installed package equality and storage separation without replacing the paired app. - Run this task's full compact/enlarged-text Android away/return matrix: deterministic running-to-completed and running-to-failed while backgrounded, exact host/profile/session/run and canonical history, disconnect unknown then deliberate Retry, current exact approval grants and rejected late old-owner results. Record per-phase send/create/approval/Stop attempt counts; unobserved counts are not zero. Repair only reproduced Wing defects with focused regressions. Existing broad feature/YAML entries do not alone qualify this matrix."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](docs/product/prd.md#leading-acceptance-outcome), [retained offline task history](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
