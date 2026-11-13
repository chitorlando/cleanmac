#!/usr/bin/env bash
# Builds CleanMac.app from the Swift package and signs it for local use.
#
# Usage: build-app.sh [configuration] [architecture...]
#
# SIGN_IDENTITY picks the signing certificate, by name or SHA-1 hash. Without
# it the app is signed ad hoc, which is all a local build needs. Releases use
# CleanMac's self-signed certificate (see create-signing-certificate.sh).
# SIGN_KEYCHAIN limits the search for that identity to one keychain file.
#
# Without architectures the app is built for this Mac only, which is the
# fastest. Naming them builds one app for all of them: "release arm64 x86_64"
# gives a universal app that also runs on Intel Macs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-release}"
APP_NAME="CleanMac"
APP_DIR="$ROOT/build/$APP_NAME.app"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

BUILD_ARGS=(--package-path "$ROOT" -c "$CONFIGURATION")
for architecture in "${@:2}"; do
    BUILD_ARGS+=(--arch "$architecture")
done

swift build "${BUILD_ARGS[@]}"
# Where the products land depends on the build system and on the
# architectures, so ask for it with the same arguments as the build.
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$RESOURCES_DIR"
cp "$BIN_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT/Support/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT/Support/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

# Localized Info.plist values, one folder per language.
cp -R "$ROOT"/Support/*.lproj "$RESOURCES_DIR/"

# Resource bundles of each module (translations, assets). They hold no code,
# so they are the same whatever the architectures.
find "$BIN_DIR" -maxdepth 1 -name "${APP_NAME}_*.bundle" -exec cp -R {} "$RESOURCES_DIR/" \;

# SwiftPM links binary dependencies but does not embed them in our hand-built
# app. ditto preserves Sparkle's versioned symlinks, helpers and vendor signatures.
SPARKLE_FRAMEWORK="$ROOT/.build/artifacts/cleanmac/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"
if [ ! -d "$SPARKLE_FRAMEWORK" ]; then
    echo "Sparkle.framework was not found at $SPARKLE_FRAMEWORK" >&2
    exit 1
fi
mkdir -p "$APP_DIR/Contents/Frameworks"
ditto "$SPARKLE_FRAMEWORK" "$APP_DIR/Contents/Frameworks/Sparkle.framework"
cp "$ROOT/.build/artifacts/cleanmac/Sparkle/LICENSE" "$RESOURCES_DIR/Sparkle-LICENSE.txt"

# Ad hoc by default: enough to run locally and to grant Full Disk Access, but
# each build gets a new identity. A certificate's identity, the bundle
# identifier plus the certificate's hash, stays the same across builds, so
# macOS keeps the permissions it granted. Free either way: no Apple account,
# Developer ID or notarization. Do not enable hardened runtime library
# validation: the embedded framework keeps Sparkle's own signature.
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
SIGN_ARGS=(--force --sign "$SIGN_IDENTITY")
if [ "$SIGN_IDENTITY" != "-" ]; then
    # Apple's timestamp service has nothing to add to a self-signed certificate.
    SIGN_ARGS+=(--timestamp=none)
fi
if [ -n "${SIGN_KEYCHAIN:-}" ]; then
    SIGN_ARGS+=(--keychain "$SIGN_KEYCHAIN")
fi
codesign "${SIGN_ARGS[@]}" "$APP_DIR" >/dev/null
codesign --verify --deep --strict "$APP_DIR"

echo "$APP_DIR"
