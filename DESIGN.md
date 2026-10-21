---

> Reference correction: [official Desktop authority](docs/quality/official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.

{
  "version": "alpha",
  "name": "Hermes Wing — first desktop shell",
  "description": "Implemented shell-only reference roles; untouched feature and compact themes are not a global rollout.",
  "colors": {
    "primary": "#003f7a",
    "dark-accent": "#579fff",
    "light-rail": "#f8f8f8",
    "light-work-area": "#ffffff",
    "light-foreground": "#111111",
    "light-secondary": "#555555",
    "light-hover": "#f0f0f0",
    "light-selection": "#003f7a14",
    "light-border": "#e5e5e5",
    "dark-rail": "#171717",
    "dark-work-area": "#212121",
    "dark-foreground": "#ececec",
    "dark-secondary": "#b4b4b4",
    "dark-hover": "#2f2f2f",
    "dark-selection": "#003f7a26",
    "dark-border": "#ffffff0f"
  },
  "typography": {
    "shell-nav": {
      "fontFamily": "sans-serif, 'Helvetica Neue', Arial, 'DejaVu Sans'",
      "fontSize": "13px",
      "fontWeight": 400,
      "lineHeight": 1.4
    },
    "shell-nav-selected": {
      "fontFamily": "sans-serif, 'Helvetica Neue', Arial, 'DejaVu Sans'",
      "fontSize": "13px",
      "fontWeight": 600,
      "lineHeight": 1.4
    },
    "shell-status": {
      "fontFamily": "sans-serif, 'Helvetica Neue', Arial, 'DejaVu Sans'",
      "fontSize": "11px",
      "lineHeight": 1
    }
  },
  "rounded": {
    "shell-control": "10px"
  },
  "spacing": {
    "row-gap-half": "2px",
    "group-vertical": "4px",
    "status-icon-gap": "6px",
    "row-inset-vertical": "7px",
    "rail-inset": "8px",
    "nav-icon-gap": "10px",
    "status-column-gap": "12px"
  },
  "components": {
    "shell-nav-light-default": {
      "backgroundColor": "{colors.light-rail}",
      "textColor": "{colors.light-foreground}",
      "typography": "{typography.shell-nav}",
      "rounded": "{rounded.shell-control}",
      "padding": "7px 10px"
    },
    "shell-nav-light-selected": {
      "backgroundColor": "{colors.light-selection}",
      "textColor": "{colors.primary}",
      "typography": "{typography.shell-nav-selected}",
      "rounded": "{rounded.shell-control}",
      "padding": "7px 10px"
    },
    "shell-nav-light-hover": {
      "backgroundColor": "{colors.light-hover}",
      "textColor": "{colors.light-foreground}",
      "typography": "{typography.shell-nav}",
      "rounded": "{rounded.shell-control}",
      "padding": "7px 10px"
    },
    "shell-toggle-light": {
      "backgroundColor": "{colors.light-rail}",
      "textColor": "{colors.light-foreground}",
      "rounded": "{rounded.shell-control}",
      "width": "48px",
      "height": "48px"
    },
    "shell-status-light": {
      "backgroundColor": "{colors.light-rail}",
      "textColor": "{colors.light-secondary}",
      "typography": "{typography.shell-status}",
      "padding": "4px 12px"
    },
    "shell-nav-dark-default": {
      "backgroundColor": "{colors.dark-rail}",
      "textColor": "{colors.dark-foreground}",
      "typography": "{typography.shell-nav}",
      "rounded": "{rounded.shell-control}",
      "padding": "7px 10px"
    },
    "shell-nav-dark-selected": {
      "backgroundColor": "{colors.dark-selection}",
      "textColor": "{colors.dark-accent}",
      "typography": "{typography.shell-nav-selected}",
      "rounded": "{rounded.shell-control}",
      "padding": "7px 10px"
    },
    "shell-nav-dark-hover": {
      "backgroundColor": "{colors.dark-hover}",
      "textColor": "{colors.dark-foreground}",
      "typography": "{typography.shell-nav}",
      "rounded": "{rounded.shell-control}",
      "padding": "7px 10px"
    },
    "shell-toggle-dark": {
      "backgroundColor": "{colors.dark-rail}",
      "textColor": "{colors.dark-foreground}",
      "rounded": "{rounded.shell-control}",
      "width": "48px",
      "height": "48px"
    },
    "shell-status-dark": {
      "backgroundColor": "{colors.dark-rail}",
      "textColor": "{colors.dark-secondary}",
      "typography": "{typography.shell-status}",
      "padding": "4px 12px"
    }
  }
}
---

# Design System: Hermes Wing — first desktop shell

## Official Desktop shared visual foundation

Target: a near-literal Flutter port of official Hermes Desktop, adapted for touch,
not a Telegram-inspired client. Reference pinned from GitHub at
`ccc695635094d7615373db267b77f894d978b1a0`:

- `apps/shared/src/theme-presets.ts:125-181`: canonical Nous light/dark seeds.
- `apps/desktop/src/themes/context.tsx:270-289,338-389`: applied seed/mix rules.
- `apps/desktop/src/styles.css:297-416,476-494`: derived surfaces/text and fonts.
- `apps/desktop/DESIGN.md`: flat hierarchy, shared primitives and Chat as home.

Port the applied surfaces, not merely the boot CSS fallbacks. Light chrome is
92% white plus 8% `#f3f3f3`; dark chrome is 74% `#0d1117` plus 26% `#0d0d0e`.
Sidebar seeds are `#f6f8fa` / `#010409`. Editor seeds mix at 22% / 38% against
`#fcfcfc` / `#161618`. Primary is `#0053fd` / `#4a84fe`; primary foreground is
white / `#161616`. Text uses the source foreground at 94% / 74% opacity over
its surface. Use those same roles on compact and wide layouts, with one token
owner consumed by the Flutter default theme and sidebar. Preserve palette IDs
and explicitly saved alternative palettes. No new network font dependency.

Touch adaptations retain 48 logical-pixel action targets, current readable body
sizes, platform font fallback, 200% scaling, keyboard focus and reduced motion.
Do not copy 24px desktop hit areas onto phones. This slice does not change the
transcript/composer structure, session model, Agent transport or feature gates.

Required verification: source-derived theme expectations, light/dark text/action
contrast, existing alternate-palette persistence, shell regression, analyzer,
formatter and rendered compact/wide production controls. Rendered browser evidence
is not Android, native keychain, live Agent, full typography or full design parity.

## Overview

**Creative North Star: "The Hermes Desktop Task Shell"**

Hermes Wing inherits the pinned Hermes Desktop visual language: a flat neutral rail, an open workspace, restrained blue selection and small, readable navigation. This documents the completed first shell/sidebar slice, not a newly invented brand. The source tokens below are normative only for the desktop shell; Flutter logical pixels are written as px for interchange.

The sidebar theme is local. The route subtree receives only the workspace scaffold background override; feature controls retain their existing app theme. Compact navigation retains its existing Material presentation. Neither Chat nor the rest of the app has been redesigned by this documentation.

**Key Characteristics:**
- Flat neutral rail and workspace backing
- Restrained blue selection with a disclosed accessible dark accent
- Reference navigation density with accessible control targets
- Local shell roles, not a replacement global theme

### Scope, lineage and acceptance

Source of truth: [AppShell](lib/shared/widgets/app_shell.dart),
[scoped desktop style](lib/shared/widgets/app_shell_desktop_style.dart), and
[nearest regression](test/shared/widgets/app_shell_reference_fidelity_test.dart).
The [surface direction](.impeccable/surfaces/lib-shared-widgets-app-shell-dart.md)
remains surface strategy; [PRODUCT.md](PRODUCT.md) owns product truth.

Read-only Hermes Desktop checkout verified at
`withdrawn reference revision`; this is a checkout pin, not a remote-latest claim.
Final source hashes match `.task-evidence/desktop-shell-fidelity/redesign-manifest.json`;
its older sibling `manifest.json` is superseded refinement evidence.
The [runbook](docs/runbooks/desktop-shell-reference-fidelity.md) and finish packet
record executor evidence. Their pending-review text predates the
independent verdict (local-only reference: `.task-evidence/desktop-shell-fidelity/focus-fix-verdict.md`):
**ship applies only to the two listed corrections** (toggle outline and typography
accuracy), both resolved. The font-description correction is not font bundling.
The parent-reported detector returned `[]`, exit 0, with limited Flutter coverage.
No whole-surface re-review, full-suite pass, native desktop, Android/iOS,
screen-reader, live Agent/provider, release or window-chrome qualification follows.
This pass completes design documentation, not additional implementation.

Remaining parity gaps: grouped recent sessions, real profile footer and icon-only
footer density, full sessions modal, multi-conversation tabs, Discover/Kanban/Memory
coverage, collapse relaunch persistence, exact bundled fonts and Lucide pictograms,
native window chrome, and the next Chat composer/transcript slice.

## Colors

One primary blue carries selection; neutrals carry structure. Frontmatter stores
exact source colors. Flutter ARGB transparency is translated to CSS RGBA hex
without rounding: selection alpha bytes are `14` light / `26` dark, and dark border
alpha is `0f`. These are translucent paints, not opaque sampled composites.

Official `@google/design.md lint DESIGN.md` reports no schema/reference errors,
but six warnings: two contrast checks compare against uncomposited selection
RGB, and four workspace/border colors are not referenced by the restricted
component property set. Preserve the actual paints rather than replacing them
with invented opaque tokens. Compositing selection over the real rail gives
contrast approximately 8.666:1 light and 6.339:1 dark; these calculated pairs
are not whole-app accessibility qualification.

### Primary

- **Reference Navy** (`primary`): light selected navigation text and sidebar primary role.
- **Accessible Sky Blue** (`dark-accent`): dark selected text. Intentionally replaces
  Desktop's dark `#006acd`; this accessible departure is not an exact match.
- **Translucent Reference Blue** (`light-selection`, `dark-selection`): selected row
  paint over the respective rail. Hover/focus uses the corresponding opaque overlay.

### Neutral

- **Soft Paper / Charcoal Rail** (`light-rail`, `dark-rail`): sidebar and status strip.
- **White / Graphite Workspace** (`light-work-area`, `dark-work-area`): backing and
  route scaffold background only.
- **Ink / Pale Ink** (`light-foreground`, `dark-foreground`): ordinary sidebar text/icons.
- **Quiet Ink / Silver Ink** (`light-secondary`, `dark-secondary`): status text,
  scoped icon theme, disabled-color basis and focus-outline color.
- **Hover Paper / Hover Charcoal** (`light-hover`, `dark-hover`): interactive overlays.
- **Soft Rule / Transparent White Rule** (`light-border`, `dark-border`): rail divider
  and status top rule; not a sidebar/workspace separator.

**The Scope Rule.** Shell roles are local; extending them to a feature requires a separate implementation and review.

## Typography

The configured inherited family is `Segoe UI`, with platform fallbacks defined
in `lib/theme/wing_theme.dart`. This is system/native fallback, not a claim that
a single named face renders on every platform.

- **Navigation:** `shell-nav`; regular inactive labels, semibold selection through
  `shell-nav-selected`. No display/headline scale is established here.
- **Status:** `shell-status`; inherited label weight, ellipsis and tooltip disclosure.
  No independent weight token is invented.
- **Icons:** Flutter Material icons, navigation/toggle (16px) and status (12px),
  not Desktop's Lucide set or circular-mark hover swap.

Earlier Manrope/Cairo comparisons are historical, not current official Desktop
parity evidence. Wing does not bundle those fonts. Exact font and script fidelity
remain unqualified; configured family names alone do not establish rendered parity.

## Layout

Below (600px), preserve the existing compact bottom navigation and More sheet.
At (600px) and above, the shell uses an expanded rail (250px) or collapsed rail
(64px), and a fixed header (64px). The toggle sits at the right when expanded,
centered when collapsed. Navigation/toggle targets remain at least (48×48px),
an intentional departure from smaller Desktop controls.

Workflow occupies the top; existing Loaded sessions appears only when expanded;
utilities anchor below. Workflow/Utilities headings are semantic, not painted.
Short windows scroll navigation while keeping the toggle available. Group padding
is (8px horizontal, 4px vertical), row exterior spacing (2px vertical), button
padding (10px horizontal, 7px vertical), icon/label gap (10px).

Workspace consumes remaining width, without the former 1180px content cap.
The full-width status strip has minimum height (26px), padding (12px horizontal,
4px vertical), column gaps (12px), icon/text gaps (6px). Height can grow with text;
do not replace the minimum with a clipping fixed height. These source dimensions
are shell facts, not feature page grids.

## Elevation & Depth

The shell is flat: no new shell shadows, gradients, glass or ornamental lift.
Rail/work-area tone, selection paint and restrained rules establish hierarchy.
Existing feature dialogs and compact sheets remain outside this depth specification.
Sidecar tonal ramps are synthesized panel swatch aids, not implemented Flutter
tokens; translucent colors' ramps use their opaque RGB basis, not blended samples.

## Shapes

Shell buttons share gently rounded corners through `rounded.shell-control`.
Rail/workspace are rectangular regions, not floating cards. Focus follows the
control shape; the repaired toggle has no circular default focus halo.

## Components

### Navigation rows

Quiet route-selected TextButtons. Default paint is transparent over the rail;
frontmatter default component backing records that visible rail, not extra fill.
Selected rows use selection paint and semibold accent text. Hover/focus uses the
opaque hover overlay; navigation focus has a secondary shaped border (default
BorderSide width 1px). Disabled foreground uses secondary at alpha (0.55).
Source button animation duration is (150ms); no independent easing token is invented.
Collapsed rows retain names, tooltips and selected semantics; keyboard focus brings
rows into view. Nine real routes and their existing ordering remain unchanged.

### Collapse/expand toggle

Named IconButton with (48×48px) geometry and shared corners. Focus wins over hover:
transparent focused overlay exposes a continuous (2px) secondary-color outline.
Unfocused hover retains the hover fill. This override is toggle-only; do not assign
its outline width to nav rows. Collapse is immediate and retains route child,
draft and keyboard focus. It is presentation-only, performs no Agent operation,
and does not persist across relaunch.

### Loaded sessions and status

Loaded sessions reuses existing owner-scoped controls inside the sidebar theme;
Open/New Session reaches Chat only after exact acknowledgement. Collapse removes
these controls from focus/semantics. This is not grouped recents or a full modal;
no new domain state or incidental inventory reads are introduced. Status shows
existing bounded connection/profile/model/inventory values, with ellipsis and
tooltips. Do not synthesize authoritative state to populate it.

The sidecar contains self-contained HTML/CSS **documentation previews** of nav/toggle
roles in both schemes, using inline illustrative icons. These are not a Flutter
runtime, exact Material glyph capture, native qualification or implemented web
components. No inputs, chips or cards are invented for this shell-only set.
No shipping raster was added. Agent/Wing Link authority remains unchanged.

## Do's and Don'ts

### Do:
- **Do** apply these tokens only to the implemented desktop shell and its status strip.
- **Do** preserve nine real destinations, named collapsed controls and exact acknowledged loaded-session actions.
- **Do** retain visible keyboard focus and immediate collapse without transferring route or draft ownership.
- **Do** disclose accessible adaptations and missing reference workflows.

### Don't:
- **Don't** apply shell typography or palette to untouched feature controls or compact navigation by implication.
- **Don't** describe the system fallback or Material icons as exact Manrope/Cairo or Lucide parity.
- **Don't** fabricate recents, profile state, unsupported destinations or Agent capabilities to complete the picture.
- **Don't** treat a fix-list ship verdict, CSS specimen or empty detector result as whole-app or native qualification.
