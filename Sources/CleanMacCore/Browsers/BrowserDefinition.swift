/// A browser CleanMac knows, where it keeps its caches and which apps may be using them.
public struct BrowserDefinition: Identifiable, Hashable, Sendable {
    public let name: String
    public let bundleID: String
    /// Bundle identifiers of other editions that keep caches in this browser's folders, such
    /// as Firefox Nightly, whose profiles are next to those of Firefox.
    public let editionBundleIDs: [String]
    public let cacheLocations: [CacheLocation]
    /// Folders of the Library, relative to it, that the browser writes to besides its caches
    /// and that are named after its maker, such as "Caches/Mozilla", where Firefox keeps the
    /// updates it downloads. Other apps of the maker may use them too, so they're never
    /// cleaned as the browser's caches, but nothing in them is removed while it's open.
    public let sharedFolders: [String]

    public var id: String { bundleID }

    public init(
        name: String,
        bundleID: String,
        editionBundleIDs: [String] = [],
        cacheLocations: [CacheLocation],
        sharedFolders: [String] = []
    ) {
        self.name = name
        self.bundleID = bundleID
        self.editionBundleIDs = editionBundleIDs
        self.cacheLocations = cacheLocations
        self.sharedFolders = sharedFolders
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

extension BrowserDefinition {
    /// Whether an item of the Library, given by its path relative to it, holds, is or is inside
    /// a folder the browser may be using: one of its caches or of its shared folders.
    func mayUse(_ path: String) -> Bool {
        cacheLocations.contains { $0.overlaps(path) }
            || sharedFolders.contains { CacheLocation.overlap($0.lowercased(), path.lowercased()) }
    }
}
