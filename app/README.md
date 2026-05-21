# Navivox Flutter App

This is the Flutter package for Navivox, the Android-first operator app for trusted local or self-hosted Gormes agents.

For product context and repo-level docs, start with `../README.md` and `../CONTEXT.md`.

## Development

```bash
flutter pub get
flutter test
flutter run
```

## Package Scope

This package owns the app UI and local client behavior:

- setup flow for a Gormes Navivox gateway
- profile contact and chat surfaces
- text and device-transcribed voice turns
- streaming assistant/system/tool UI
- safe connection, token, and recovery states

Server-side agent execution, provider calls, tools, sessions, secrets, and policy stay in Gormes.
