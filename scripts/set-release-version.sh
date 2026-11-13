#!/usr/bin/env bash
# Run before compiling: Package.swift embeds this plist in the executable too.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${1:?Usage: set-release-version.sh vMAJOR.MINOR.PATCH BUILD_NUMBER}"
BUILD_NUMBER="${2:?A monotonically increasing build number is required}"

if [[ ! "$TAG" =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    echo "Expected a stable release tag such as v0.1.0, got: $TAG" >&2
    exit 1
fi
if [[ ! "$BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]]; then
    echo "Build number must be a positive integer." >&2
    exit 1
fi

plutil -replace CFBundleShortVersionString -string "${TAG#v}" "$ROOT/Support/Info.plist"
plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$ROOT/Support/Info.plist"
