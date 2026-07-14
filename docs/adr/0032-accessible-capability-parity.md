# ADR 0032: Require accessible capability parity

Status: accepted
Date: 2026-07-13

Navivox treats WCAG 2.2 Level AA, where applicable to Flutter applications, plus each target platform's accessibility conventions as capability-parity requirements. A capability is not validated when its user outcome depends only on a 3D or canvas surface, pointer input, speech, motion, sound, or color.

## Acceptance baseline

- Interactive controls expose useful names, roles, values, states, and validation errors to assistive technology.
- Navigation, dialogs, menus, lists, editors, approvals, and destructive confirmations have logical focus order, visible focus, focus restoration, and complete keyboard operation on desktop.
- Android critical flows work with TalkBack; each desktop critical flow works with keyboard-only input and a supported screen reader for that platform.
- Layouts preserve content and actions at 200% text scaling and adapt to the larger accessibility settings supported by the platform.
- Text and essential UI indicators meet AA contrast; color, animation, audio, spatial position, and gestures are never the sole carrier of meaning or action.
- Touch targets follow the platform's accessible minimum, using at least 48 by 48 logical pixels for primary Android controls.
- Reduced-motion preferences suppress non-essential animation without removing state feedback.
- Speech input and text-to-speech remain optional enhancements; equivalent text controls and transcripts are available.

## Office consequence

The desktop 3D Office remains a parity requirement, but every Office action and state also exists through a non-spatial semantic presentation using the same interaction model. The accessible presentation is an equivalent path, not a reduced read-only fallback.

## Evidence

Focused semantics, focus, keyboard, scaling, contrast, and reduced-motion tests provide repeatable checks. Milestone receipts also include manual assistive-technology coverage on Android and each retirement-gate desktop platform. Accessibility defects block validation of the affected capability.
