/// Decides whether a Library file name belongs to an app, and how strongly.
public enum LeftoverMatcher {
    /// App names shorter than this are too generic to identify an app.
    static let minimumAppNameLength = 3

    /// The strongest rule that matches, or `nil` when the file does not belong to the app.
    /// Comparisons ignore case and a trailing ".plist", ".savedState" or ".binarycookies".
    public static func strength(
        of fileName: String,
        for app: AppBundleInfo,
        rules: [MatchRule]
    ) -> MatchStrength? {
        let name = LeftoverName(fileName).value
        let bundleID = app.bundleID.lowercased()
        return rules
            .filter { matches(name, bundleID: bundleID, app: app, rule: $0) }
            .map { MatchStrength(rule: $0, specificity: bundleID.count) }
            .max()
    }

    private static func matches(_ name: String, bundleID: String, app: AppBundleInfo, rule: MatchRule) -> Bool {
        switch rule {
        case .bundleID:
            name == bundleID
        case .bundleIDPrefix:
            name.hasPrefix(bundleID + ".")
        case .groupContainer:
            name.hasSuffix("." + bundleID)
        case .appName:
            appNames(of: app).contains(name)
        }
    }

    private static func appNames(of app: AppBundleInfo) -> Set<String> {
        Set(([app.name] + app.alternateNames)
            .filter { $0.count >= minimumAppNameLength }
            .map { $0.lowercased() })
    }
}
