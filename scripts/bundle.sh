#!/bin/sh
# Builds a release DyaNotch.app (ad-hoc signed) and installs it to ~/Applications.
# Usage: scripts/bundle.sh [--no-install]
set -e
cd "$(dirname "$0")/.."
VERSION=0.1.0
APP=build/DyaNotch.app

swift build -c release --arch arm64
BIN=$(swift build -c release --arch arm64 --show-bin-path)/DyaNotch

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/DyaNotch"
strip -x "$APP/Contents/MacOS/DyaNotch"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key><string>io.dyanotch.app</string>
	<key>CFBundleName</key><string>DyaNotch</string>
	<key>CFBundleDisplayName</key><string>DyaNotch</string>
	<key>CFBundleExecutable</key><string>DyaNotch</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>$VERSION</string>
	<key>CFBundleVersion</key><string>1</string>
	<key>LSMinimumSystemVersion</key><string>14.0</string>
	<key>LSUIElement</key><true/>
	<key>NSHighResolutionCapable</key><true/>
	<key>NSAppleEventsUsageDescription</key><string>DyaNotch controls Spotify playback (play, pause, skip, seek) from the notch.</string>
</dict>
</plist>
PLIST

codesign --force --sign - --entitlements DyaNotch.entitlements --options runtime "$APP"
echo "Built $APP ($(du -sh "$APP" | cut -f1))"

if [ "$1" != "--no-install" ]; then
  mkdir -p ~/Applications
  pkill -x DyaNotch 2>/dev/null || true
  rm -rf ~/Applications/DyaNotch.app
  cp -R "$APP" ~/Applications/
  echo "Installed ~/Applications/DyaNotch.app"
fi
