import { test, expect } from "@playwright/test";
import {
  APP_URL as APP,
  enableFlutterAccessibility as a11y,
} from "../../support/flutter_semantics.mjs";

async function installSpeechSynthesisRecorder(page) {
  await page.addInitScript(() => {
    const state = {
      utterances: [],
      speakAttempts: 0,
      cancelCount: 0,
      throwOnSpeak: false,
      current: null,
      finish() {
        const utterance = state.current;
        state.current = null;
        utterance?.onend?.(new Event("end"));
      },
      fail() {
        const utterance = state.current;
        state.current = null;
        utterance?.onerror?.({ error: "synthesis-failed" });
      },
    };
    const synth = globalThis.speechSynthesis;
    Object.defineProperties(synth, {
      speak: {
        configurable: true,
        value(utterance) {
          state.speakAttempts += 1;
          if (state.throwOnSpeak) throw new Error("Synthetic speech failure");
          state.current = utterance;
          state.utterances.push({
            text: utterance.text,
            rate: utterance.rate,
            pitch: utterance.pitch,
            volume: utterance.volume,
          });
          queueMicrotask(() => utterance.onstart?.(new Event("start")));
        },
      },
      cancel: {
        configurable: true,
        value() {
          state.cancelCount += 1;
          state.finish();
        },
      },
      getVoices: { configurable: true, value: () => [] },
      pause: { configurable: true, value() {} },
      resume: { configurable: true, value() {} },
    });
    globalThis.wingE2ESpeech = state;
  });
}

async function installAgentAudioRecorder(page, { autoFinish = false } = {}) {
  await page.addInitScript((finishAutomatically) => {
    const state = {
      plays: [],
      pauseCount: 0,
      current: null,
      failPlay: false,
      finish() {
        state.current?.dispatchEvent(new Event("ended"));
      },
      fail() {
        state.current?.dispatchEvent(new Event("error"));
      },
    };
    Object.defineProperties(HTMLMediaElement.prototype, {
      duration: { configurable: true, get: () => 0.1 },
      play: {
        configurable: true,
        value() {
          state.current = this;
          state.plays.push({ src: this.src });
          if (state.failPlay) {
            return Promise.reject(new Error("Synthetic Agent audio failure"));
          }
          this.dispatchEvent(new Event("play"));
          if (finishAutomatically) {
            setTimeout(() => this.dispatchEvent(new Event("ended")), 0);
          }
          return Promise.resolve();
        },
      },
      pause: {
        configurable: true,
        value() {
          state.pauseCount += 1;
        },
      },
    });
    globalThis.wingE2EAgentAudio = state;
  }, autoFinish);
}

async function screenshot(page, testInfo, name) {
  await page.mouse.move(0, 0);
  await page.waitForTimeout(200);
  await page.screenshot({
    path: testInfo.outputPath(`${name}.png`),
    fullPage: true,
  });
}

async function open(page, route) {
  await page.goto(`${APP}#${route}`, { timeout: 15000 });
  await page.waitForFunction(
    () => typeof globalThis.wingE2EHermesConnect === "function",
    null,
    { timeout: 30000 },
  );
  await a11y(page, { delay: 500 });
}

async function connect(page) {
  await page.evaluate(() => globalThis.wingE2EHermesConnect());
  await expect(
    page.getByRole("heading", { name: /E2E Hermes Session/ }),
  ).toBeVisible();
}

async function connectFromVoiceSettings(
  page,
  { faster = false, testInfo, agentAudio = true } = {},
) {
  await page.request.post(`${APP}e2e/hermes/audio`, {
    data: { enabled: agentAudio },
  });
  await open(page, "/settings/voice");
  const speakReplies = page.getByRole("switch", {
    name: /Speak replies aloud/,
  });
  await expect(speakReplies).not.toBeChecked();
  await speakReplies.press("Space");
  await expect(speakReplies).toBeChecked();
  if (faster) {
    const speed = page.getByRole("slider");
    await speed.fill("2");
    await expect(
      page.getByRole("group", { name: "Reply speed · 1.25×" }),
    ).toBeVisible();
  }
  if (testInfo) await screenshot(page, testInfo, "voice-settings-enabled");

  await page.evaluate(() => {
    location.hash = "/hermes";
  });
  await connect(page);
  if (testInfo) await screenshot(page, testInfo, "chat-connected");
}

