# ADR 0002: Use Riverpod providers for app seams and test overrides

Status: accepted
Date: 2026-07-07

## Context

The Flutter app uses `flutter_riverpod`. `WingApp` wraps the app in `ProviderScope`, `routerProvider` supplies the router, `hermesChannelProvider` owns the default `HermesApiChannel`, and the Hermes chat screen exposes provider seams for voice capture and text-to-speech.

E2E builds also override `hermesChannelProvider` to install a test-owned `HermesApiChannel` while keeping the normal router and widgets.

## Decision

Use Riverpod providers as the app's dependency injection seam for app-level services and test adapters. Production defaults live in providers; tests and E2E entry points override providers rather than wiring global singletons.

## Consequences

- Runtime services can be substituted in widget tests and Playwright E2E without changing UI code.
- Provider defaults must avoid exposing secrets and must dispose owned resources.
- Do not introduce a second global service-locator pattern for Hermes, voice, or routing.

## Evidence

- `pubspec.yaml:12`
- `lib/app/wing_app.dart:1-30`
- `lib/router/providers/app_router.dart:10-42`
- `lib/features/hermes_chat/providers/hermes_channel_provider.dart:13-37`
- `lib/features/hermes_chat/screens/hermes_chat_screen.dart:37-44`
- `lib/main_e2e.dart:53-58`
