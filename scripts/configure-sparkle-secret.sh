#!/usr/bin/env bash
# Uploads the existing CleanMac signing key to GitHub without printing it.
set -euo pipefail
umask 077

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/sparkle.sh
source "$ROOT/scripts/lib/sparkle.sh"
TOOLS="${SPARKLE_TOOLS_DIR:-$(sparkle_artifacts_dir "$ROOT")/bin}"
PUBLIC_KEY="$("$TOOLS/generate_keys" --account io.github.cleanmac -p)"
EXPECTED_KEY="$(plutil -extract SUPublicEDKey raw -o - "$ROOT/Support/Info.plist")"
if [ "$PUBLIC_KEY" != "$EXPECTED_KEY" ]; then
    echo "The Keychain key does not match CleanMac's public key. Do not replace it." >&2
    exit 1
fi

KEY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cleanmac-signing.XXXXXX")"
trap 'rm -rf "$KEY_DIR"' EXIT
"$TOOLS/generate_keys" --account io.github.cleanmac -x "$KEY_DIR/private-key" >/dev/null
gh secret set SPARKLE_PRIVATE_KEY --repo chitorlando/cleanmac < "$KEY_DIR/private-key"
echo "SPARKLE_PRIVATE_KEY configured for chitorlando/cleanmac."
