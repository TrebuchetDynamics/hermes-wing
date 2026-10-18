# Installed Desktop shared control contract

Reference: official installed Agent `d923a5eb487a17c0a68801bba9ef0f56c81040a8`, read-only.

`apps/desktop/src/themes/presets.ts:32-46` defines system sans (Segoe UI/SF Pro/system fallbacks), not bundled Manrope. Wing maps the native family names and keeps emoji fallback. This corrects earlier design prose describing Manrope as the current installed default; the earlier GitHub snapshot and installed revision are distinct references.

`apps/desktop/src/components/ui/button.tsx:11-15` implements 2.5px text-button corners. Wing applies the same geometry to shared filled, outlined and text controls, preserving 48px minimum targets for touch and enlarged text rather than copying desktop-only small targets.

This shared theme is part of the ongoing shell/Chat/settings reconstruction, not an independent whole-app fidelity claim. Platform font availability can change the resolved face. Actual live Desktop CDP was unavailable on the documented port 9222; no user process was restarted to expose it.
