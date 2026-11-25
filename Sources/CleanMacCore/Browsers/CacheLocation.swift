/// Where a browser keeps a cache, relative to the user's Library.
///
/// Every case names cache folders explicitly, so nothing outside them can ever be offered:
/// history, cookies, passwords, sessions and other data are never listed.
public enum CacheLocation: Hashable, Sendable {
    /// A folder inside `~/Library/Caches`, such as "Google/Chrome". Everything in it is cache.
    case cachesFolder(String)
    /// Every item of `~/Library/Caches` named after a bundle identifier, such as
    /// "com.apple.Safari" and "com.apple.Safari.SafeBrowsing".
    case cachesNamed(bundleID: String)
    /// Named cache folders inside each profile of a user data folder, such as
    /// "Application Support/Google/Chrome" with "Default/Cache" and "Profile 1/Cache".
    case profileFolders(userData: String, layout: ProfileLayout, cacheFolders: [String])
    /// Named folders inside each profile that hold what websites stored there, not copies the
    /// browser can download again, such as "Service Worker/CacheStorage". They're listed but
    /// never selected unless the user asks.
    case profileSiteData(userData: String, layout: ProfileLayout, folders: [String])
}

public extension CacheLocation {
    /// Whether what is found here is selected after a scan. Site data never is.
    var isSelectedByDefault: Bool {
        if case .profileSiteData = self { return false }
        return true
    }
}

public extension CacheLocation {
    /// Cache folders every Chromium profile has. Anything else in a profile is user data.
    static let chromiumCacheFolders = ["Cache", "Code Cache", "GPUCache"]

    /// What the service workers of websites and web apps keep in a Chromium profile: the files
    /// they stored to work offline and their own scripts. Chromium counts them as site data,
    /// not as cache, and clearing them can make web apps start over.
    static let chromiumServiceWorkerFolders = ["Service Worker/CacheStorage", "Service Worker/ScriptCache"]

    /// The caches of a Chromium browser: its `~/Library/Caches` folders, the cache folders of
    /// each profile in `~/Library/Application Support` and what its service workers stored.
    static func chromium(
        bundleID: String,
        caches: String,
        userData: String,
        layout: ProfileLayout = .chromium
    ) -> [CacheLocation] {
        [
            .cachesFolder(caches),
            .cachesNamed(bundleID: bundleID),
            .profileFolders(userData: "Application Support/\(userData)", layout: layout, cacheFolders: chromiumCacheFolders),
            .profileSiteData(userData: "Application Support/\(userData)", layout: layout, folders: chromiumServiceWorkerFolders)
        ]
    }
}

extension CacheLocation {
    /// Words that name another edition of a browser after the browser's own folder, as in
    /// "Microsoft Edge Beta", "Vivaldi Snapshot" or "Brave-Browser-Nightly".
    private static let editionNames = ["beta", "canary", "dev", "nightly", "snapshot"]

    /// Whether an item of the Library, given by its path relative to it, holds, is or is inside
    /// a folder of this location. A folder of `~/Library/Caches` counts with the ones other
    /// editions of the browser keep next to it, which the catalog doesn't list. Case is ignored,
    /// as the file system does unless told otherwise.
    func overlaps(_ path: String) -> Bool {
        let path = path.lowercased()
        switch self {
        case .cachesFolder(let folder):
            return Self.withEditions("caches/\(folder.lowercased())").contains { Self.overlap($0, path) }
        case .cachesNamed(let bundleID):
            let components = path.split(separator: "/")
            guard components.first == "caches" else { return false }
            return components.count == 1 || String(components[1]).isNamed(afterBundleID: bundleID)
        case .profileFolders(let userData, _, _), .profileSiteData(let userData, _, _):
            return Self.overlap(userData.lowercased(), path)
        }
    }

    /// The folder and the ones other editions of the browser keep next to it: its name, a space
    /// or a hyphen and an edition, such as "Microsoft Edge Beta" next to "Microsoft Edge".
    /// Folders that only start with the same word, such as "Microsoft Teams", are not.
    private static func withEditions(_ folder: String) -> [String] {
        [folder] + editionNames.flatMap { edition in [" ", "-"].map { folder + $0 + edition } }
    }

    /// Whether the paths are the same or one is inside the other.
    static func overlap(_ one: String, _ other: String) -> Bool {
        one == other || one.hasPrefix(other + "/") || other.hasPrefix(one + "/")
    }
}
