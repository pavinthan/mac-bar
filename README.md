# MacBar

A lightweight macOS menu bar utility that puts quick-access tools and system info one click away.

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Word Clock** — Current time displayed as a sentence, with multiple timezone support
- **Default Browser** — Switch your default browser with one click
- **Quick Actions**
  - Color Picker — Pick any color on screen, auto-copies in your preferred format (HEX, RGB, HSL, SwiftUI)
  - Cleaning Mode — Hide desktop icons and dock for presentations
  - QR Scanner — Select a region on screen to scan and copy QR code content
  - Mute Sound / Mute Mic — Toggle system audio and microphone
- **System Stats** — CPU, Memory, Disk usage with color-coded progress bars, plus network speed
- **AI Usage** — Auto-detects your Claude subscription (Pro/Max/Team/Enterprise) and shows session, weekly, and model-specific usage limits

## Install

### From GitHub Releases

1. Download `MacBar.zip` from the [latest release](https://github.com/pavinthan/mac-bar/releases/latest)
2. Unzip it
3. Open Terminal and run:
   ```
   xattr -cr ~/Downloads/MacBar.app
   ```
4. Move `MacBar.app` to `/Applications`
5. Double-click to open

> The `xattr` command is needed because the app is not notarized with Apple. This is safe for apps you trust.

### Build from Source

```bash
git clone https://github.com/pavinthan/mac-bar.git
cd mac-bar
xcodebuild -project MacBar.xcodeproj -scheme MacBar -configuration Release -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES
cp -R build/Build/Products/Release/MacBar.app /Applications/
```

## AI Usage Tracking

MacBar automatically detects Claude Code credentials from `~/.claude/.credentials.json` and displays your subscription usage. No manual setup required — if you use Claude Code, it just works.

## Requirements

- macOS 15.0+
- Screen Recording permission (for QR scanner only)

## License

MIT
