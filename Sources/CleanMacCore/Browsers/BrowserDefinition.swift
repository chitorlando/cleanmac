/// A browser CleanMac knows, where it keeps its caches and which apps may be using them.
public struct BrowserDefinition: Identifiable, Hashable, Sendable {
    public let name: String
    public let bundleID: String
    /// Bundle identifiers of other editions that keep caches in this browser's folders, such
    /// as Firefox Nightly, whose profiles are next to those of Firefox.
    public let editionBundleIDs: [String]
    public let cacheLocations: [CacheLocation]

    public var id: String { bundleID }

    public init(name: String, bundleID: String, editionBundleIDs: [String] = [], cacheLocations: [CacheLocation]) {
        self.name = name
        self.bundleID = bundleID
        self.editionBundleIDs = editionBundleIDs
        self.cacheLocations = cacheLocations
    }
}

public extension BrowserDefinition {
    /// Whether an open app may be using this browser's caches: the browser itself or another
    /// edition of it.
    ///
    /// An edition is one listed in `editionBundleIDs`, or any app whose bundle identifier
    /// extends this browser's after a dot, such as "com.google.Chrome.canary": `cachesNamed`
    /// lists the cache folder named after it under this browser.
    func isEdition(_ app: RunningApp) -> Bool {
        guard let appID = app.bundleID else { return false }
        return ([bundleID] + editionBundleIDs).contains { appID.isNamed(afterBundleID: $0) }
    }
}
