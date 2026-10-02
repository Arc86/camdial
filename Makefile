SWIFTC = swiftc
CACHE_DIR = /tmp/swift-cache
ARCH ?= $(shell uname -m)
MACOS_MIN_VER ?= 13.0
TARGET ?= $(ARCH)-apple-macos$(MACOS_MIN_VER)
SDKROOT ?= $(shell xcrun --show-sdk-path)
SWIFT_FLAGS = -O -module-cache-path $(CACHE_DIR) -target $(TARGET) -sdk $(SDKROOT)

VERSION = 0.1.0-beta.1
BUILD_DIR = build
APP_NAME = CamDial
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CLI_BINARY = $(BUILD_DIR)/camdial
DIST_ZIP = $(BUILD_DIR)/$(APP_NAME)-v$(VERSION).zip

COMMON_SRCS = \
	Sources/Common/Models.swift \
	Sources/Common/Presets.swift \
	Sources/UVC/UVCConstants.swift \
	Sources/UVC/UVCControl.swift \
	Sources/UVC/UVCInterface.swift \
	Sources/UVC/UVCDevice.swift \
	Sources/UVC/UVCDiscovery.swift

CLI_SRCS = \
	$(COMMON_SRCS) \
	Sources/CLI/main.swift

APP_SRCS = \
	$(COMMON_SRCS) \
	Sources/DeviceManager/CameraDevice.swift \
	Sources/DeviceManager/DeviceManager.swift \
	Sources/App/Views/CameraViewModel.swift \
	Sources/App/Views/CameraPreviewView.swift \
	Sources/App/Views/ControlSliderRow.swift \
	Sources/App/Views/PictureSettingsView.swift \
	Sources/App/Views/ExposureSettingsView.swift \
	Sources/App/Views/OpticsSettingsView.swift \
	Sources/App/Views/PresetsView.swift \
	Sources/App/Views/ContentView.swift \
	Sources/App/AppDelegate.swift \
	Sources/App/main.swift

.PHONY: all clean cli app dist help install-cli

all: cli app

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
	mkdir -p $(CACHE_DIR)

cli: $(BUILD_DIR)
	@echo "==> Compiling camdial (CLI)..."
	CLANG_MODULE_CACHE_PATH=$(CACHE_DIR) SWIFT_MODULE_CACHE_PATH=$(CACHE_DIR) \
	$(SWIFTC) $(SWIFT_FLAGS) \
		-framework Foundation -framework IOKit \
		$(CLI_SRCS) -o $(CLI_BINARY)
	@echo "==> CLI binary built at: $(CLI_BINARY)"

app: $(BUILD_DIR)
	@echo "==> Compiling $(APP_NAME).app (macOS GUI)..."
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp Info.plist $(APP_BUNDLE)/Contents/Info.plist
	CLANG_MODULE_CACHE_PATH=$(CACHE_DIR) SWIFT_MODULE_CACHE_PATH=$(CACHE_DIR) \
	$(SWIFTC) $(SWIFT_FLAGS) \
		-framework Cocoa -framework SwiftUI -framework AVFoundation -framework IOKit \
		$(APP_SRCS) -o $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@echo "==> App bundle built at: $(APP_BUNDLE)"

dist: all
	@echo "==> Packaging release archive $(DIST_ZIP)..."
	@cd $(BUILD_DIR) && zip -q -r -y $(APP_NAME)-v$(VERSION).zip $(APP_NAME).app camdial
	@echo "==> Distributable archive created at: $(DIST_ZIP)"

install-cli: cli
	@echo "==> Installing camdial to /usr/local/bin (may require sudo)..."
	install -m 755 $(CLI_BINARY) /usr/local/bin/camdial
	@echo "==> Installed camdial to /usr/local/bin/camdial"

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(CACHE_DIR)

help:
	@echo "CamDial Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all          Build both the CLI binary and the macOS App bundle (default)"
	@echo "  app          Build the macOS Menu Bar application (build/CamDial.app)"
	@echo "  cli          Build the command-line utility (build/camdial)"
	@echo "  dist         Build everything and create a release zip archive"
	@echo "  install-cli  Install camdial into /usr/local/bin"
	@echo "  clean        Remove build artifacts and temporary compiler caches"
	@echo "  help         Display this help message"
