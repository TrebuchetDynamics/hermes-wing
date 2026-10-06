---
version: 1
slug: "lib-shared-widgets-app-shell-dart"
primary_target: "lib/shared/widgets/app_shell.dart"
related_targets: ["lib/shared/widgets/app_shell_desktop_style.dart"]
---

# Desktop shell/sidebar

Mode: Operate. Code-led, pinned-reference redesign. Primary target:
`lib/shared/widgets/app_shell.dart`. Desktop/wide web 1280×900, compact web
390×844; native Android/iOS remain unqualified and compact styles unchanged.

## Direction contract

THESIS: Reproduce Hermes Desktop's task shell rather than embellishing Wing's
incumbent Material rail. Keep nine real routes and exact Agent session actions;
never fill missing Discover/Kanban/Memory/profile-footer capabilities with mocks.

OWN-WORLD: Desktop's flat 250/64 sidebar, light #f8f8f8/dark #171717 rail,
white/#212121 work area, 13px navigation, 16px icons, 10px corners, subtle blue
selection and explicit hover/keyboard-focus treatment. Native system-font fallback
is disclosed; compact Material behavior stays unchanged.

STORY: Orient, choose an existing route, open an acknowledged loaded session,
collapse without losing identity, and recover the compact navigation.

FIRST VIEWPORT: Clean top-right sidebar toggle, pinned workflow above the flexible
loaded-session area, labeled available utilities anchored below, full-width 26px
status strip, unconstrained work area beside the sidebar. Signature interaction:
collapse/expand preserves route, draft and keyboard focus with no backend action.

FORM: User-pinned Hermes Desktop wins over assigned candidate 5. Seed b59dfc09,
direction/Operate, already run by parent; no alternative world or invented ritual.

MOTION: Native button hover/focus responds within Desktop's 150ms rhythm; collapse
is immediate to retain stable child/focus ownership and honor reduced motion.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

Honest gaps: real profile footer, grouped recent sessions, tabs, unsupported routes,
relaunch persistence, exact bundled Manrope Latin/Cairo Arabic faces and native
window chrome are not fabricated. Parent owns PRODUCT.md, independent finish review, DESIGN.md and the
fleet detector. Earlier refinement captures/scan are historical, not redesign
acceptance. New redraw gets one batched light/dark desktop/compact inspection and
at most one correction/confirmation round.
