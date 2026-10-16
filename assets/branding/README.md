# Wing logo and app icons

The owner supplied the blue/white portrait with winged headphones as Wing's logo
and app icon. The unchanged [original JPEG](wing-logo-original.jpg) is retained
for provenance. The [transparent raster master](wing-logo-master.png) removes
only the outside white corners, not the white portrait or blue artwork. Neither
source has been traced, cropped, upscaled or redrawn. This records the owner's
selection, not an independent authorship or licensing conclusion.

## Pick the right format

- **README and Markdown docs:** [256px transparent PNG](wing-logo-256.png), displayed
  at 64–80px with alt text. PNG works on GitHub, light and dark backgrounds.
- **App UI:** the existing `hermes-emblem.png` runtime path now contains the
  transparent Wing image at 512px; the compatibility filename is not Hermes Agent
  artwork. The widget keeps its existing aspect-preserving layout.
- **Web:** [512px lossless transparent WebP](wing-logo-512.webp) is available when
  appropriate. Site navigation/favicon uses its dedicated transparent PNG;
  ordinary web app icons also retain alpha.
- **Windows:** [multi-size transparent ICO](wing-logo.ico); the runner's ICO keeps
  its established frame sizes. Android's existing launcher PNGs retain alpha.
- **Apple app-icon resources:** composite the artwork on the source-edge blue
  background, not white, because distribution icons must be opaque. Web maskable
  icons use that blue plate and a centered 56% safe-area square so masks cannot
  clip the artwork. Do not use these opaque platform derivatives as a docs logo.

Do not flatten the transparent logo onto white or put a checkerboard preview in
production. Do not claim an embedded raster SVG is a vector original.

## Provenance and checks

[The manifest](wing-logo-provenance.json) records both source hashes and all 38
consumer resources, dimensions, transforms, alpha policies and output hashes.
Only the runtime PNG is registered by Flutter; original/provenance/download files
are not added to its asset bundle. No dependency, app ID, credentials or Agent
state changes are involved.

`test/tooling/wing_branding_assets_test.dart` pins the approved source/master,
checks output hashes/dimensions, decodes PNG/WebP alpha and blue corner pixels,
checks ICO frame counts and verifies README/docs/site references. Generation also
checks every PNG and ICO frame against its source transform. Real-widget and
local README/docs/site renders check placement on light/dark backgrounds.
Resource checks and preview rendering are not installed-launcher, OS-mask,
Apple signing, store delivery, or physical-device qualification.
