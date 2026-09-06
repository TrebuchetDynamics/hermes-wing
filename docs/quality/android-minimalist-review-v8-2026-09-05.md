# Minimalist UI review — 2026-09-05, pass 8

Reviewed the pass-7 physical Android screenshots of 13 routes in both themes.
The visual problem was repeated hierarchy and inconsistent density: host selectors
had an extra horizontal inset, administrative content started too far below
selectors, and the Settings overview repeated controls from its detail screen.
The existing neutral surfaces and readable type scale were retained.

## Screen review

| Screen | Finding and action |
| --- | --- |
| Settings | Three voice switches repeated the dedicated screen. Replaced them with one descriptive navigation row; removed the repeated Diagnostics heading. Tightened saved-host rows without reducing text size. Squared the appearance segments and removed the nested accent-field outline. |
| Office | Colored avatars and filled arrow buttons competed with contact names. Use a neutral avatar for inactive contacts, a simple chevron, and 12px card padding. Current contact remains explicitly labeled. |
| Providers | The model section heading competed with the page heading. Standardized the section scale, shortened the gap after host selection, and made credential management a text action. |
| Profiles | Supporting introduction competed with names. Use secondary body styling, smaller supporting metadata icons, and less space below the host selector. |
| Tools | Removed excess space between host selection and inventories. |
| Gateway | Shared selector now aligns with the same content grid and keeps a 48px minimum height. Trust details and revocation retain their established layout. |
| Schedules | Shares the aligned host selector. Read-only wording remains visible because mutation support is unavailable. |
| Diagnostics | Existing compact label/value layout and export reachability are retained. |
| Voice & speech | Becomes the single place for voice switches; advanced controls stay collapsed initially. Settings navigation and persistence are regression tested. |
| Persona | Name, editor, and Save/Cancel hierarchy remains appropriate for one scoped edit. |
| Chat | Keep the starter prompts and composer hierarchy; avoid adding decorative material to the empty conversation. |
| Pairing | Keep the three explicit setup choices and explanatory text. |
| Local setup | Preserve ordered steps and host-action wording; compact styling must not obscure where commands execute. |

Empty inventory screenshots do not qualify populated lists, every modal, or live
Agent operations. No fonts, dependencies, transport contracts, permissions, or
Agent-owned state were changed.

## Evidence

Temporary before/after gallery and logs are in `/tmp/hermes-wing-ui-v8/`.
Evidence is synthetic QA data from a physical Samsung SM-S928B, Android 16.
Screenshots and APKs remain outside version control.

- Initial focused suite: 119 passed across Settings, Settings routes, Profiles,
  Providers, Tools, and Office, including existing 200% text cases.
- After the final Settings spacing refinement: all 37 Settings and route tests
  passed again.
- `flutter gen-l10n`: passed; English source and generated output updated together.
- `flutter analyze`: passed.
- Changed Dart files pass `dart format --output=none --set-exit-if-changed`.
- QA and regular debug APK builds passed.
- Physical `visual_review.yaml` and updated `settings.yaml`: both passed in
  3m 42s. The interaction flow covers theme persistence, navigation into voice,
  voice preference persistence, command-word editing, and safe diagnostics export.
- After the spacing refinement, repeated `visual_review.yaml`: all 26 captures
  passed with zero reported layout overflows. Both contact sheets were inspected.
  With two saved hosts, the entire Settings overview fits the normal phone viewport.
- `npm run readme:assets`: passed again after final UI changes, including the
  deterministic release web build.
- `git diff --check`: passed.

Commands and final physical results are recorded alongside the gallery. These
checks establish the exercised UI behavior, not live provider inference or
qualification of other platforms.