async function submitComposer(page, text) {
  const composer = page.locator('textarea[data-semantics-role="text-field"]');
  await composer.click();
  await page.waitForTimeout(100);
  await composer.fill(text);
  await page.getByRole("button", { name: "Send", exact: true }).click();
}

async function sendChat(page, text, { testInfo, screenshotPrefix } = {}) {
  await submitComposer(page, text);
  await expect(page.getByText(text).first()).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Approve once" }),
  ).toBeVisible();
  if (testInfo)
    await screenshot(page, testInfo, `${screenshotPrefix}-approval`);
  await page.getByRole("button", { name: "Approve once" }).click();
  await expect(page.getByText(`Hermes echo: ${text}`).first()).toBeVisible();
  if (testInfo) await screenshot(page, testInfo, `${screenshotPrefix}-reply`);
}

async function expectVoiceInputAvailable(page) {
  const legacyDirectControl = page.getByRole("button", {
    name: "Speak and send",
  });
  const handsFreeControl = page.getByRole("button", {
    name: "Hands-free voice",
  });
  await expect
    .poll(async () =>
      (await legacyDirectControl.count()) + (await handsFreeControl.count()),
    )
    .toBeGreaterThan(0);
  if (await handsFreeControl.count()) {
    await expect(handsFreeControl).toBeVisible();
  } else {
    await expect(legacyDirectControl).toBeVisible();
  }
}

test.beforeEach(async ({ request }) => {
  const response = await request.post(`${APP}e2e/hermes/reset`);
  expect(response.ok()).toBeTruthy();
});

test("chat replies stay silent when Speak replies aloud is disabled", async ({
  page,
}, testInfo) => {
  await installSpeechSynthesisRecorder(page);
  await open(page, "/hermes");
  await connect(page);
  await screenshot(page, testInfo, "silent-chat-ready");

  await sendChat(page, "silent chat browser turn", {
    testInfo,
    screenshotPrefix: "silent-chat",
  });

  await expect
    .poll(() => page.evaluate(() => globalThis.wingE2ESpeech.utterances.length))
    .toBe(0);
  await expectVoiceInputAvailable(page);
  await expect(page.getByRole("button", { name: "Stop speaking" })).toHaveCount(
    0,
  );
});

test("unadvertised Agent audio never falls back to browser speech", async ({
  page,
}, testInfo) => {
  await installSpeechSynthesisRecorder(page);
  await connectFromVoiceSettings(page, { testInfo, agentAudio: false });

  await sendChat(page, "unsupported agent audio browser turn", {
    testInfo,
    screenshotPrefix: "unsupported-agent-audio",
  });

  await expect
    .poll(() => page.evaluate(() => globalThis.wingE2ESpeech.utterances.length))
    .toBe(0);
  await expect(page.getByRole("button", { name: "Stop speaking" })).toHaveCount(
    0,
  );
  await expect(page.getByText("Could not speak Hermes reply.")).toHaveCount(0);
});

