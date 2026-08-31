# Conversation-First Agent Workspace Design

**Status:** Approved design

## Summary

Hermes Wing Chat will become a conversation-first control surface for Hermes Agent. It will preserve the behavioral outcomes that make Hermes Desktop effective—chat-first navigation, first-class sessions, visible runs, grouped tools, approvals, slash commands, and a unified command surface—while retaining an independent, adaptive Flutter visual identity.

The design serves a balanced hybrid use case: quick conversation, substantial delegated work, and multi-session supervision. Progressive disclosure keeps routine conversation calm while preserving complete access to Hermes Agent activity.

## Sources and constraints

This design follows:

- `CONTEXT.md`: Hermes Agent owns profiles, projects, sessions, runs, tools, approvals, and gateway state; server state wins after reconnect.
- `docs/adr/client.md`: shared domain behavior, adaptive native presentation, replaceable Riverpod/channel seams, and accessible equivalents.
- `docs/product/hermes-desktop-feature-study.md`: Desktop user outcomes are reference behavior, not an Electron implementation template.
- `docs/product/hermes-desktop-ui-gap.md`: mobile chat should retain low chrome, a fast bottom composer, clear user messages, and grouped Agent activity.

## Goals

1. Make routine conversation fast and visually calm.
2. Make substantial Agent work understandable without exposing raw event noise.
3. Keep detached and concurrent work visible across suspension, relaunch, and reconnect.
4. Anchor approvals, failures, and recovery actions to the work that caused them.
5. Make profile, Hermes Project, and session context continuously understandable.
6. Preserve equivalent outcomes across phones, tablets, and desktops.
7. Use Hermes Agent capabilities directly and avoid Wing-owned shadow domain state.

## Non-goals

- Pixel or structural duplication of Hermes Desktop.
- A separate Simple/Operator mode.
- Displaying raw stream payloads, internal IDs, host paths, or sensitive arguments in normal Chat.
- Inventing mobile-only run, profile, project, or session state.
- Copying Desktop filesystem, CLI, Electron IPC, or local Hermes-home access patterns.
- Making reasoning, motion, sound, color, pointer input, or spatial presentation necessary for operation.

## Product hierarchy

Chat uses this priority order:

1. **Conversation:** user requests and Hermes answers dominate the surface.
2. **Context:** one compact bar identifies the active profile, project, and session.
3. **Execution:** substantial requests expose an inline run capsule.
4. **Activity:** reasoning and tool calls form compact, expandable groups.
5. **Decisions:** approval cards appear beside the requesting run step.
6. **Input:** one adaptive composer reveals advanced controls only when relevant.
7. **Navigation:** phone sheets progressively become tablet and desktop rails or side sheets.

No separate mode changes these priorities.

## Responsive screen anatomy

### Phone

- The app bar contains profile identity, active session title, connection state, and overflow actions.
- A one-line context bar beneath it reads `Profile · Project · Session` and opens the context sheet.
- The transcript remains the main surface.
- Run capsules sit beneath their initiating user request.
- Approval cards sit inside the relevant run timeline.
- A floating rounded composer remains at the bottom.
- Sessions, context, run details, and attachment selection use bottom sheets.

### Tablet

- A collapsible session rail may remain visible.
- The transcript uses a readable maximum width.
- Context and run details may use a side sheet rather than covering Chat.
- Composer behavior remains consistent with phone.

### Desktop

- The session rail is persistent and supports search and branch affordances.
- Concurrent detached runs can become switchable tabs or capsules above the transcript when Hermes Agent advertises the required state.
- Model, reasoning, and context controls can remain visible in the wider composer.
- Keyboard shortcuts and secondary-click actions remain first-class.

### Scrolling

- Streaming output follows only while the user is already near the live edge.
- Reading older content is never interrupted by automatic scrolling.
- A visible `New activity` affordance returns to the active run.
- Relaunch restores the selected session and reveals the active or latest run rather than choosing an arbitrary transcript offset.

## Context model

A compact context bar provides continuous identity without consuming app-bar space. Tapping it opens one context sheet with:

- active profile;
- active Hermes Project and primary-folder label when advertised;
- active session;
- model and connection summary;
- profile, project, and session switch actions;
- new-session and project-management shortcuts.

The sheet previews a destination before committing a switch. A context change uses supported Agent operations and never silently changes global Agent defaults. If context becomes unavailable, the existing transcript remains readable while mutation controls fail closed until valid Agent-owned context is selected.

## Run and activity model

A request forms a visible run unit when Hermes Agent reports run lifecycle, tool, approval, detached-work, or recovery activity. Quick text-only exchanges do not reserve an empty capsule. Each visible run unit remains understandable:

```text
User request
└─ Run capsule
   ├─ Reasoning summary
   ├─ Grouped tool activity
   ├─ Anchored approvals
   └─ Final answer
```

### Collapsed run capsule

The default state shows:

- queued, running, waiting, stopped, failed, disconnected, or completed status;
- one short current-activity summary;
- elapsed time when useful;
- Stop, Resume, Retry, or Open action when applicable;
- detached/background state.

### Expanded run details

Expansion may show:

- reasoning sections supplied by the Agent;
- ordered, grouped tool calls and bounded safe results;
- approval requests and decisions;
- token and timing metadata;
- failure and recovery history.

Routine successful activity stays collapsed. Approvals, failures, and user-requested details expand automatically. Multiple adjacent tool calls become one activity group with a useful summary such as `Used 4 tools · 3 succeeded · 1 needs attention`.

### Authority and reconciliation

