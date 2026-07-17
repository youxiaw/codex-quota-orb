#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

swift build -c release

APP_DIR="dist/Codex Quota Orb.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp ".build/release/CodexQuotaOrb" "$MACOS_DIR/Codex Quota Orb"
swift scripts/generate-icon.swift "dist/CodexQuotaOrb.icns"
cp "dist/CodexQuotaOrb.icns" "$RESOURCES_DIR/CodexQuotaOrb.icns"
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>Codex Quota Orb</string>
  <key>CFBundleIdentifier</key>
  <string>dev.local.codex-quota-orb</string>
  <key>CFBundleName</key>
  <string>Codex Quota Orb</string>
  <key>CFBundleIconFile</key>
  <string>CodexQuotaOrb</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST

echo "Created $APP_DIR"