test("Agent speech uses the exact endpoint and Stop speaking cancels playback", async ({
  page,
}, testInfo) => {
  await installAgentAudioRecorder(page);
  await connectFromVoiceSettings(page, { testInfo });
  await sendChat(page, "chat and tts browser turn", {
    testInfo,
    screenshotPrefix: "tts-agent",
  });
  await expect(
    page.getByRole("button", { name: "Stop speaking" }),
  ).toBeVisible();
  await expect
    .poll(() => page.evaluate(() => globalThis.wingE2EAgentAudio.plays.length))
    .toBe(1);
  const audioState = await page.request.get(`${APP}e2e/hermes/audio`);
  expect((await audioState.json()).spokenTexts).toEqual([
    "Hermes echo: chat and tts browser turn",
  ]);
  const pausesBeforeStop = await page.evaluate(
    () => globalThis.wingE2EAgentAudio.pauseCount,
  );

  await page.getByRole("button", { name: "Stop speaking" }).click();
  await expectVoiceInputAvailable(page);
  await expect
    .poll(() => page.evaluate(() => globalThis.wingE2EAgentAudio.pauseCount))
    .toBeGreaterThan(pausesBeforeStop);
  await expect(page.getByText("Could not speak Hermes reply.")).toHaveCount(0);
  await screenshot(page, testInfo, "tts-stopped");

  await sendChat(page, "speech after cancellation", {
    testInfo,
    screenshotPrefix: "tts-after-cancel",
  });
  await expect(
    page.getByRole("button", { name: "Stop speaking" }),
  ).toBeVisible();
  await expect
    .poll(() => page.evaluate(() => globalThis.wingE2EAgentAudio.plays.length))
    .toBe(2);
  await page.evaluate(() => globalThis.wingE2EAgentAudio.finish());
});

test("Agent speech returns to voice input after completion", async ({
  page,
}, testInfo) => {
  await installAgentAudioRecorder(page);
  await connectFromVoiceSettings(page, { testInfo });

  await sendChat(page, "first spoken browser turn", {
    testInfo,
    screenshotPrefix: "first-spoken",
  });
  await expect(
    page.getByRole("button", { name: "Stop speaking" }),
  ).toBeVisible();
  await page.evaluate(() => globalThis.wingE2EAgentAudio.finish());
  await expectVoiceInputAvailable(page);
  await screenshot(page, testInfo, "first-speech-completed");

  await sendChat(page, "second spoken browser turn", {
    testInfo,
    screenshotPrefix: "second-spoken",
  });
  await expect(
    page.getByRole("button", { name: "Stop speaking" }),
  ).toBeVisible();
  const audioState = await page.request.get(`${APP}e2e/hermes/audio`);
  expect((await audioState.json()).spokenTexts).toEqual([
    "Hermes echo: first spoken browser turn",
    "Hermes echo: second spoken browser turn",
  ]);
  await page.evaluate(() => globalThis.wingE2EAgentAudio.finish());
  await expectVoiceInputAvailable(page);
  await expect(page.getByText("Could not speak Hermes reply.")).toHaveCount(0);
});

test("local slash help never creates a Hermes run or speech", async ({
  page,
  request,
}, testInfo) => {
  await installSpeechSynthesisRecorder(page);
  await connectFromVoiceSettings(page, { testInfo });
  await screenshot(page, testInfo, "slash-help-ready");
  const runCountUrl = `${APP}e2e/hermes/run-count`;

  await submitComposer(page, "/help");

  await expect(
    page.getByText(
      "These commands run on this device and are never sent to Hermes Agent.",
    ),
  ).toBeVisible();
  await expect(
    page
      .locator("flt-semantics")
      .filter({ hasText: "/sessions Open session history." })
      .last(),
  ).toBeVisible();
  await screenshot(page, testInfo, "slash-help-sheet");
  await expect
    .poll(async () => (await (await request.get(runCountUrl)).json()).runCount)
    .toBe(0);
  await expect(page.getByRole("button", { name: "Approve once" })).toHaveCount(
    0,
  );
  expect(
    await page.evaluate(() => globalThis.wingE2ESpeech.utterances.length),
  ).toBe(0);
});

