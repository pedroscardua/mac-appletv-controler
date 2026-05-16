# Apple TV Remote — macOS Menu Bar Controller

Control your Apple TV right from your Mac's menu bar. A full-featured Siri Remote clone that lives in your menu bar, discovers Apple TVs automatically, and supports press-and-hold gestures.

<p align="center">
  <img src="Resources/AppleTVRemote.icns" width="128" alt="Apple TV Remote icon">
</p>

---

## Table of Contents

- [Download & Install](#download--install)
- [First-Time Setup (Pairing)](#first-time-setup-pairing)
- [How to Use](#how-to-use)
- [Requirements](#requirements)
- [Build from Source](#build-from-source)
- [Architecture](#architecture)
- [Makefile Reference](#makefile-reference)
- [App Store Submission](#app-store-submission)
- [Troubleshooting](#troubleshooting)
- [Privacy](#privacy)
- [Credits](#credits)

---

## Download & Install

### Option 1: Download DMG (Recommended)

1. Go to [Releases](https://github.com/pedroscardua/mac-appletv-controler/releases)
2. Download `AppleTVRemote.dmg`
3. Open the DMG and drag `Apple TV Remote.app` to your `Applications` folder
4. Launch from Launchpad or Spotlight

### Option 2: Homebrew (Coming Soon)

```bash
brew install --cask apple-tv-remote
```

### Option 3: Build from Source

See [Build from Source](#build-from-source) below.

> **Note:** macOS may warn that the app is from an "unidentified developer." Go to **System Settings → Privacy & Security** and click **Open Anyway**.

---

## First-Time Setup (Pairing)

Apple TV requires a one-time pairing before the remote can send commands. The app will guide you through it automatically.

### Step-by-Step

| Step | What you see | What you do |
|------|-------------|-------------|
| 1. Launch | Menu bar icon appears (Apple TV logo) | Click the icon |
| 2. Discover | App scans your network | Wait 5 seconds |
| 3. Select | List of Apple TVs found | Click your Apple TV name |
| 4. Pair | Message: *"This Apple TV needs to be paired"* | Click **Pair** |
| 5. PIN | Your TV screen shows a 4-digit code | Type it into the app |
| 6. Done | Remote control appears | Start using it! |

**Credentials are saved** in `~/.appletv_control/credentials.json`. Pairing only happens once — subsequent launches connect automatically.

### Re-pairing

If your Apple TV changes or credentials expire:
1. Click **Disconnect** in the remote popup
2. Select your Apple TV again
3. Click **Pair** and repeat the PIN flow

---

## How to Use

Click the Apple TV icon in the menu bar to open the remote. Click anywhere outside the popup to close it.

### Button Reference

| Button | Icon | Action | Press & Hold |
|--------|------|--------|-------------|
| **Up / Down / Left / Right** | ▲ ▼ ◀ ▶ | Navigate menus | Continuous scroll |
| **Select** | ● | Confirm selection | — |
| **Menu** | ☰ | Back / Context menu | Context menu (long press) |
| **Home** | 📺 | Home screen | App switcher |
| **Play/Pause** | ▶⏸ | Toggle playback | — |
| **Previous / Next** | ⏪ ⏩ | Skip track | — |
| **Volume Up / Down** | 🔊🔉 | Adjust volume | — |
| **Sleep** | ⏻ | Put Apple TV to sleep | — |

### Press-and-Hold

All directional buttons, Select, Menu, and Home support press-and-hold:

- **Tap** (< 350ms) — single press (normal click)
- **Hold** (≥ 350ms) — triggers hold action (continuous scroll, context menu, app switcher)

The button highlights more intensely during a hold, and the Apple TV auto-repeats while held.

---

## Requirements

| Component | Minimum | Notes |
|-----------|---------|-------|
| macOS | 14.0 (Sonoma) | Required for SwiftUI features |
| Python | 3.9+ | Only needed when building from source |
| pyatv | 0.17.0+ | Installed via pip (`pip3 install pyatv`) |
| Apple TV | tvOS 14+ | Uses Companion protocol (tvOS 26+ optimized) |
| Network | Same LAN | iPhone and Apple TV must be on the same network |

---

## Build from Source

### Prerequisites

```bash
# 1. Clone the repo
git clone https://github.com/pedroscardua/mac-appletv-controler.git
cd mac-appletv-controler

# 2. Install Python dependencies
pip3 install pyatv

# 3. Verify Swift toolchain
swift --version  # Should be 5.9+
```

### Quick Start (Development)

```bash
make run          # Build debug binary + .app + launch
```

This opens the app directly. Look for the Apple TV icon in your menu bar.

### Build Release

```bash
make build-release  # Compile optimized binary
make app-release    # Create release .app bundle
make dmg            # Package as DMG
```

The DMG is created at `AppleTVRemote.dmg`.

### Build with Code Signing

```bash
make sign-dev       # Sign with Apple Development certificate
make dmg-signed     # Create signed DMG
make notarize       # Notarize with Apple (requires Apple ID + team)
```

> **Note:** Code signing requires an Apple Developer certificate. The Makefile uses the default certificate for `pedroscardua210@gmail.com (5C844FF8Y9)`. Edit `DEV_CERT` in the Makefile if using a different certificate.

---

## Architecture

```
┌──────────────────────────────────────┐
│         SwiftUI Menu Bar App          │
│                                      │
│  ┌──────────┐    ┌───────────────┐   │
│  │ App.swift │───▶│ MenuBar       │   │
│  │ @main     │    │ Controller    │   │
│  └──────────┘    │ NSStatusBar   │   │
│                  │ NSPopover     │   │
│                  └──────┬────────┘   │
│                         │            │
│  ┌──────────────────────▼─────────┐  │
│  │        RemoteView.swift        │  │
│  │  ┌─────┐  ┌──────┐  ┌──────┐  │  │
│  │  │D-Pad│  │Playbk│  │Nav/Vol│  │  │
│  │  └─────┘  └──────┘  └──────┘  │  │
│  └──────────────┬─────────────────┘  │
│                 │ @EnvironmentObject │
│  ┌──────────────▼─────────────────┐  │
│  │     AppleTVBridge.swift        │  │
│  │  Process(stdin) → JSON cmds    │  │
│  │  Process(stdout) ← JSON resp   │  │
│  └──────────────┬─────────────────┘  │
└─────────────────┼────────────────────┘
                  │ Unix pipe (stdin/stdout)
┌─────────────────▼────────────────────┐
│       Python Bridge (bridge.py)       │
│                                      │
│  ┌──────────┐    ┌───────────────┐   │
│  │  scan()  │    │  connect()    │   │
│  │  pyatv   │    │  Companion    │   │
│  │  scan()  │    │  protocol     │   │
│  └──────────┘    └──────┬────────┘   │
│                         │            │
│  ┌──────────────────────▼─────────┐  │
│  │     do_command()               │  │
│  │  SingleTap / Hold / DoubleTap  │  │
│  │  HID commands over Companion   │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  FileStorage                   │  │
│  │  ~/.appletv_control/           │  │
│  │  credentials.json              │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

### Key Components

| File | Purpose |
|------|---------|
| `App.swift` | Entry point, sets up `NSApplicationDelegate` |
| `MenuBarController.swift` | Menu bar icon (`NSStatusBar`), popover toggle |
| `RemoteView.swift` | SwiftUI remote control UI with gesture handling |
| `AppleTVBridge.swift` | Manages Python subprocess, JSON protocol, `@Published` state |
| `Models.swift` | `AppleTVDevice`, `RemoteCommand`, data types |
| `bridge.py` | Python backend: scan, connect, pair, HID commands |
| `generate_icon.py` | Generates `.icns` icon from Pillow |

### Protocol

The Swift app and Python bridge communicate via newline-delimited JSON over stdin/stdout:

**Input (Swift → Python):**
```json
{"action": "scan"}
{"action": "connect", "identifier": "AA:BB:CC:DD:EE:FF"}
{"action": "begin_pairing"}
{"action": "submit_pin", "pin": "1234"}
{"action": "command", "command": "up"}
{"action": "hold_command", "command": "down"}
{"action": "disconnect"}
{"action": "quit"}
```

**Output (Python → Swift):**
```json
{"type": "scan_result", "devices": [{"name": "Living Room", "identifier": "...", "paired": true}]}
{"type": "pairing_required", "name": "Living Room", "message": "..."}
{"type": "pairing_started", "message": "Enter PIN from TV"}
{"type": "pairing_success", "message": "Paired!"}
{"type": "connected", "name": "Living Room"}
{"type": "ok"}
{"type": "error", "message": "..."}
{"type": "disconnected"}
{"type": "bye"}
```

---

## Makefile Reference

### Development

| Command | Description |
|---------|-------------|
| `make build` | Compile debug binary |
| `make app` | Create debug `.app` bundle |
| `make run` | Build, bundle, and launch |
| `make install` | Copy app to `/Applications` |

### Release

| Command | Description |
|---------|-------------|
| `make build-release` | Compile optimized release binary |
| `make app-release` | Create release `.app` bundle with icon + entitlements |
| `make dmg` | Package as unsigned DMG |
| `make sign-dev` | Sign app with Development certificate |
| `make sign-dist` | Sign app with Distribution certificate |
| `make dmg-signed` | Create code-signed DMG |
| `make notarize` | Submit DMG for Apple notarization |
| `make app-store` | Create signed `.pkg` for App Store submission |

### Utilities

| Command | Description |
|---------|-------------|
| `make icon` | Generate `.icns` from Python script |
| `make clean` | Remove `.app`, `.dmg`, `.pkg`, and build artifacts |

---

## App Store Submission

### Prerequisites

- [ ] Apple Developer Program membership ($99/year)
- [ ] Xcode installed (not just Command Line Tools)
- [ ] Apple Distribution certificate in Keychain
- [ ] App Store Connect app record created
- [ ] Privacy policy hosted at a public URL

### Step-by-Step

**1. Create App Record**

Go to [App Store Connect](https://appstoreconnect.apple.com) → My Apps → New App:
- Platform: **macOS**
- Name: **Apple TV Remote**
- Bundle ID: **com.pedro.appletvremote**
- SKU: **ATVR001**

**2. Build and Sign**

```bash
# Ensure DEV_CERT and DIST_CERT in Makefile match your certificates
security find-identity -v -p codesigning

# Build the App Store package
make app-store
```

This creates `AppleTVRemote.pkg` signed with your Distribution certificate.

**3. Upload**

Using **Transporter** app (from Mac App Store):
- Open Transporter → drag `AppleTVRemote.pkg`
- Click **Deliver**

Or using command line:
```bash
xcrun altool --upload-app -f AppleTVRemote.pkg \
  -t macos \
  -u "your@email.com" \
  -p "@keychain:Application Loader:your@email.com"
```

**4. Complete Metadata**

In App Store Connect, fill in:
- **Description** — see `AppStore/metadata.json`
- **Keywords** — apple tv, remote, control, menu bar
- **Screenshots** — required: 1280×800, 1440×900, 2560×1600, 2880×1800
- **Privacy Policy URL** — publish `AppStore/privacy-policy.md` to a public URL
- **Category** — Utilities
- **Rating** — No restrictions

**5. Submit for Review**

Click **Submit for Review** in App Store Connect. Review typically takes 24-48 hours.

### Entitlements

The app uses these entitlements (`Resources/AppleTVRemote.entitlements`):

```xml
com.apple.security.app-sandbox        = true   (required for App Store)
com.apple.security.network.client     = true   (scan + connect to Apple TV)
com.apple.security.network.server     = true   (mDNS discovery)
com.apple.security.files.user-selected.read-only = true
```

### Screenshot Guidelines

Required resolutions for Mac App Store:
- **1280×800** (MacBook Pro 13")
- **1440×900** (MacBook Air)
- **2560×1600** (MacBook Pro Retina)
- **2880×1800** (MacBook Pro 15" Retina)

Tips:
- Show the menu bar icon with the remote popover open
- Show the device picker and the remote UI
- Use `screencapture -W` to capture a specific window
- Do not include the mouse cursor

---

## Troubleshooting

### "No Apple TVs found"

1. Make sure your Apple TV is powered on and awake
2. Verify both devices are on the same Wi-Fi network
3. Check that your Mac's firewall allows local network access
4. Restart your Apple TV

### "command failed: up is not supported"

The device needs pairing. Click **Disconnect** → select your Apple TV → click **Pair** → enter the PIN shown on your TV screen.

### "bridge.py not found"

This happens when running outside the app bundle. Ensure you're running the compiled `.app`, not the raw binary:

```bash
make run     # Correct — launches the .app bundle
```

### "pairing failed" or "PIN submission failed"

1. Make sure you entered the correct PIN (shown on TV screen)
2. The PIN times out after ~30 seconds — click **Pair** again for a new PIN
3. Try restarting both the app and the Apple TV

### "not connected" error

The bridge lost connection to the Apple TV. Close the popup and reopen it — the app will auto-reconnect.

### Port already in use

Only one instance can run at a time. Check for existing processes:

```bash
pkill -f AppleTVRemote
```

### Reset Everything

```bash
# Remove app, credentials, and cache
rm -rf ~/Applications/AppleTVRemote.app
rm -rf ~/.appletv_control/
rm -rf ~/Library/Caches/com.pedro.appletvremote/
```

Then reinstall and pair again.

---

## Privacy

Apple TV Remote does **not** collect, store, or transmit any personal information.

- No analytics, no tracking, no crash reporting
- No data sent to external servers — only local network communication with Apple TV
- Pairing credentials stored locally in `~/.appletv_control/`
- No account required, no sign-in

See the full privacy policy at [AppStore/privacy-policy.md](AppStore/privacy-policy.md) or the hosted URL in the App Store listing.

---

## Credits

- **SwiftUI + AppKit** — Native macOS menu bar app and remote UI
- **[pyatv](https://github.com/postlund/pyatv)** — Python library for Apple TV communication
- **Companion protocol** — Used by tvOS 26+ for remote control, pairing, and HID commands
- **SF Symbols** — Apple's icon set used throughout the UI

### License

MIT License — see [LICENSE](LICENSE) file.

---

<p align="center">
  Made for macOS • Works with Apple TV HD, 4K, and 4K (3rd gen) • tvOS 14–26+
</p>
