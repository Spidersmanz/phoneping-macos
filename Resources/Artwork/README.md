# PhonePing artwork

The app icon is drawn directly as editable SVG geometry. It uses the selected B design: a graphite phone, a light neutral screen, grey ringing marks, and a transparent background. There is no coloured tile. There are no embedded raster images, fonts, scripts, external references, gradients, or filters. The earlier generated concept is not used in these assets.

- `PhonePing.svg`: full-size master with two arcs on each side.
- `PhonePing-small.svg`: optical variant for 16- and 32-point icons, with a stronger frame and one arc per side.
- `../AppIcon.icns`: packaged macOS icon, generated from the two sources. Builds copy this file into the application; they need no graphics dependencies.

The app's menu bar control keeps its native monochrome SF Symbol and its busy/attention states. The neutral phone icon is for the application bundle and About panel. The maintainer selected this direction on October 12, 2026.

## Exporting an edit

Keep both SVG view boxes at 1024 × 1024 and preserve the transparent outer margin. Export RGBA PNGs from a vector editor into a folder named `PhonePing.iconset`:

| File at standard resolution | Standard pixels | Retina pixels | Source |
| --- | --- | --- | --- |
| icon_16x16.png | 16 × 16 | 32 × 32 | Small |
| icon_32x32.png | 32 × 32 | 64 × 64 | Small |
| icon_128x128.png | 128 × 128 | 256 × 256 | Full |
| icon_256x256.png | 256 × 256 | 512 × 512 | Full |
| icon_512x512.png | 512 × 512 | 1024 × 1024 | Full |

For each Retina file, insert the suffix `@2x` before the `.png` extension. Run `python3 scripts/package-icon.py PhonePing.iconset Resources/AppIcon.icns` from the repository root. This writes PNG representations directly into the native icon container, avoiding colour changes in legacy bitmap representations. The package contains no separate metadata section.

Inspect the exports on light and dark backgrounds and decode the ICNS with macOS before updating the exact reviewed-asset hash in `scripts/check-privacy.py`. A changed asset remains blocked by the publication check until reviewed. The artwork is covered by the repository's MIT license.