test("Markdown transcript export contains the visible chat without invoking TTS", async ({
  page,
}, testInfo) => {
  await installSpeechSynthesisRecorder(page);
  await open(page, "/hermes");
  await connect(page);
  await sendChat(page, "transcript browser turn", {
    testInfo,
    screenshotPrefix: "transcript-chat",
  });
  await page.context().grantPermissions(["clipboard-read", "clipboard-write"]);

  await page.getByRole("button", { name: "Copy transcript" }).click();
  await expect(
    page.getByRole("button", { name: "Copy as text" }),
  ).toBeVisible();
  await screenshot(page, testInfo, "transcript-format-options");
  await page.getByRole("button", { name: "Copy as Markdown" }).click();
  await expect(
    page.getByText("Transcript copied as Markdown").last(),
  ).toBeVisible();
  await screenshot(page, testInfo, "transcript-markdown-copied");

  const clipboard = await page.evaluate(() => navigator.clipboard.readText());
  expect(clipboard).toContain("transcript browser turn");
  expect(clipboard).toContain("Hermes echo: transcript browser turn");
  expect(
    await page.evaluate(() => globalThis.wingE2ESpeech.utterances.length),
  ).toBe(0);
});

test("Agent speech failure is bounded and recoverable", async ({
  page,
}, testInfo) => {
  await installAgentAudioRecorder(page);
  await connectFromVoiceSettings(page, { testInfo });
  await page.request.post(`${APP}e2e/hermes/audio`, {
    data: { enabled: true, fail: true },
  });

  await sendChat(page, "failing speech browser turn", {
    testInfo,
    screenshotPrefix: "tts-failure",
  });
  await expect(
    page.getByText("Could not speak Hermes reply.").last(),
  ).toBeVisible();
  await expectVoiceInputAvailable(page);
  await expect(page.getByRole("button", { name: "Stop speaking" })).toHaveCount(
    0,
  );
  await screenshot(page, testInfo, "tts-failure-notice");

  await page.request.post(`${APP}e2e/hermes/audio`, {
    data: { enabled: true, fail: false },
  });
  await sendChat(page, "recovered speech browser turn", {
    testInfo,
    screenshotPrefix: "tts-recovered",
  });
  await expect(
    page.getByRole("button", { name: "Stop speaking" }),
  ).toBeVisible();
  await expect
    .poll(() => page.evaluate(() => globalThis.wingE2EAgentAudio.plays.length))
    .toBe(1);
  const recoveredAudioState = await page.request.get(
    `${APP}e2e/hermes/audio`,
  );
  expect((await recoveredAudioState.json()).spokenTexts).toHaveLength(2);
  await page.evaluate(() => globalThis.wingE2EAgentAudio.finish());
});

test("Agent speech is cancelled when leaving chat", async ({
  page,
}, testInfo) => {
  await installAgentAudioRecorder(page);
  await connectFromVoiceSettings(page, { testInfo });
  await sendChat(page, "navigation speech browser turn", {
    testInfo,
    screenshotPrefix: "navigation-speech",
  });
  await expect(
    page.getByRole("button", { name: "Stop speaking" }),
  ).toBeVisible();
  const pausesBeforeNavigation = await page.evaluate(
    () => globalThis.wingE2EAgentAudio.pauseCount,
  );

  await page.evaluate(() => {
    location.hash = "/settings/voice";
  });
  await expect(
    page.getByRole("heading", { name: "Voice & speech" }),
  ).toBeVisible();
  await expect
    .poll(() => page.evaluate(() => globalThis.wingE2EAgentAudio.pauseCount))
    .toBeGreaterThan(pausesBeforeNavigation);
  const speakReplies = page.getByRole("switch", {
    name: /Speak replies aloud/,
  });
  await expect(speakReplies).toBeChecked();
  await speakReplies.press("Space");
  await expect(speakReplies).not.toBeChecked();
  await screenshot(page, testInfo, "tts-disabled-after-navigation");

  await page.evaluate(() => {
    location.hash = "/hermes";
  });
  await expect(page.getByRole("button", { name: "Sessions" })).toBeVisible();
  await sendChat(page, "silent after navigation browser turn", {
    testInfo,
    screenshotPrefix: "silent-after-navigation",
  });
  const navigationAudioState = await page.request.get(
    `${APP}e2e/hermes/audio`,
  );
  expect((await navigationAudioState.json()).spokenTexts).toHaveLength(1);
  await expect(page.getByRole("button", { name: "Stop speaking" })).toHaveCount(
    0,
  );
});

