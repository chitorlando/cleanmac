#!/usr/bin/env bash
# Builds CleanMac.app from the Swift package and signs it for local use.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-release}"
APP_NAME="CleanMac"
APP_DIR="$ROOT/build/$APP_NAME.app"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

swift build --package-path "$ROOT" -c "$CONFIGURATION"
BIN_DIR="$(swift build --package-path "$ROOT" -c "$CONFIGURATION" --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$RESOURCES_DIR"
cp "$BIN_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT/Support/Info.plist" "$APP_DIR/Contents/Info.plist"

# Localized Info.plist values, one folder per language.
cp -R "$ROOT"/Support/*.lproj "$RESOURCES_DIR/"

# Resource bundles of each module (translations, assets).
find "$BIN_DIR" -maxdepth 1 -name "${APP_NAME}_*.bundle" -exec cp -R {} "$RESOURCES_DIR/" \;

# Ad-hoc signature: enough to run locally and to grant Full Disk Access.
codesign --force --sign - "$APP_DIR" >/dev/null
codesign --verify --strict "$APP_DIR"

echo "$APP_DIR"
