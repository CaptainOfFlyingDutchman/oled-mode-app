# OLED Mode

A small macOS control deck for OLED displays.

macOS keeps bright, static chrome on screen: the menu bar, the Dock, and the Stage Manager strip. On OLED that is not decoration. It is a burn-in pattern. This app exists to put that chrome away in one motion, and to bring your previous layout back just as easily.

## Purpose

OLED Mode is a local utility, not a settings replacement.

- **POWER** arms an OLED-friendly preset: menu bar always hidden, Dock auto-hidden, Stage Manager strip hidden when Stage Manager is on.
- Arming saves whatever you had. Disarming restores that snapshot instead of forcing everything visible.
- The four menu-bar keys, Dock **HIDE**, and Stage **HIDE** are there so you can still trim one surface without opening System Settings.
- If Stage Manager is off, that row stays offline and is not part of the preset. Mixed manual changes pop POWER out.

It lives in `~/Applications`. It does not need admin rights.

## Philosophy

Persistent UI is the enemy of an OLED panel. The right default is not “toggle each control independently.” The right default is one honest button that means **make this desktop OLED-safe**, then get out of the way.

The deck is built like hardware because the job is physical: lamps and latching keys, not a preferences form. Amber means armed. Idle means unlit. Close the window when you are done; the app stays in the Dock. Hover the Dock or use Spotlight when the chrome you just hid is the chrome you would have clicked.

The window is a dark chassis on purpose. It should be findable on a black wallpaper, and it should not itself become a bright rectangle you then have to hide.

## Controls

| Control | What it does |
|---|---|
| **POWER** | Apply or restore the OLED preset |
| **NEVER / FULL SCR / DESKTOP / ALWAYS** | Menu bar hide mode (macOS's four states) |
| **DOCK HIDE** | Dock auto-hide |
| **STAGE STRIP HIDE** | Stage Manager recent-apps strip |

First launch will ask to control **System Events**. Allow that, or the keys cannot change Dock and menu bar.

## Build

macOS 15 or later. Unsigned local build; no App Store account required.

Xcode's Play button runs a copy under DerivedData. It does **not** install into `~/Applications`. After you clone, build Release and copy the `.app` with `ditto` (not `cp -R`). `ditto` is a macOS tool that copies an app bundle with the metadata Finder and Launch Services expect.

```bash
git clone <this-repo> oled-mode-app
cd oled-mode-app

xcodebuild -project OLEDMode.xcodeproj -scheme "OLED Mode" \
  -configuration Release -derivedDataPath ./build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES

mkdir -p "$HOME/Applications"
ditto "build/Build/Products/Release/OLED Mode.app" \
  "$HOME/Applications/OLED Mode.app"

open "$HOME/Applications/OLED Mode.app"
```

Then launch from Spotlight or `~/Applications`. First run may ask to open an unsigned app; choose Open.

## License

MIT. See [LICENSE](LICENSE).
