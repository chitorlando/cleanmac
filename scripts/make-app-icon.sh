#!/usr/bin/env bash
# Renders the app icon and packs it into Support/AppIcon.icns.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

MASTER="$WORK_DIR/AppIcon-1024.png"
ICONSET="$WORK_DIR/AppIcon.iconset"

swift "$ROOT/scripts/render-app-icon.swift" "$MASTER"

mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$MASTER" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" "$MASTER" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil --convert icns "$ICONSET" --output "$ROOT/Support/AppIcon.icns"
echo "$ROOT/Support/AppIcon.icns"
