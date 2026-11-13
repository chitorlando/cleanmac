#!/usr/bin/env bash
# Checks CleanMac.app's signature and prints its designated requirement, which
# is what macOS remembers permissions by.
#
# Usage: verify-app-signature.sh <CleanMac.app> [certificate SHA-1]
#
# With a certificate hash, also checks that the requirement names CleanMac's
# bundle identifier and that certificate, so it stays the same across releases.
set -euo pipefail

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <CleanMac.app> [certificate SHA-1]" >&2
    exit 1
fi
APP="$1"
EXPECTED_CERTIFICATE="$(tr '[:upper:]' '[:lower:]' <<<"${2:-}")"
BUNDLE_ID="$(plutil -extract CFBundleIdentifier raw -o - "$APP/Contents/Info.plist")"

codesign --verify --deep --strict --verbose=2 "$APP"

REQUIREMENT="$(codesign -d -r - "$APP" 2>&1 | sed -n 's/^designated => //p')"
echo "Designated requirement: $REQUIREMENT"
codesign -d --verbose=2 "$APP" 2>&1 | grep -E '^(Identifier|Authority|TeamIdentifier|Signature)=' || true
echo "Sparkle.framework:"
codesign -d --verbose=2 "$APP/Contents/Frameworks/Sparkle.framework" 2>&1 \
    | grep -E '^(Authority|TeamIdentifier)=' || true

if [ -n "$EXPECTED_CERTIFICATE" ]; then
    expected="identifier \"$BUNDLE_ID\" and certificate leaf = H\"$EXPECTED_CERTIFICATE\""
    if [ "$REQUIREMENT" != "$expected" ]; then
        echo "The designated requirement isn't the stable one: $expected" >&2
        exit 1
    fi
    echo "Stable identity: the requirement names $BUNDLE_ID and the certificate."
fi