test("approval review exposes bounded details before chat continues", async ({
  page,
}, testInfo) => {
  await open(page, "/hermes");
  await connect(page);
  await page.context().grantPermissions(["clipboard-read", "clipboard-write"]);
  await submitComposer(page, "review approval browser turn");
  await expect(page.getByRole("button", { name: "Review" })).toBeVisible();
  await screenshot(page, testInfo, "approval-request-card");

  await page.getByRole("button", { name: "Review" }).click();
  await expect(page.getByText("Review Hermes approval")).toBeVisible();
  const approvalSheet = page
    .getByRole("group")
    .filter({ hasText: "Risk: low" })
    .last();
  await expect(approvalSheet).toContainText("Tool call: tool_e2e");
  await screenshot(page, testInfo, "approval-review-sheet");

  await page.getByRole("button", { name: "Copy details" }).click();
  await expect(
    page.getByText("Copied redacted Hermes approval details.").last(),
  ).toBeVisible();
  await screenshot(page, testInfo, "approval-details-copied");
  await expect
    .poll(() => page.evaluate(() => navigator.clipboard.readText()))
    .toContain("Approve e2e browser run?");
  await page.getByRole("button", { name: "Close" }).click();
  await page.getByRole("button", { name: "Approve once" }).click();
  await expect(
    page.getByText("Hermes echo: review approval browser turn").first(),
  ).toBeVisible();
  await expect(
    page.getByText("Hermes could not record the approval decision."),
  ).toHaveCount(0);
  await expect(page.getByRole("button", { name: "Approve once" })).toHaveCount(
    0,
  );
  await screenshot(page, testInfo, "approval-reviewed-reply");
});

test("a delayed mobile approval remains actionable until the operator decides", async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await open(page, "/hermes");
  await connect(page);
  await submitComposer(page, "delayed mobile approval browser turn");
  await expect(page.getByRole("button", { name: "Review" })).toBeVisible();
  await screenshot(page, testInfo, "mobile-delayed-approval");

  await page.waitForTimeout(1800);
  await expect(
    page.getByText("Hermes echo: delayed mobile approval browser turn"),
  ).toHaveCount(0);
  await page.getByRole("button", { name: "Review" }).click();
  await expect(page.getByText("Review Hermes approval")).toBeVisible();
  await expect(page.getByRole("button", { name: "Deny" })).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Approve once" }),
  ).toBeVisible();
  await screenshot(page, testInfo, "mobile-delayed-approval-review");

  await page.getByRole("button", { name: "Approve once" }).click();
  await expect(
    page.getByText("Hermes echo: delayed mobile approval browser turn"),
  ).toBeVisible();
  await expect(
    page.getByText("Hermes could not record the approval decision."),
  ).toHaveCount(0);
  await screenshot(page, testInfo, "mobile-delayed-approval-completed");
});

test("a compact phone can scroll every approval action into reach", async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ width: 320, height: 568 });
  await open(page, "/hermes");
  await connect(page);
  await submitComposer(page, "compact approval browser turn");
  await expect(page.getByRole("button", { name: "Review" })).toBeVisible();
  await screenshot(page, testInfo, "compact-approval-request");

  await page.getByRole("button", { name: "Review" }).click();
  await expect(page.getByText("Review Hermes approval")).toBeVisible();
  await screenshot(page, testInfo, "compact-approval-review-top");
  const approve = page.getByRole("button", { name: "Approve once" });
  await approve.scrollIntoViewIfNeeded();
  await expect(approve).toBeVisible();
  await screenshot(page, testInfo, "compact-approval-actions-reachable");
  await approve.click();
  await expect(
    page.getByText("Hermes echo: compact approval browser turn"),
  ).toBeVisible();
  await screenshot(page, testInfo, "compact-approval-completed");
});

