#!/usr/bin/env bash
# Imports CleanMac's signing certificate into a keychain of its own and prints
# the identity to sign with: the certificate's SHA-1 hash.
#
# Usage: CODESIGN_P12_PASSWORD=<password> import-signing-certificate.sh <certificate.p12> <new.keychain-db>
#
# The keychain is left out of the user's search list, so it never affects
# other signing. Sign with it, then delete it:
#   SIGN_KEYCHAIN=<keychain> SIGN_IDENTITY=<hash> scripts/build-app.sh release
#   security delete-keychain <keychain>
set -euo pipefail
umask 077

OPENSSL=/usr/bin/openssl

if [ $# -ne 2 ]; then
    echo "Usage: CODESIGN_P12_PASSWORD=<password> $0 <certificate.p12> <new.keychain-db>" >&2
    exit 1
fi
P12="$1"
KEYCHAIN="$2"
if [ -z "${CODESIGN_P12_PASSWORD:-}" ]; then
    echo "CODESIGN_P12_PASSWORD is not set." >&2
    exit 1
fi
if [ -e "$KEYCHAIN" ]; then
    echo "$KEYCHAIN already exists." >&2
    exit 1
fi

# Creating a keychain can add it to the search list; put the list back as it was.
search_list=()
while IFS= read -r line; do
    search_list+=("$(sed -E 's/^[[:space:]]*"(.*)"$/\1/' <<<"$line")")
done < <(security list-keychains -d user)

KEYCHAIN_PASSWORD="$("$OPENSSL" rand -base64 24)"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security list-keychains -d user -s "${search_list[@]}"
security set-keychain-settings -lut 3600 "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security import "$P12" -k "$KEYCHAIN" -f pkcs12 -P "$CODESIGN_P12_PASSWORD" -T /usr/bin/codesign >/dev/null
# Lets codesign use the key without asking for the keychain's password.
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN" >/dev/null

"$OPENSSL" pkcs12 -in "$P12" -nokeys -passin env:CODESIGN_P12_PASSWORD 2>/dev/null \
    | "$OPENSSL" x509 -noout -fingerprint -sha1 \
    | cut -d= -f2 | tr -d ':'
