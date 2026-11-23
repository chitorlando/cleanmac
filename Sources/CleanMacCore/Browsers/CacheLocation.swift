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
}

public extension CacheLocation {
    /// Cache folders every Chromium profile has. Anything else in a profile is user data.
    static let chromiumCacheFolders = [
        "Cache",
        "Code Cache",
        "GPUCache",
        "Service Worker/CacheStorage",
        "Service Worker/ScriptCache"
    ]

    /// The caches of a Chromium browser: its `~/Library/Caches` folders and the cache folders
    /// of each profile in `~/Library/Application Support`.
    static func chromium(
        bundleID: String,
        caches: String,
        userData: String,
        layout: ProfileLayout = .chromium
    ) -> [CacheLocation] {
        [
            .cachesFolder(caches),
            .cachesNamed(bundleID: bundleID),
            .profileFolders(userData: "Application Support/\(userData)", layout: layout, cacheFolders: chromiumCacheFolders)
        ]
    }
}
