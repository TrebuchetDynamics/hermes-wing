# Hermes Mobile lessons for Wing

Source review: 2026-09-21, [Hy4ri/hermes-mobile](https://github.com/Hy4ri/hermes-mobile)
at commit `9f16ba292953e3d81332f26d345e7989f000ac68`. This is a source
comparison, not Android runtime qualification. No Kotlin code was copied.

## Applied: refresh where the user's hand already is

Mobile's [HermesScaffold](https://github.com/Hy4ri/hermes-mobile/blob/9f16ba292953e3d81332f26d345e7989f000ac68/app/src/main/java/com/m57/hermescontrol/ui/common/HermesScaffold.kt)
provides a pull-to-refresh container when a refresh callback is supplied.
Its [CronJobsScreen](https://github.com/Hy4ri/hermes-mobile/blob/9f16ba292953e3d81332f26d345e7989f000ac68/app/src/main/java/com/m57/hermescontrol/ui/cron/CronJobsScreen.kt)
uses that callback alongside an explicit refresh action.

Wing already uses this pattern in Office and gateway contacts. The
[Schedules screen](../../lib/features/schedules/screens/schedules_screen.dart)
now also supports pulling short and empty inventories to refresh. The labeled
toolbar button remains the keyboard/accessibility equivalent. Both entry points
use the existing direct Agent read and reject overlapping refresh requests.
Capability and grant checks, error redaction, and refresh-generation checks
remain in place. No schedule mutation or new transport is introduced.

## Next candidates, in priority order

1. **Session search that explains its scope.** Mobile's
   [SessionsViewModel](https://github.com/Hy4ri/hermes-mobile/blob/9f16ba292953e3d81332f26d345e7989f000ac68/app/src/main/java/com/m57/hermescontrol/ui/sessions/SessionsViewModel.kt)
   tracks separate search results, pagination, errors, and request generations.
   Wing's [session list](../../lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart)
   filters the sessions supplied by the channel. Distinguish filtering loaded
   sessions from searching all history before extending search. Remote search
   needs a verified, advertised, profile-scoped Agent operation; do not build a
   second transcript index or infer support from Mobile's dashboard calls.
2. **Readable schedule expressions.** Mobile's
   [CronExpressionFormatter](https://github.com/Hy4ri/hermes-mobile/blob/9f16ba292953e3d81332f26d345e7989f000ac68/app/src/main/java/com/m57/hermescontrol/util/CronExpressionFormatter.kt)
   translates common expressions into prose. Wing's
   [job model](../../lib/core/hermes/models/hermes_job.dart) already prefers the
   Agent's display string, falling back to the expression. Keep that precedence.
   Any additional formatter should be localized, strictly validate supported
   expressions, preserve the raw value, and avoid implying device-local time
   when the schedule timezone is unknown. Verify Agent semantics before adding it.
3. **Search-result excerpts that remain readable.** Mobile's
   [SessionSearchFormatting](https://github.com/Hy4ri/hermes-mobile/blob/9f16ba292953e3d81332f26d345e7989f000ac68/app/src/main/java/com/m57/hermescontrol/ui/sessions/SessionSearchFormatting.kt)
   extracts prose from structured snippets and highlights matched terms as text.
   Revisit this when Wing has an authoritative search-result contract. Retain
   bounded output and readable text without relying on highlight color alone;
   do not show arbitrary serialized payloads as fallback excerpts.

## Boundaries to preserve

Mobile's [README](https://github.com/Hy4ri/hermes-mobile/blob/9f16ba292953e3d81332f26d345e7989f000ac68/README.md)
describes a dashboard REST/WebSocket client, local chat history, and plain HTTP
on trusted networks. These are not Wing implementation templates. Wing requires
its existing secure transport and separate Agent/Wing Link credentials, keeps
Agent domain state authoritative, and gates each operation independently.
Mobile's configuration, cron mutations, and notification replies do not establish
that equivalent contracts are available to Wing. No upstream Agent changes are
permitted to make a copied workflow work.

## Validation scope

Regression coverage in
[schedules_screen_test.dart](../../test/features/schedules/schedules_screen_test.dart)
checks gesture refresh on short/empty inventories, overlapping button/gesture
requests, exact read grants, and the existing gateway-switch race. Flutter widget
tests exercise the shared presentation on the Linux test host; they are not
physical Android gesture or service qualification.
