#!/bin/bash

# Exit immediately if any command fails
set -e

APP_NAME="MorningClaude"
BUNDLE_ID="com.rebornjoe.morningclaude"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
INFO_PLIST="${CONTENTS_DIR}/Info.plist"
BUILD_BIN=".build/release/${APP_NAME}"

echo "🚀 Compiling ${APP_NAME} (Release configuration)..."
swift build -c release

echo "📦 Assembling the macOS .app bundle..."
# Remove any leftover bundle from previous local builds
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "📄 Copying executable..."
cp "${BUILD_BIN}" "${MACOS_DIR}/"

echo "🖼️ Checking for application icon..."
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "${RESOURCES_DIR}/"
    echo "   -> AppIcon.icns found and copied."
else
    echo "   -> No AppIcon.icns found. Skipping icon packaging."
fi

echo "📝 Generating Info.plist..."
cat > "${INFO_PLIST}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>

    <key>NSAppleEventsUsageDescription</key>
    <string>MorningClaude needs to control the Terminal to launch Claude Code automatically.</string>
</dict>
</plist>
EOF

echo "🚚 Installing to /Applications..."
# Remove the old version if it's currently installed, to prevent overwrite errors
if [ -d "/Applications/${APP_DIR}" ]; then
    echo "   -> Removing older version from /Applications..."
    rm -rf "/Applications/${APP_DIR}"
fi

mv "${APP_DIR}" /Applications/

echo "✅ Success! ${APP_NAME} is now installed."
echo "   You can launch it from your Applications folder or via Spotlight."