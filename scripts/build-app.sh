#!/usr/bin/env bash
# Builds CleanMac.app from the Swift package and signs it for local use.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-release}"
APP_NAME="CleanMac"
APP_DIR="$ROOT/build/$APP_NAME.app"

swift build --package-path "$ROOT" -c "$CONFIGURATION"
BIN_DIR="$(swift build --package-path "$ROOT" -c "$CONFIGURATION" --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT/Support/Info.plist" "$APP_DIR/Contents/Info.plist"

# Ad-hoc signature: enough to run locally and to grant Full Disk Access.
codesign --force --sign - "$APP_DIR" >/dev/null

echo "$APP_DIR"
