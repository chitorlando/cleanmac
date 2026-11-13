# Locates Sparkle's binary artifact. Sourced by the scripts that need it; not run on its own.

# Prints the folder SwiftPM extracted Sparkle into: .build/artifacts/<package>/Sparkle.
# SwiftPM names <package> after the checkout's folder, "cleanmac" for a plain clone,
# so the folder is looked up instead of hardcoded. Resolves the package if needed.
sparkle_artifacts_dir() {
    local root="$1"
    local dir
    dir="$(find "$root/.build/artifacts" -mindepth 2 -maxdepth 2 -type d -name Sparkle 2>/dev/null | head -n 1)"
    if [ -z "$dir" ]; then
        swift package --package-path "$root" resolve >/dev/null
        dir="$(find "$root/.build/artifacts" -mindepth 2 -maxdepth 2 -type d -name Sparkle 2>/dev/null | head -n 1)"
    fi
    if [ -z "$dir" ]; then
        echo "Sparkle was not found in $root/.build/artifacts." >&2
        return 1
    fi
    printf '%s\n' "$dir"
}
