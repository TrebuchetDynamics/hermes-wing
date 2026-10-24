# Installed Skills category filters

Date: 2026-10-24. Official reference: NousResearch/hermes-agent
`14e1e43a23761b369641208e204365cd6cb9399d`.

## Delivered outcome

The Skills inventory now exposes independently selectable category filters and an
**All categories** reset. Multiple selected categories match with OR; the literal
text query applies with AND. Clearing only the search leaves the category choices
intact; All categories clears only that facet. Filtering performs no Agent calls.

Sources at the exact pin:

- [`catalog-browser.tsx`](https://github.com/NousResearch/hermes-agent/blob/14e1e43a23761b369641208e204365cd6cb9399d/apps/desktop/src/app/capabilities/catalog/catalog-browser.tsx): category controls and composition of facets with the query.
- [`catalog-query.ts`](https://github.com/NousResearch/hermes-agent/blob/14e1e43a23761b369641208e204365cd6cb9399d/apps/desktop/src/app/capabilities/catalog/catalog-query.ts): OR category membership and AND query matching.
- [`use-catalog-filters.ts`](https://github.com/NousResearch/hermes-agent/blob/14e1e43a23761b369641208e204365cd6cb9399d/apps/desktop/src/app/capabilities/catalog/use-catalog-filters.ts): category toggle and All clearing semantics.

Flutter uses wrapping Material filter chips so the controls remain operable by
keyboard and with enlarged text. Labels come only from the existing bounded
installed-skill category metadata. A selected category that disappears during a
same-owner refresh remains available to deselect, allowing explicit recovery
from zero results. Tab visits and inventory updates retain the selection; exact
read-grant loss or host/profile/connection ownership changes discard it, including
loss/restoration before the next frame. No category state is persisted.

The existing advertised and authorized skills inventory remains the only source.
Public catalog discovery, skill content, installation, edits, enablement and
other administration remain unsupported by this slice. Toolsets are unchanged.

## Executed checks

Linux Flutter widget renderer, Flutter 3.44.2 / Dart 3.12.2. Existing lockfile
unchanged. Six new behavioral cases failed against the old search-only inventory
before implementation.

- `dart format lib/features/tools/screens/tools_screen.dart test/features/tools/skills_category_filters_test.dart test/features/tools/tools_screen_test.dart`: passed.
- `flutter test --no-pub --concurrency=1 test/features/tools`: **49 passed**, serial.
- `flutter analyze --no-pub`: no issues (5.7s).
- `git diff --check`: passed.

The eight new cases cover OR/AND semantics, literal query characters, independent
clearing, no extra Agent reads/writes, tab retention, disappearing-category
recovery, same-frame profile/grant roundtrips, stale callbacks after owner replacement and disposal, and keyboard chip activation at
390/1280px with 200% text. The retained metadata assertion is scoped to the actual
list row because the category is now also named by its filter control.

Localization is supplied by the coordinated Settings commit `38f89cf9`'s generated
`skillsCategoriesLabel` / `skillsAllCategoriesLabel` entries; that commit is a
build dependency of this slice. Broader frozen-candidate and compiled-browser
checks are run by the integration owner. No physical/native-device, screen-reader
or live Agent capability administration is qualified by these widget checks.
