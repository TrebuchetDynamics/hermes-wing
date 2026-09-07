# Compact minimalist UI review

Physical Android screenshot review of the 13-screen light/dark tour, following
[the density pass](maestro-ui-density-review-2026-09-05.md).

## Diagnosis and changes

The previous screens were functional but visually repetitive: outlined selectors
sat above outlined cards, every section had similar emphasis, and technical
metadata pushed actions below the first viewport. The direction is a neutral
canvas, flat surfaces, compact chrome, and progressive disclosure of secondary
information. Readable body text, named actions, focus treatment, and 48-pixel
button targets remain.

| Screen | Finding and response |
| --- | --- |
| Profiles | Selector and inventory competed as two boxed forms. The shared selector is now flat; cards align with the content edge. Profile identity and Chat remain visible. |
| Tools | Unsupported-inventory explanations occupied oversized panels. Reduced panel padding and heading gaps while preserving the exact unsupported-state explanation. |
| Office | Contact cards were visually heavier than the short list justified. Flat cards and the shared smaller header reduce chrome without changing contact activation. |
| Providers | Model/provider cards had excessive padding and action gaps. Tightened both, preserving model selection and credential capability gates. |
| Persona | A sparse editor does not need extra decoration. Shared heading and surface treatment make the editor quieter; Save and Cancel remain explicit. |
| Gateway | A full disconnect row and raw trust identifiers dominated the viewport. Disconnect moves to the labeled header action. Device identity and revoke remain visible; fingerprint, protocol, scopes, and host instructions expand under Identity & permissions. Error notices remain visible. |
| Settings | Nested padding and large section gaps pushed useful controls down. Reduced section gaps and standardized internal padding, preserving all preferences and accessible palette controls. |
| Voice & speech | Shared section spacing and flat cards make the three switches easier to scan. Advanced controls remain expandable. |
| Diagnostics | Repeated borders and section gaps made short status information feel sprawling. Shared section/card changes tighten the hierarchy; explicit status text and missing-data labels remain. |
| Schedules | Border-heavy chrome outweighed the small read-only inventory. Flat selector/cards and quieter headings preserve the read-only explanation. |
| Chat | Empty-state content already has a useful hierarchy and a reachable composer. Shared neutral surfaces and smaller chrome apply without removing starter actions or changing chat behavior. |
| Pairing | The three choices are meaningful touch targets, not decorative cards. Retained their generous hit areas while flattening surfaces and reducing heading weight. |
| Local setup | Instructions and the primary next step remain the priority. Shared typography/surfaces apply; safety and prerequisite instructions are retained. |

The light palette uses neutral off-white with charcoal text. The dark palette
retains its readable charcoal surfaces. Color remains available for selected
controls and status. Shared cards drop decorative outlines and default outer
margins; mobile navigation is 60 pixels and app bars are 52 pixels. Body text
sizes and primary button minimum targets are unchanged.

## Evidence

Artifacts and final validation are recorded under `/tmp/hermes-wing-ui-v6/`.
Only isolated QA fixture screens are captured; no production credentials or
transcripts are used. The screen tour covers initial viewports in both themes,
with separate Settings and Gateway trust interaction checks. It does not cover
every modal, every scroll position, or live provider inference.

Validation commands:

```bash
flutter test --concurrency=1 test/theme test/shared/widgets test/features/gateway test/features/settings test/features/providers test/features/tools
flutter test test/features/gateway/gateway_screen_test.dart
flutter analyze
WING_ISOLATED_DEVICE_TEST=1 flutter build apk --debug -t integration_test/hermes_features_maestro_main.dart
maestro --device "$ANDROID_SERIAL" test --test-output-dir /tmp/hermes-wing-ui-v6/final scripts/maestro/fixture/visual_review.yaml scripts/maestro/fixture/gateway_trust.yaml scripts/maestro/fixture/settings.yaml
maestro --device "$ANDROID_SERIAL" test --test-output-dir /tmp/hermes-wing-ui-v6/compact scripts/maestro/fixture/visual_review.yaml scripts/maestro/fixture/gateway_trust.yaml
flutter build apk --debug -t lib/main.dart
npm run readme:assets
git diff --check
```

The focused suite passed 161 tests; all 15 Gateway tests passed again after the
header adjustment. Changed Dart files pass formatting. Analysis passed with no
issues. An initial stale uppercase desktop-brand assertion was aligned with the
concurrent sentence-case brand change, and an existing missing-braces lint in the
profile editor was corrected without changing validation behavior.

The first phone tour passed with 26 screenshots and zero reported overflows.
Settings passed in 123 seconds, including palette interaction and persistence.
The new trust-details flow initially failed because Android adds “Collapsed” to
the expansion row's accessible label; the selector now accepts that state suffix.
The 200% widget test verifies the details start collapsed, expand to reveal the
full fingerprint/scopes, and preserve confirmed self-revocation. Its initial
scroll/tap timing was corrected to wait for layout before tapping.

Both APK builds passed. The README asset command rebuilt the deterministic web
fixture and generated its screenshots successfully. The full Flutter suite,
full browser suite, live inference, and physical platforms other than Android
were not exercised in this pass. No Agent or Wing Link domain/security contract
was changed.

Final physical rerun: visual review passed in 95 seconds and Gateway trust passed
with the corrected expansion selector. Both final contact sheets were inspected,
along with the full-size Gateway, expanded trust, and Settings palette menu
captures. The gallery at `/tmp/hermes-wing-ui-v6/index.html` compares the previous
pass with the final 26 captures. The additional expanded-trust capture is in
`compact/screenshots/gateway-trust-details.png`; the two Settings captures remain
in `final/screenshots/`. Screenshots are not checked into Git.

The regular Android package was verified and updated using `adb install -r`,
preserving stored user data, then opened on the phone.
