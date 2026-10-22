+++
schema = 1
id = "LIVE-CONNECTION-PATHS"
title = "Live qualifications for CONNECTION-PATHS"
short = "Live qualifications"
status = "open"
goal = "CONNECTION-PATHS"
section = "Needs decision"
rank = 18001
depends_on = ["CONNECTION-LINK-REMOVAL"]
touches = ["lib/router/", "lib/features/enrollment/", "lib/features/local_setup/", "lib/features/profiles/", "lib/features/providers/", "lib/features/gateway/", "lib/core/hermes/", "android/app/src/", "test/router/", "test/features/enrollment/", "test/features/local_setup/", "test/features/profiles/", "test/features/providers/", "test/features/gateway/", "test/core/", "test/fixtures/", "integration_test/", "lib/l10n/app_en.arb", "lib/l10n/app_localizations*.dart", "docs/product/enrollment.md", "docs/product/desktop-connection-paths.md", "docs/product/routes.md", "docs/adr/product.md"]
resources = []
kind = "implementation"
ownership = "owner"
scope = "Owner-authorized live checks accumulated from offline task closures in this goal."
acceptance = ["CONNECTION-LINK-REMOVAL: Named Android device/emulator cold/warm intent classification, FlutterActivity/plugin lifecycle, actual Termux preparation/migration, physical keystore and assistive-technology output remain unqualified. Standalone Kotlin compilation and platform-overridden widget tests do not establish these outcomes.", "CONNECTION-LINK-REMOVAL: Existing CONNECTION-SETUP-AUTH-MATRIX/native owners retain actual Linux OS chooser, platform secure storage and approved live Local/SSH/Remote authentication/reconnect qualification with exact host/profile/session preservation and zero mutation replay. No live service, credential discovery, provider inference or personal installation operation was performed.", "CONNECTION-LINK-REMOVAL: Coordinator integration and merged-tree qualification remain separate from this local commit; the aggregate CONNECTION-PATHS/native/live acceptance is not claimed complete."]
checks = ["Live qualification by an authorized person"]
exclusions = ["Offline evidence does not count"]
+++
