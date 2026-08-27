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

macOS caches Dock tiles by **bundle ID** (`com.manvendrask.oled-mode`). `killall Dock` alone is usually not enough. The running tile is also the icon from **process launch**, so a long-lived Xcode Run keeps the old mark until that process dies.

There are often several copies of the same app. Launch Services / Dock may keep showing whichever one launched first:

| Copy | Typical source |
|---|---|
| `~/Applications/OLED Mode.app` | Installed / copied app (what you usually pin) |
| `build/Build/Products/Debug/OLED Mode.app` | `xcodebuild -derivedDataPath build` |
| `~/Library/Developer/Xcode/DerivedData/OLEDMode-*/Build/Products/Debug/OLED Mode.app` | Product ▸ Run in Xcode |

Confirm which process owns the tile:

```bash
pgrep -lf "OLED Mode"
```

### 1. Quit every copy

If you launched with **Product ▸ Run** in Xcode, stop that session first (**Product ▸ Stop**, or ⌘.). The debugger holds the process; `killall` often cannot kill it, and that live Dock tile keeps the old icon.

Then:

```bash
killall "OLED Mode" 2>/dev/null || true
killall -9 "OLED Mode" 2>/dev/null || true
pgrep -lf "OLED Mode" || echo "all copies quit"
```

If `pgrep` still shows a path under `DerivedData`, Xcode is still attached — stop the Run session and repeat.

### 2. Flush the user Dock + Icon Services caches

No sudo. This deletes only your user’s caches under `/var/folders/.../C/`.

```bash
CACHE="$(getconf DARWIN_USER_CACHE_DIR)"
rm -rf "${CACHE}com.apple.dock.iconcache" \
       "${CACHE}com.apple.iconservices"
```

### 3. Re-register the bundle you actually launch

```bash
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

APP="$HOME/Applications/OLED Mode.app"   # or the Debug .app you just built
touch "$APP" "$APP/Contents/Info.plist" "$APP/Contents/Resources/AppIcon.icns"
"$LSREGISTER" -f "$APP"

killall Dock
open "$APP"
```

`killall Dock` restarts the Dock in about a second. The new tile should appear when the app relaunches.

### 4. Still stuck — system Icon Services store

Only if step 2 did not change the tile. This rebuilds icons for **all** apps, so the Dock and Finder flicker while caches come back.

```bash
sudo rm -rf /Library/Caches/com.apple.iconservices.store
killall Dock
killall Finder
```

Do **not** run `lsregister -kill`. On Sequoia and later it can wipe System Settings contents.

Do **not** `find /private/var/folders ... -exec rm` as a broad sweep. The `getconf DARWIN_USER_CACHE_DIR` paths above are the safe, user-scoped equivalents of `com.apple.dock.iconcache` and `com.apple.iconservices`.

### 5. Last resort

Log out and back in, or reboot. Icon Services rebuilds on a full session restart. If two copies are running at once (`pgrep` shows both DerivedData and `~/Applications`), quit them and open only one.

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

# 3. Stop Xcode’s Run session (Product ▸ Stop / ⌘.) so the debugger
#    is not holding an old Dock tile, then quit every remaining copy.
killall "OLED Mode" 2>/dev/null || true

# 4. Rebuild
xcodebuild -project OLEDMode.xcodeproj -scheme "OLED Mode" \
  -configuration Debug -derivedDataPath build

# 5. Flush Dock icon cache and relaunch one copy
CACHE="$(getconf DARWIN_USER_CACHE_DIR)"
rm -rf "${CACHE}com.apple.dock.iconcache" "${CACHE}com.apple.iconservices"
killall Dock
open "build/Build/Products/Debug/OLED Mode.app"
```

If the tile is still old, follow [Dock still shows the old icon](#dock-still-shows-the-old-icon).
