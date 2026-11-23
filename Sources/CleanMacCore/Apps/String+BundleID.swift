public extension String {
    /// Whether this name is the bundle identifier or extends it after a dot, ignoring case.
    ///
    /// "com.apple.Safari.SafeBrowsing" and "com.google.Chrome.canary" are named after
    /// "com.apple.Safari" and "com.google.Chrome"; "com.apple.SafariTechnologyPreview" is not.
    func isNamed(afterBundleID bundleID: String) -> Bool {
        let name = lowercased()
        let id = bundleID.lowercased()
        return name == id || name.hasPrefix(id + ".")
    }
}
