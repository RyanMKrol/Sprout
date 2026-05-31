#!/usr/bin/env bash
#
# build_run.sh — generate, build, install, launch, and screenshot Sprout on the
# iOS simulator, entirely from the CLI (no Xcode GUI). This is the empirical
# "Verify" step: the loop runs it, then reads the saved screenshot to confirm the
# app behaves. (Mirrors the proven setup in the sibling Basket project.)
#
# Notes baked in from this machine's Xcode 26.5 / XcodeGen combo:
#   * The generated *scheme* reports an empty supported-platforms list, so the
#     usual `-scheme … -destination 'platform=iOS Simulator,…'` matches nothing
#     for a plain build. We therefore build by `-target` with an explicit
#     SUPPORTED_PLATFORMS + SYMROOT. (XCTest via `xcodebuild test` still uses the
#     scheme + destination form — see CLAUDE.md "Definition of done".)
#   * Needs a simulator runtime matching the SDK; if missing, run
#     `xcodebuild -downloadPlatform iOS`.
#
# Usage: ./build_run.sh [simulator-name]   (default: "iPhone 17 Pro")

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

APP_NAME="Sprout"
BUNDLE_ID="com.ryankrol.sprout"
SIM_NAME="${1:-iPhone 17 Pro}"
# Resolve the device name to a concrete UDID — prefer an already-booted one,
# else the last (newest-runtime) match.
SIM_ID="$(xcrun simctl list devices booted | grep -F "$SIM_NAME (" | grep -Eo '[0-9A-Fa-f-]{36}' | head -1)"
if [ -z "$SIM_ID" ]; then
  SIM_ID="$(xcrun simctl list devices available | grep -F "$SIM_NAME (" | grep -Eo '[0-9A-Fa-f-]{36}' | tail -1)"
fi
SIM="${SIM_ID:-$SIM_NAME}"
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/Debug-iphonesimulator/$APP_NAME.app"
SHOT_DIR="$PROJECT_DIR/screenshots"
SHOT_PATH="$SHOT_DIR/latest.png"

echo "▸ Generating Xcode project…"
xcodegen generate >/dev/null

echo "▸ Building $APP_NAME for the simulator…"
xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -target "$APP_NAME" \
  -sdk iphonesimulator \
  -configuration Debug \
  build \
  SUPPORTED_PLATFORMS="iphonesimulator" \
  SYMROOT="$BUILD_DIR" \
  | tail -3

echo "▸ Booting simulator '$SIM_NAME'…"
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl bootstatus "$SIM" >/dev/null 2>&1 || true
open -a Simulator || true

echo "▸ Installing + launching…"
xcrun simctl install "$SIM" "$APP_PATH"
# Pass any extra launch args through (e.g. -seedDemoData YES for populated screenshots).
xcrun simctl launch "$SIM" "$BUNDLE_ID" "${@:2}"

mkdir -p "$SHOT_DIR"
sleep 3
xcrun simctl io "$SIM" screenshot "$SHOT_PATH" >/dev/null
echo "▸ Screenshot → $SHOT_PATH"