test("denying an approval stays silent and returns chat to a usable state", async ({
  page,
}, testInfo) => {
  await installSpeechSynthesisRecorder(page);
  await connectFromVoiceSettings(page, { testInfo });
  await submitComposer(page, "denied spoken browser turn");
  await expect(page.getByRole("button", { name: "Deny" })).toBeVisible();
  await screenshot(page, testInfo, "denied-turn-approval");

  await page.getByRole("button", { name: "Deny" }).click();
  await expect(page.getByRole("button", { name: "Approve once" })).toHaveCount(
    0,
  );
  await expect(
    page.getByText("Hermes echo: denied spoken browser turn"),
  ).toHaveCount(0);
  await expect(
    page.getByRole("button", { name: /Tool activity: bash/ }),
  ).toHaveCount(0);
  await expectVoiceInputAvailable(page);
  expect(
    await page.evaluate(() => globalThis.wingE2ESpeech.utterances.length),
  ).toBe(0);
  await screenshot(page, testInfo, "denied-turn-ready");
});

test("Agent speech queues replies during playback", async ({
  page,
}, testInfo) => {
  await installAgentAudioRecorder(page);
  await connectFromVoiceSettings(page, { testInfo });
  await sendChat(page, "first queued speech browser turn", {
    testInfo,
    screenshotPrefix: "queued-speech-first",
  });
  await expect(
    page.getByRole("button", { name: "Stop speaking" }),
  ).toBeVisible();

  await sendChat(page, "second queued speech browser turn", {
    testInfo,
    screenshotPrefix: "queued-speech-second",
  });
  expect(
    await page.evaluate(() => globalThis.wingE2EAgentAudio.plays.length),
  ).toBe(1);
  await screenshot(page, testInfo, "queued-speech-waiting");

  await page.evaluate(() => globalThis.wingE2EAgentAudio.finish());
  await expect
    .poll(() => page.evaluate(() => globalThis.wingE2EAgentAudio.plays.length))
    .toBe(2);
  await expect(
    page.getByRole("button", { name: "Stop speaking" }),
  ).toBeVisible();
  const queuedAudioState = await page.request.get(`${APP}e2e/hermes/audio`);
  expect((await queuedAudioState.json()).spokenTexts.at(-1)).toBe(
    "Hermes echo: second queued speech browser turn",
  );
  await screenshot(page, testInfo, "queued-speech-second-speaking");
  await page.evaluate(() => globalThis.wingE2EAgentAudio.finish());
});

test("Agent speech stops when starting a new session", async ({
  page,
}, testInfo) => {
  await installAgentAudioRecorder(page);
  await connectFromVoiceSettings(page, { testInfo });
  await sendChat(page, "old session active speech browser turn", {
    testInfo,
    screenshotPrefix: "session-change-old-speech",
  });
  await expect(
    page.getByRole("button", { name: "Stop speaking" }),
  ).toBeVisible();
  const pausesBeforeSessionChange = await page.evaluate(
    () => globalThis.wingE2EAgentAudio.pauseCount,
  );

  await page.getByRole("button", { name: "New session" }).click();
  await expect(
    page.getByRole("heading", { name: /E2E Hermes Session \d+/ }),
  ).toBeVisible();
  await expect
    .poll(() => page.evaluate(() => globalThis.wingE2EAgentAudio.pauseCount))
    .toBeGreaterThan(pausesBeforeSessionChange);
  await expect(page.getByRole("button", { name: "Stop speaking" })).toHaveCount(
    0,
  );
  await expect(
    page.getByText("Hermes session changed. Spoken reply stopped."),
  ).toBeVisible();
  await expect(
    page.getByText("Hermes session changed. Continuous voice paused."),
  ).toHaveCount(0);
  expect(
    await page.evaluate(() => globalThis.wingE2EAgentAudio.plays.length),
  ).toBe(1);
  await screenshot(page, testInfo, "session-change-playback-cancelled");

  await sendChat(page, "new session spoken browser turn", {
    testInfo,
    screenshotPrefix: "session-change-new-speech",
  });
  await expect
    .poll(() => page.evaluate(() => globalThis.wingE2EAgentAudio.plays.length))
    .toBe(2);
  const sessionAudioState = await page.request.get(`${APP}e2e/hermes/audio`);
  expect((await sessionAudioState.json()).spokenTexts.at(-1)).toBe(
    "Hermes echo: new session spoken browser turn",
  );
  await page.evaluate(() => globalThis.wingE2EAgentAudio.finish());
});

