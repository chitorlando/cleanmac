#!/usr/bin/env bash
# Updates every module's String Catalog with the strings used in its code.
#
# New strings are added and strings no longer used are marked as stale,
# the same way Xcode does when it builds. Translations are kept.
set -euo pipefail
shopt -s nullglob

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INTERMEDIATES="$ROOT/.build/out/Intermediates.noindex"

# Building emits one .stringsdata file per Swift source file.
swift build --package-path "$ROOT" >/dev/null

catalogs=("$ROOT"/Sources/*/Resources/Localizable.xcstrings)
if [ ${#catalogs[@]} -eq 0 ]; then
    echo "No string catalogs found."
    exit 0
fi

stringsdata_files=()
if [ -d "$INTERMEDIATES" ]; then
    while IFS= read -r -d '' file; do
        stringsdata_files+=("$file")
    done < <(find "$INTERMEDIATES" -path "*/Debug/*" -name "*.stringsdata" -print0)
fi

if [ ${#stringsdata_files[@]} -eq 0 ]; then
    echo "No strings data found in $INTERMEDIATES." >&2
    echo "make strings needs Swift 6.4 or later (Xcode 27), whose build system emits it." >&2
    exit 1
fi

for catalog in "${catalogs[@]}"; do
    target="$(basename "$(dirname "$(dirname "$catalog")")")"
    args=()
    for file in "${stringsdata_files[@]}"; do
        source="$(plutil -extract source raw -o - "$file" 2>/dev/null || true)"
        case "$source" in
            */Sources/"$target"/*) args+=(--stringsdata "$file") ;;
        esac
    done

    if [ ${#args[@]} -eq 0 ]; then
        echo "No strings found for $target." >&2
        exit 1
    fi

    xcrun xcstringstool sync "$catalog" "${args[@]}"
    # xcstringstool drops the final newline when it rewrites a catalog. Command
    # substitution strips every trailing newline, so exactly one is written back.
    content="$(cat "$catalog")"
    printf '%s\n' "$content" > "$catalog"
    echo "Synced $target"
done
