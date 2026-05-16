.PHONY: build app run clean install

APP_NAME = AppleTVRemote
BUILD_DIR = .build/debug
APP_DIR = $(APP_NAME).app
CONTENTS = $(APP_DIR)/Contents
MACOS_DIR = $(CONTENTS)/MacOS
RESOURCES_DIR = $(CONTENTS)/Resources

build:
	swift build

app: build
	@echo "Creating $(APP_NAME).app..."
	@rm -rf "$(APP_DIR)"
	@mkdir -p "$(MACOS_DIR)"
	@mkdir -p "$(RESOURCES_DIR)"
	@cp $(BUILD_DIR)/AppleTVRemote "$(MACOS_DIR)/"
	@cp Resources/Info.plist "$(CONTENTS)/"
	@cp Scripts/bridge.py "$(RESOURCES_DIR)/"
	@echo "App bundle created: $(APP_DIR)"

run: app
	@echo "Launching Apple TV Remote..."
	@open "$(APP_DIR)"

clean:
	@rm -rf "$(APP_DIR)"
	@swift package clean

install: app
	@echo "Copying to /Applications..."
	@cp -r "$(APP_DIR)" /Applications/
	@echo "Installed. Open via Spotlight or Launchpad."