test("Agent speech preference survives reload", async ({
  page,
}, testInfo) => {
  await installAgentAudioRecorder(page);
  await page.request.post(`${APP}e2e/hermes/audio`, {
    data: { enabled: true },
  });
  await open(page, "/settings/voice");
  const speakReplies = page.getByRole("switch", {
    name: /Speak replies aloud/,
  });
  await speakReplies.press("Space");
  await screenshot(page, testInfo, "persisted-voice-settings-selected");

  await page.reload();
  await page.waitForFunction(
    () => typeof globalThis.wingE2EHermesConnect === "function",
    null,
    { timeout: 30000 },
  );
  await a11y(page, { delay: 500 });
  await expect(
    page.getByRole("switch", { name: /Speak replies aloud/ }),
  ).toBeChecked();
  await screenshot(page, testInfo, "persisted-voice-settings-reloaded");

  await page.evaluate(() => {
    location.hash = "/hermes";
  });
  await connect(page);
  await sendChat(page, "persisted reply speed browser turn", {
    testInfo,
    screenshotPrefix: "persisted-reply-speed",
  });
  await expect
    .poll(() => page.evaluate(() => globalThis.wingE2EAgentAudio.plays.length))
    .toBe(1);
  const persistedAudioState = await page.request.get(`${APP}e2e/hermes/audio`);
  expect((await persistedAudioState.json()).spokenTexts).toEqual([
    "Hermes echo: persisted reply speed browser turn",
  ]);
  await page.evaluate(() => globalThis.wingE2EAgentAudio.finish());
});

test("stopping Agent speech discards queued replies", async ({
  page,
}, testInfo) => {
  await installAgentAudioRecorder(page);
  await connectFromVoiceSettings(page, { testInfo });
  await sendChat(page, "queued stop first browser turn", {
    testInfo,
    screenshotPrefix: "queued-stop-first",
  });
  await sendChat(page, "queued stop discarded browser turn", {
    testInfo,
    screenshotPrefix: "queued-stop-discarded",
  });
  expect(
    await page.evaluate(() => globalThis.wingE2EAgentAudio.plays.length),
  ).toBe(1);
  await screenshot(page, testInfo, "queued-stop-waiting");

  const pausesBeforeStop = await page.evaluate(
    () => globalThis.wingE2EAgentAudio.pauseCount,
  );
  await page.getByRole("button", { name: "Stop speaking" }).click();
  await expectVoiceInputAvailable(page);
  await expect
    .poll(() => page.evaluate(() => globalThis.wingE2EAgentAudio.pauseCount))
    .toBeGreaterThan(pausesBeforeStop);
  await page.waitForTimeout(500);
  expect(
    await page.evaluate(() => globalThis.wingE2EAgentAudio.plays.length),
  ).toBe(1);
  await screenshot(page, testInfo, "queued-stop-cleared");

  await sendChat(page, "queued stop recovery browser turn", {
    testInfo,
    screenshotPrefix: "queued-stop-recovery",
  });
  await expect
    .poll(() => page.evaluate(() => globalThis.wingE2EAgentAudio.plays.length))
    .toBe(2);
  const queuedStopAudioState = await page.request.get(`${APP}e2e/hermes/audio`);
  expect((await queuedStopAudioState.json()).spokenTexts.at(-1)).toBe(
    "Hermes echo: queued stop recovery browser turn",
  );
  await page.evaluate(() => globalThis.wingE2EAgentAudio.finish());
});

