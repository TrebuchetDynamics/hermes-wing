# ADR 0040: Detach Android while server runs continue

Status: accepted
Date: 2026-07-13

When Hermes Wing leaves the Android foreground, it detaches presentation and may lose its HTTP/SSE transport, but it does not implicitly stop a Hermes Agent run. The server remains authoritative and continues or expires work according to its run and approval policies. Hermes Wing does not add a foreground service, wake lock, polling loop, or hidden retry queue merely to keep a run connection alive.

## Background transition

- Microphone capture, continuous voice, speech recognition, text-to-speech, and local voice-command listening stop immediately; late results are discarded.
- Draft text remains inert in memory under ADR 0030. In-memory follow-up queues, approval affordances, and pending client mutations are invalidated and never replayed automatically.
- Backgrounding itself sends no stop, approval, tool, task, or administrative command.
- The app releases transport and media resources when Android requires it. Process termination may discard in-memory drafts and stale snapshots.

## Resume reconciliation

Resume first revalidates the saved endpoint credential, capabilities, scopes, profile context, and connection generation. Hermes Wing then fetches authoritative session and run state, reconciles terminal output and any still-valid server-side approval, and reconnects the advertised event stream using its event ID when useful. GET reconciliation remains authoritative when events were missed or compacted.

The client does not infer run completion from a dropped stream, reuse an approval rendered before backgrounding, send an inert draft, or restore a queue from storage. Endpoint, credential, profile, session, or run changes reject stale resume responses.

## Optional notifications

Run-completion or attention notifications require a separate advertised server capability, explicit app and operating-system permission, and an operator opt-in for that endpoint. Push registration tokens are sensitive endpoint data, are never analytics identifiers, and are removed on opt-out, endpoint deletion, credential revocation, or sign-out when possible.

Notification title, body, and payload contain no prompt, response, transcript, profile or session name, tool details, approval contents, endpoint origin, credential, or private identifier. A notification may say only that Hermes completed work or needs attention. Opening it launches Hermes Wing, which authenticates and fetches current state; the notification itself carries no bearer authorization or mutation instruction.

When notification capability is unavailable or permission is denied, runs still continue server-side and reconcile on next foreground resume. Hermes Wing does not emulate push with a persistent Android service.

## Evidence

Android receipts cover background during streaming, reasoning, tool execution, and approval; late voice-result rejection; no background mutation or replay; process death; resume after completion and missed events; changed endpoint/profile/credential; notification denial and opt-out; redacted notification content; and server run continuation without a Hermes Wing foreground service.
