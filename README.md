# Apple TV Remote — macOS Menu Bar Controller

Control your Apple TV from your Mac's menu bar. Full-featured remote with pairing, press-and-hold, and auto-discovery.

## Download

Download the latest DMG from [Releases](https://github.com/pedroscardua/mac-appletv-controler/releases).

## Features

- **Menu bar icon** — one click access, always available
- **Auto-discovery** — finds Apple TVs on your network automatically
- **Auto-connect** — connects automatically when only one Apple TV is found
- **Full D-pad** — up, down, left, right, select with press-and-hold support
- **Playback controls** — Play/Pause, Next, Previous
- **Volume control** — Volume up/down
- **Navigation** — Menu and Home buttons
- **Power** — Sleep/Wake
- **Secure pairing** — PIN-based pairing with credential persistence
- **Press-and-hold** — long press for continuous scrolling and hold actions

## Requirements

- macOS 14.0 (Sonoma) or later
- Python 3.9+ with `pyatv` (`pip3 install pyatv`)
- Apple TV on the same local network

## Build from Source

```bash
git clone https://github.com/pedroscardua/mac-appletv-controler.git
cd mac-appletv-controler

# Install Python dependency
pip3 install pyatv

# Build and run (debug)
make run

# Build release DMG
make dmg
```

## Development

```bash
make build        # Build debug binary
make app          # Create .app bundle (debug)
make run          # Launch app
make build-release # Build release binary
make app-release  # Create .app bundle (release)
make dmg          # Create unsigned DMG
make dmg-signed   # Create signed DMG (needs certificate)
make notarize     # Notarize DMG (needs Apple ID)
make clean        # Clean all artifacts
```

## App Store Submission

See [AppStore/](AppStore/) for metadata and instructions.

```bash
# Prerequisites: Apple Developer account ($99/year), Xcode installed
make app-store    # Create signed .pkg for App Store
```

Then upload via Transporter or `xcrun altool`.

## Architecture

```
┌─────────────────────────────┐
│  SwiftUI Menu Bar App       │
│  ├── NSStatusBar icon       │
│  ├── NSPopover remote UI    │
│  └── Process(stdin/stdout)  │
└──────────┬──────────────────┘
           │ JSON lines
┌──────────▼──────────────────┐
│  Python Bridge (bridge.py)  │
│  ├── pyatv scan + connect   │
│  ├── Companion protocol     │
│  └── FileStorage (creds)    │
└─────────────────────────────┘
```

## Credits

Built with:
- SwiftUI + AppKit for the native macOS UI
- [pyatv](https://github.com/postlund/pyatv) for Apple TV communication
- Companion protocol (tvOS 26+)