test("asynchronous Agent playback errors recover", async ({
  page,
}, testInfo) => {
  await installAgentAudioRecorder(page);
  await connectFromVoiceSettings(page, { testInfo });
  await sendChat(page, "asynchronous speech failure browser turn", {
    testInfo,
    screenshotPrefix: "async-speech-failure",
  });
  await expect(
    page.getByRole("button", { name: "Stop speaking" }),
  ).toBeVisible();

  await page.evaluate(() => globalThis.wingE2EAgentAudio.fail());
  await expect(
    page.getByText("Could not speak Hermes reply.").last(),
  ).toBeVisible();
  await expectVoiceInputAvailable(page);
  await screenshot(page, testInfo, "async-speech-failure-notice");

  await sendChat(page, "asynchronous speech recovery browser turn", {
    testInfo,
    screenshotPrefix: "async-speech-recovery",
  });
  await expect(
    page.getByRole("button", { name: "Stop speaking" }),
  ).toBeVisible();
  await screenshot(page, testInfo, "async-speech-recovered");
  await page.evaluate(() => globalThis.wingE2EAgentAudio.finish());
});

test("Agent speech stops on disconnect", async ({
  page,
}, testInfo) => {
  await installAgentAudioRecorder(page);
  await connectFromVoiceSettings(page, { testInfo });
  await sendChat(page, "disconnect active speech browser turn", {
    testInfo,
    screenshotPrefix: "disconnect-speech",
  });
  await expect(
    page.getByRole("button", { name: "Stop speaking" }),
  ).toBeVisible();
  const pausesBeforeDisconnect = await page.evaluate(
    () => globalThis.wingE2EAgentAudio.pauseCount,
  );

  await page.getByRole("button", { name: "Disconnect" }).click();
  const disconnectDialog = page.getByRole("alertdialog");
  await expect(disconnectDialog).toContainText("Disconnect from Hermes?");
  await screenshot(page, testInfo, "disconnect-speech-confirmation");
  await disconnectDialog.getByRole("button", { name: "Disconnect" }).click();
  await expect(page.getByRole("heading", { name: "Profiles" })).toBeVisible();
  await expect(page.getByText("Gateway: Disconnected")).toBeVisible();
  await expect
    .poll(() => page.evaluate(() => globalThis.wingE2EAgentAudio.pauseCount))
    .toBeGreaterThan(pausesBeforeDisconnect);
  await screenshot(page, testInfo, "disconnect-speech-cancelled");

  await connect(page);
  await expect(page.getByRole("button", { name: "Stop speaking" })).toHaveCount(
    0,
  );
  expect(
    await page.evaluate(() => globalThis.wingE2EAgentAudio.plays.length),
  ).toBe(1);
  await screenshot(page, testInfo, "disconnect-speech-reconnected");
});

test("mobile Agent speech controls stay reachable", async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await installAgentAudioRecorder(page);
  await connectFromVoiceSettings(page, { testInfo });

  await sendChat(page, "mobile spoken browser turn", {
    testInfo,
    screenshotPrefix: "mobile-spoken",
  });
  await expect(
    page.getByRole("button", { name: "Stop speaking" }),
  ).toBeVisible();
  await screenshot(page, testInfo, "mobile-stop-speaking");
  await page.evaluate(() => globalThis.wingE2EAgentAudio.finish());
  await expectVoiceInputAvailable(page);
  await screenshot(page, testInfo, "mobile-speech-completed");
});
