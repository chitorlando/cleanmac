#!/usr/bin/env bash
# Rehearses the release signing locally: builds build/CleanMac.app signed with
# a throwaway self-signed certificate, checks it, and deletes the certificate
# and its keychain. Nothing is published and the user's keychains are untouched.
#
# Usage: signing-dry-run.sh [architecture...]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cleanmac-signing-dry-run.XXXXXX")"
KEYCHAIN="$WORK_DIR/signing.keychain-db"
cleanup() {
    security delete-keychain "$KEYCHAIN" 2>/dev/null || true
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

"$ROOT/scripts/create-signing-certificate.sh" "$WORK_DIR/throwaway.p12" >/dev/null
IDENTITY="$(CODESIGN_P12_PASSWORD="$(cat "$WORK_DIR/throwaway.p12.password")" \
    "$ROOT/scripts/import-signing-certificate.sh" "$WORK_DIR/throwaway.p12" "$KEYCHAIN")"

SIGN_IDENTITY="$IDENTITY" SIGN_KEYCHAIN="$KEYCHAIN" "$ROOT/scripts/build-app.sh" release "$@" >/dev/null
"$ROOT/scripts/verify-app-signature.sh" "$ROOT/build/CleanMac.app" "$IDENTITY"
echo "Signed with a throwaway certificate, now deleted: $ROOT/build/CleanMac.app"
