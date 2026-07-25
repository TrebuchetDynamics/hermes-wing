# Hermes Wing Playwright

Browser tests cover connection validation, all primary read-only surfaces, session search and selection, run stopping, connected chat workflows, delayed/denied/scoped approvals, browser TTS settings/playback/cancellation/queued replies/error recovery, disconnect cleanup, mobile controls, live Hermes API smoke, provider-backed chat, and route screenshots.

```bash
npm run web:e2e
```

Chat/TTS flows retain step screenshots under `test-results/regression-chat-tts-*`.

Live Hermes and provider tests remain skipped unless their documented `WING_*_HERMES_URL` environment variables are set.
