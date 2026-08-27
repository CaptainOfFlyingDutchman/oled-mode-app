# App icon pipeline

OLED Mode uses a two-layer icon pipeline. Large sizes come from a photoreal 1024×1024 master. Tiny sizes are drawn in AppKit so type does not smear in the Dock, Spotlight, or Finder list view.

## Design

The mark is a dark nested control panel with:

- a matte charcoal chassis and recessed well
- a mustard/amber stadium (pill) button
- two lines of equal-weight type on the pill: **OLED** / **MODE**
- a small amber LED above the pill (on state)

`POWER` / `OLED ON` is the in-app latch, not the Dock wordmark. The yellow pill is what ties the icon to the app chrome.

macOS applies a squircle mask. The artwork is already a rounded square that nearly fills the canvas.

## Size rules

| Point size | Pixel files | Artwork |
|---|---|---|
| 16pt | 16, 32 (`@2x`) | Drawn. No type. Pill + LED + chassis. |
| 32pt | 32, 64 (`@2x`) | Drawn. No type. Slightly larger pill and LED. |
| 128pt and up | 128, 256, 512, 1024 | Scaled from the 1024 master. Full panel, type, glow, nested bevels. |

Do not ship one 1024 and scale it all the way down. At 32pt, `OLED` / `MODE` becomes a dark smear across the pill, which is worse than no type.

The Dock / Applications / Spotlight icon is always the **on** state (lit pill + LED). An off-state mark is fine in-app, not as the app icon.

## Files

| Path | Role |
|---|---|
| `scripts/oled-mode-icon-1024.png` | 1024×1024 master. Source of truth for 128px and up. |
| `scripts/GenerateIcon.swift` | Writes every PNG the asset catalog expects. |
| `OLEDMode/Assets.xcassets/AppIcon.appiconset/` | Icon set Xcode compiles into `AppIcon.icns`. |
| `OLEDMode/Assets.xcassets/AppIcon.appiconset/Contents.json` | Slot names. Do not rename files without updating this. |

`GenerateIcon.swift` looks for the master next to itself. If that PNG is present, sizes **≥ 128px** are rasterized from it. Sizes **≤ 64px** are always drawn (`drawIcon`), even if the master exists.

Drawn colors match `DeckTheme` (chassis, amber, amberHot, ink). Nested bevels and type are omitted below 128px.

## Regenerate the icon set

From the repo root:

```bash
swift scripts/GenerateIcon.swift OLEDMode/Assets.xcassets/AppIcon.appiconset
```

This writes:

```
icon_16x16.png          16px    drawn
icon_16x16@2x.png       32px    drawn
icon_32x32.png          32px    drawn
icon_32x32@2x.png       64px    drawn
icon_128x128.png        128px   from master
icon_128x128@2x.png     256px   from master
icon_256x256.png        256px   from master
icon_256x256@2x.png     512px   from master
icon_512x512.png        512px   from master
icon_512x512@2x.png     1024px  from master
```

If the master is missing, the script draws every size, including 128px+ with `OLED` / `MODE`. That fallback is flatter than the photoreal master.

## Rebuild and run

Xcode compiles the asset catalog into `AppIcon.icns` at build time. Regenerating PNGs is not enough until you rebuild.

```bash
killall "OLED Mode" 2>/dev/null || true

xcodebuild \
  -project OLEDMode.xcodeproj \
  -scheme "OLED Mode" \
  -configuration Debug \
  -derivedDataPath build

open "build/Build/Products/Debug/OLED Mode.app"
```

The product is `build/Build/Products/Debug/OLED Mode.app`. A Release build lands under `build/Build/Products/Release/`.

## Dock still shows the old icon

macOS caches app icons. After a rebuild:

1. Quit OLED Mode.
2. Open the newly built `.app` (not a stale copy in `/Applications`).
3. If the Dock tile is still old:

```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "build/Build/Products/Debug/OLED Mode.app"
killall Dock
```

`killall Dock` restarts the Dock in about a second.

## How to change the look

**Large icon (Dock, About, Spotlight large)**  
Replace `scripts/oled-mode-icon-1024.png` with a new **1024×1024** PNG. Keep the same composition: dark panel, yellow pill, `OLED` / `MODE`, amber LED, no extra captions or chrome. Then run the `swift` command and rebuild.

**Small icon (16 / 32 / 64)**  
Edit `drawIcon(pixelSize:)` in `scripts/GenerateIcon.swift`. The important branches:

- `showText = pixelSize >= 128` — keep this false for the drawn small sizes
- `simplify = pixelSize <= 64` — drops nested bevels
- pill and LED dimensions are per-size so 16px stays a yellow bar + a 2px LED

Then regenerate and rebuild.

**Slot names**  
Keep the filenames in `Contents.json`. If you add or rename a PNG, update that file or Xcode will ignore the asset.

## One-shot from a new master

```bash
# 1. Save the new 1024×1024 artwork
cp /path/to/new-icon.png scripts/oled-mode-icon-1024.png

# 2. Expand into the asset catalog
swift scripts/GenerateIcon.swift OLEDMode/Assets.xcassets/AppIcon.appiconset

# 3. Rebuild and launch
killall "OLED Mode" 2>/dev/null || true
xcodebuild -project OLEDMode.xcodeproj -scheme "OLED Mode" \
  -configuration Debug -derivedDataPath build
open "build/Build/Products/Debug/OLED Mode.app"
```
