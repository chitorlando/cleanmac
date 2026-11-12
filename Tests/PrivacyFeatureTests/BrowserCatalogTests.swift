import PrivacyFeature
import Testing

struct BrowserCatalogTests {
    /// Folder names that hold history, cookies, passwords, sessions and other user data.
    private static let userData = [
        "History", "Cookies", "Login Data", "Web Data", "Local Storage", "IndexedDB",
        "Sessions", "Bookmarks", "Preferences", "places.sqlite", "cookies.sqlite", "logins.json"
    ]

    private static let cacheFolderNames: Set<String> = [
        "Cache", "Code Cache", "GPUCache", "Service Worker/CacheStorage", "Service Worker/ScriptCache",
        "cache2", "startupCache"
    ]

    @Test func knowsTheSupportedBrowsers() {
        #expect(BrowserCatalog.browsers.map(\.name) == [
            "Safari", "Google Chrome", "Microsoft Edge", "Brave", "Arc", "Vivaldi", "Opera", "Firefox"
        ])
    }

    @Test func identifiesEveryBrowserOnce() {
        let ids = BrowserCatalog.browsers.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    /// Profile folders hold user data, so only these known cache folders may be taken from them.
    @Test func takesOnlyKnownCacheFoldersFromProfiles() {
        for browser in BrowserCatalog.browsers {
            for case let .profileFolders(_, _, cacheFolders) in browser.cacheLocations {
                #expect(Set(cacheFolders).isSubset(of: Self.cacheFolderNames), "\(browser.name)")
                #expect(cacheFolders.allSatisfy { folder in !Self.userData.contains { folder.contains($0) } })
            }
        }
    }

    /// Whole folders are only ever taken from `~/Library/Caches`.
    @Test func takesWholeFoldersOnlyFromTheCaches() {
        for browser in BrowserCatalog.browsers {
            for case let .profileFolders(userData, layout, _) in browser.cacheLocations where layout == .anyFolder {
                #expect(userData.hasPrefix("Caches/"), "\(browser.name)")
            }
        }
    }
}
