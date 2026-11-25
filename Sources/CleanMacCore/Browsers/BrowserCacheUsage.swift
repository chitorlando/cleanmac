import Foundation

/// Tells which open apps may be using an item of a user's Library, because it holds, is or
/// is inside a cache folder or a shared folder of their browser, so nothing is removed under
/// them.
///
/// `~/Library/Caches/Google` counts for Chrome as much as `Google/Chrome` inside it does, and
/// `~/Library/Caches/Mozilla`, where Firefox keeps its updates, counts for Firefox.
public struct BrowserCacheUsage: Sendable {
    private let libraryPath: String
    private let browsers: [BrowserDefinition]

    public init(library: URL, browsers: [BrowserDefinition] = BrowserCatalog.browsers) {
        libraryPath = library.resolvingSymlinksInPath().path
        self.browsers = browsers
    }

    /// The apps among `openApps` that may be using the item: every open edition of a browser
    /// that keeps caches or a shared folder there. Empty for an item no browser uses or outside
    /// the Library.
    public func apps(using item: URL, among openApps: [RunningApp]) -> [RunningApp] {
        guard let path = pathInLibrary(of: item) else { return [] }
        let owners = browsers.filter { $0.mayUse(path) }
        return openApps.filter { app in owners.contains { $0.isEdition(app) } }
    }

    /// The item's path relative to the Library. The folder that holds the item is resolved,
    /// since folder listings can spell it another way, but not the item: a link that takes a
    /// cache to another disk is still that cache.
    private func pathInLibrary(of item: URL) -> String? {
        let folder = item.deletingLastPathComponent().resolvingSymlinksInPath().path
        let path = folder + "/" + item.lastPathComponent
        guard path.hasPrefix(libraryPath + "/") else { return nil }
        return String(path.dropFirst(libraryPath.count + 1))
    }
}