Hermes Agent is authoritative for session, run, tool, and approval state. Wing may project live stream events for responsiveness, but it reconciles the projection against Agent state after reconnect or relaunch. Wing does not infer completion from partial output. Detached work continues independently when Wing is suspended.

Queued follow-ups remain visibly attached to their target session. Their queue position and cancellation affordance are shown without representing them as Agent-accepted work before transport confirmation.

## Approval model

Approval cards are anchored beside the run step that requested them. A card presents:

- a concise risk category;
- the exact user-meaningful action;
- the affected profile, project, or resource label when safe;
- `Allow once`, capability-supported `Allow for session`, and `Deny` actions;
- pending, approved, denied, expired, or failed state.

Approval cards do not expose raw arguments, credentials, host paths, or internal operation IDs. Expired requests remain in context with a request-again action when supported.

## Adaptive composer

### Resting state

The default composer contains:

- a multiline message field;
- add/attachment action;
- microphone action when voice input is available;
- Send.

### Contextual expansion

Only relevant controls appear:

- selected attachment previews;
- listening and transcription state;
- slash-command suggestions from Agent and Wing-local catalogs;
- queued-follow-up state;
- Stop replacing Send when the active operation supports stopping;
- model or reasoning controls only when advertised by Hermes Agent;
- project or resource context only while selected or being changed.

Drafts are retained per session. Sending, transport failure, voice-output failure, and context reconciliation do not destroy entered text. Attachments remain bounded and follow existing safe resource-handle rules.

## Visual language

Wing keeps an independent identity rather than copying Desktop styling:

- dark, calm transcript surfaces;
- strong profile color used sparingly for identity and live state;
- visually distinct user messages;
- Hermes answers placed on an open transcript surface rather than inside unnecessary cards;
- rounded geometry concentrated around interactive controls;
- minimal borders and deliberate spacing;
- high text contrast;
- icon, text, and shape used together for status;
- motion used for continuity, never as the only explanation.

The interface should feel conversational first and operational only when work requires it.

## Failure handling

Failures remain attached to the affected operation whenever possible:

- **Message failure:** preserve or restore the draft and offer Retry.
- **Connection loss:** retain the transcript, mark live work disconnected, and reconcile after reconnect.
- **Run failure:** keep partial safe text, expand the run capsule, and offer the relevant recovery action.
- **Tool failure:** expand the affected activity group with a bounded safe summary.
- **Approval expiry:** retain the expired decision card and provide request-again when supported.
- **Voice-output failure:** preserve the text answer and keep voice input available.
- **Unavailable context:** leave Chat readable and disable unsupported mutations until valid context is selected.

Global banners are reserved for failures affecting the entire connection or all visible work.

## Component boundaries

The implementation should reuse existing channel, Riverpod, and adaptive presentation seams.

- **Context bar and sheet:** render Agent-owned selection and dispatch supported selection operations.
- **Transcript projector:** map canonical turns and live events into conversational rows without owning domain state.
- **Run capsule:** render one run projection and its recovery actions.
- **Activity group:** summarize adjacent reasoning/tool activity and expose structured expansion.
- **Approval card:** render one approval and dispatch capability-gated decisions.
- **Adaptive composer:** own only local draft and staged-input presentation; submit through the existing message flow.
- **Session navigation:** adapt the same session model into phone sheets and wide rails.

Each component receives a small immutable view model and callbacks. Server authority, streaming, and reconciliation remain in channel/controller layers rather than widgets.

## Accessibility

- Complete keyboard and screen-reader operation is mandatory.
- Touch targets meet mobile minimums.
- Transcript semantics preserve logical reading order.
- Streaming, approval requests, completion, stopping, and failure receive bounded announcements.
- Status never depends on color, animation, sound, or position alone.
- Reduced-motion preferences remove nonessential movement.
- Expanded activity is structured as readable text with headings and action labels.
- Every wide-screen interaction has an equivalent phone and keyboard path.

## Validation

### Focused tests

- Widget tests for phone, tablet, and desktop anatomy.
- State-transition tests for every run capsule status.
- Composer tests for drafts, attachments, voice, slash commands, stopping, and queued follow-ups.
- Context tests for preview, commit, unavailable context, and fail-closed capability gating.
- Approval tests for pending, decision, expiry, retry, and redaction.
- Scroll tests proving live follow does not interrupt historical reading.

### Channel and integration tests

- Streaming projection followed by authoritative reconciliation.
- Disconnect and reconnect during a run.
- Relaunch while detached work continues.
- Partial response and tool failure preservation.
- Session switching and branching without cross-session draft leakage.

### Runtime evidence

The full Android Waydroid regression must cover:

- quick conversation;
- long-running work with stop and recovery;
- relaunch and detached-run recovery;
- grouped tool activity;
- anchored approval decisions;
- session switching and branching;
- voice-output fallback that preserves text and voice input;
- profile, project, and session context switching.

Desktop validation additionally covers keyboard shortcuts, context menus, persistent rails, and concurrent-run presentation. Accessibility claims require matching TalkBack, keyboard, or supported screen-reader evidence.

## Delivery sequence

1. Compact context bar and calmer transcript hierarchy.
2. Inline run capsule and authoritative reconciliation states.
3. Anchored approvals and grouped reasoning/tool activity.
4. Adaptive composer and per-session draft behavior.
5. Responsive session and concurrent-run navigation.
6. Visual, motion, accessibility, and runtime polish.

Each slice must preserve existing chat, session, voice, and recovery regression coverage before the next slice begins.
