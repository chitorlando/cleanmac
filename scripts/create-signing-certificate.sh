#!/usr/bin/env bash
# Creates CleanMac's self-signed code signing certificate. Run it once.
#
# Usage: create-signing-certificate.sh <output.p12>
#
# Releases signed with the same certificate keep the same designated
# requirement (the bundle identifier and the certificate's hash), so macOS
# keeps Full Disk Access and Automation grants across Sparkle updates.
# It isn't an Apple certificate: Gatekeeper still asks to "Open Anyway" once.
#
# Writes the certificate and its key, protected by a random password, to
# <output.p12>, and the password to <output.p12>.password. Nothing touches the
# Keychain and nothing secret is printed.
set -euo pipefail
umask 077

# macOS's LibreSSL: its .p12 files import with `security`, unlike the default
# encryption of OpenSSL 3 from Homebrew.
OPENSSL=/usr/bin/openssl
COMMON_NAME="CleanMac Self-Signed"
VALIDITY_DAYS=7300

if [ $# -ne 1 ]; then
    echo "Usage: $0 <output.p12>" >&2
    exit 1
fi
P12="$1"
PASSWORD_FILE="$P12.password"
if [ -e "$P12" ] || [ -e "$PASSWORD_FILE" ]; then
    echo "$P12 or its password file already exists. Keep the certificate you have:" >&2
    echo "a new one changes the app's identity and users would grant permissions again." >&2
    exit 1
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cleanmac-certificate.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

"$OPENSSL" req -x509 -newkey rsa:3072 -sha256 -nodes -days "$VALIDITY_DAYS" \
    -subj "/CN=$COMMON_NAME" \
    -addext "basicConstraints=critical,CA:FALSE" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" \
    -keyout "$WORK_DIR/key.pem" -out "$WORK_DIR/certificate.pem" 2>/dev/null

"$OPENSSL" rand -base64 32 | tr -d '\n' > "$PASSWORD_FILE"
"$OPENSSL" pkcs12 -export -name "$COMMON_NAME" \
    -inkey "$WORK_DIR/key.pem" -in "$WORK_DIR/certificate.pem" \
    -passout "file:$PASSWORD_FILE" -out "$P12"
chmod 600 "$P12" "$PASSWORD_FILE"

FINGERPRINT="$("$OPENSSL" x509 -in "$WORK_DIR/certificate.pem" -noout -fingerprint -sha1 | cut -d= -f2 | tr -d ':')"
EXPIRY="$("$OPENSSL" x509 -in "$WORK_DIR/certificate.pem" -noout -enddate | cut -d= -f2)"

cat <<NEXT
Created "$COMMON_NAME", valid until $EXPIRY.
  Certificate: $P12
  Password:    $PASSWORD_FILE
  SHA-1:       $FINGERPRINT (the "certificate leaf" hash in the app's designated requirement)

Next steps:
  1. Add both to the repository's secrets:
       base64 -i "$P12" | gh secret set CODESIGN_P12_BASE64 --repo chitorlando/cleanmac
       gh secret set CODESIGN_P12_PASSWORD --repo chitorlando/cleanmac < "$PASSWORD_FILE"
  2. Keep both files in an offline backup, such as an encrypted disk, and nowhere in
     the repository. If they're lost, the next release has a new identity and users
     have to grant CleanMac's permissions once more.
  3. Delete the local copies after the backup.
NEXT
