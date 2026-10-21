+++
schema = 1
id = "CONNECTION-OWNER-RECONNECT-LIVE"
title = "Live checks for CONNECTION-OWNER-RECONNECT"
short = "Live checks for CONNECTION-OWNER-RECONNECT"
status = "open"
goal = "CONNECTION-PATHS"
section = "Needs decision"
rank = 27000
depends_on = ["CONNECTION-OWNER-RECONNECT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for CONNECTION-OWNER-RECONNECT left pending."
acceptance = ["Each check passes on the real target: - Native desktop/Android exact-owner reconnect with platform secure storage and an authenticated unmodified Hermes Agent requires separate qualification. - Live Agent/provider continuation and recovery require separate runtime evidence; the opt-in live browser case was not enabled."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](../../docs/product/prd.md#connection-path-requirements), [retained offline task history](../../todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
