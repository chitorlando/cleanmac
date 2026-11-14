#!/usr/bin/env bash
# Packages the final DMG and localized notes, then signs it with Sparkle.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${1:?Usage: build-appcast.sh vMAJOR.MINOR.PATCH}"
# shellcheck source=lib/sparkle.sh
source "$ROOT/scripts/lib/sparkle.sh"
TOOLS="${SPARKLE_TOOLS_DIR:-$(sparkle_artifacts_dir "$ROOT")/bin}"
OUTPUT="$ROOT/build/release"
PLIST="$ROOT/build/CleanMac.app/Contents/Info.plist"
VERSION="$(plutil -extract CFBundleShortVersionString raw -o - "$PLIST")"
if [ "$TAG" != "v$VERSION" ]; then
    echo "Tag $TAG does not match the built app's version $VERSION." >&2
    exit 1
fi
if [ -e "$OUTPUT" ]; then
    echo "$OUTPUT already exists. Move it aside before generating a new release." >&2
    exit 1
fi

mkdir -p "$OUTPUT"
cp "$ROOT/build/CleanMac.dmg" "$OUTPUT/CleanMac.dmg"
cp "$ROOT/releases/$TAG.en.html" "$OUTPUT/CleanMac.html"
cp "$ROOT/releases/$TAG.es.html" "$OUTPUT/CleanMac.es.html"
DOWNLOAD_URL="https://github.com/chitorlando/cleanmac/releases/download/$TAG/"
ARGS=(--download-url-prefix "$DOWNLOAD_URL" --release-notes-url-prefix "$DOWNLOAD_URL"
      --link "https://github.com/chitorlando/cleanmac" --maximum-deltas 0)

if [ -n "${SPARKLE_PRIVATE_KEY:-}" ]; then
    # Standard input keeps the secret out of process arguments and log output.
    printf '%s' "$SPARKLE_PRIVATE_KEY" | "$TOOLS/generate_appcast" \
        --ed-key-file - "${ARGS[@]}" "$OUTPUT"
else
    "$TOOLS/generate_appcast" --account io.github.cleanmac "${ARGS[@]}" "$OUTPUT"
fi

# Verify against the public key actually shipped in the app, not just the
# signing key supplied by CI. A mismatched secret must never reach a release.
swift "$ROOT/scripts/verify-update.swift" "$PLIST" "$OUTPUT" "$TAG"
(cd "$OUTPUT" && shasum -a 256 CleanMac.dmg > SHA256SUMS.txt)
