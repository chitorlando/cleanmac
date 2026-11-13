#!/usr/bin/env bash
# Packages an already-built app with an Applications shortcut; no Apple account.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/build/CleanMac.app"
DMG_PATH="$ROOT/build/CleanMac.dmg"

if [ ! -d "$APP_DIR" ]; then
    echo "Build the app first: ./scripts/build-app.sh release arm64 x86_64" >&2
    exit 1
fi
codesign --verify --deep --strict "$APP_DIR"

STAGING="$(mktemp -d "${TMPDIR:-/tmp}/cleanmac-dmg.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
ditto "$APP_DIR" "$STAGING/CleanMac.app"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname CleanMac -srcfolder "$STAGING" \
    -format UDZO -ov "$DMG_PATH"
hdiutil verify "$DMG_PATH"
echo "$DMG_PATH"
