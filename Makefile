APP_NAME = AppleTVRemote
APP_DIR = $(APP_NAME).app
CONTENTS = $(APP_DIR)/Contents
MACOS_DIR = $(CONTENTS)/MacOS
RESOURCES_DIR = $(CONTENTS)/Resources
BUILD_DIR = .build
DMG_NAME = "Apple TV Remote"
DMG_FILE = "AppleTVRemote.dmg"
BUNDLE_ID = com.pedro.appletvremote
DEV_CERT = Apple Development: pedroscardua210@gmail.com (5C844FF8Y9)
DIST_CERT = Apple Distribution: pedroscardua210@gmail.com (5C844FF8Y9)

.PHONY: build build-release app app-release icon clean dmg dmg-signed notarize install run

# ── Development ──────────────────────────────────────────────

build:
	swift build

app: build icon
	@echo "==> Creating debug .app..."
	@rm -rf "$(APP_DIR)"
	@mkdir -p "$(MACOS_DIR)"
	@mkdir -p "$(RESOURCES_DIR)"
	@cp $(BUILD_DIR)/debug/$(APP_NAME) "$(MACOS_DIR)/"
	@cp Resources/Info.plist "$(CONTENTS)/"
	@cp Resources/AppleTVRemote.icns "$(RESOURCES_DIR)/"
	@cp Scripts/bridge.py "$(RESOURCES_DIR)/"
	@echo "   App: $(APP_DIR)"

run: app
	@open "$(APP_DIR)"

install: app
	@cp -r "$(APP_DIR)" /Applications/
	@echo "Installed to /Applications"

# ── Release ──────────────────────────────────────────────────

app-release: build-release icon
	@echo "==> Creating release .app..."
	@rm -rf "$(APP_DIR)"
	@mkdir -p "$(MACOS_DIR)"
	@mkdir -p "$(RESOURCES_DIR)"
	@cp $(BUILD_DIR)/release/$(APP_NAME) "$(MACOS_DIR)/"
	@cp Resources/Info.plist "$(CONTENTS)/"
	@cp Resources/AppleTVRemote.icns "$(RESOURCES_DIR)/"
	@cp Scripts/bridge.py "$(RESOURCES_DIR)/"
	@cp Resources/AppleTVRemote.entitlements "$(CONTENTS)/"
	@echo "   App: $(APP_DIR)"

build-release:
	swift build -c release

# ── Code Signing ─────────────────────────────────────────────

sign-dev: app-release
	@echo "==> Signing with Development certificate..."
	@codesign --force --deep --sign $(DEV_CERT) \
		--entitlements Resources/AppleTVRemote.entitlements \
		--options runtime \
		"$(APP_DIR)"
	@echo "   Signed with: $(DEV_CERT)"

sign-dist: app-release
	@echo "==> Signing with Distribution certificate..."
	@codesign --force --deep --sign $(DIST_CERT) \
		--entitlements Resources/AppleTVRemote.entitlements \
		--options runtime \
		"$(APP_DIR)"
	@echo "   Signed with: $(DIST_CERT)"

# ── DMG ──────────────────────────────────────────────────────

dmg: app-release
	@echo "==> Creating DMG..."
	@rm -f "$(DMG_FILE)"
	@hdiutil create -volname $(DMG_NAME) \
		-srcfolder "$(APP_DIR)" \
		-ov -format UDZO \
		"$(DMG_FILE)"
	@echo "   DMG: $(DMG_FILE)"

dmg-signed: sign-dev
	@echo "==> Creating signed DMG..."
	@rm -f "$(DMG_FILE)"
	@hdiutil create -volname $(DMG_NAME) \
		-srcfolder "$(APP_DIR)" \
		-ov -format UDZO \
		"$(DMG_FILE)"
	@codesign --force --sign $(DEV_CERT) "$(DMG_FILE)"
	@echo "   Signed DMG: $(DMG_FILE)"

# ── Notarization ─────────────────────────────────────────────

notarize: dmg-signed
	@echo "==> Submitting for notarization..."
	@xcrun notarytool submit "$(DMG_FILE)" \
		--apple-id "pedroscardua210@gmail.com" \
		--team-id "5C844FF8Y9" \
		--wait
	@echo "==> Stapling notarization ticket..."
	@xcrun stapler staple "$(DMG_FILE)"
	@echo "   Notarized: $(DMG_FILE)"

# ── App Store ────────────────────────────────────────────────

app-store: sign-dist
	@echo "==> Creating App Store package..."
	@productbuild --component "$(APP_DIR)" /Applications \
		--sign $(DIST_CERT) \
		"AppleTVRemote.pkg"
	@echo "   Package: AppleTVRemote.pkg"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Open https://appstoreconnect.apple.com"
	@echo "  2. Create New App → macOS → Bundle ID: $(BUNDLE_ID)"
	@echo "  3. Upload AppleTVRemote.pkg via Transporter or Xcode"
	@echo "  4. Fill in App Privacy details, screenshots, description"
	@echo "  5. Submit for Review"

# ── Utilities ────────────────────────────────────────────────

icon:
	@if [ ! -f Resources/AppleTVRemote.icns ]; then \
		echo "==> Generating icon..."; \
		python3 Scripts/generate_icon.py; \
	fi

clean:
	@rm -rf "$(APP_DIR)" "$(DMG_FILE)" AppleTVRemote.pkg
	@swift package clean

.PHONY: info
info:
	@echo "Available targets:"
	@echo "  make build        Debug build"
	@echo "  make app          Debug .app bundle"
	@echo "  make run          Launch debug app"
	@echo "  make app-release  Release .app bundle"
	@echo "  make sign-dev     Sign with Development cert"
	@echo "  make sign-dist    Sign with Distribution cert"
	@echo "  make dmg          Create unsigned DMG"
	@echo "  make dmg-signed   Create signed DMG"
	@echo "  make notarize     Notarize DMG (Apple ID required)"
	@echo "  make app-store    Create App Store package"
	@echo "  make clean        Clean all artifacts"
