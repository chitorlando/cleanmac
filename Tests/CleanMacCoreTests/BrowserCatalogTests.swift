import CleanMacCore
import Testing

struct BrowserCatalogTests {
    /// Folder names that hold history, cookies, passwords, sessions and other user data.
    private static let userData = [
        "History", "Cookies", "Login Data", "Web Data", "Local Storage", "IndexedDB",
        "Sessions", "Bookmarks", "Preferences", "places.sqlite", "cookies.sqlite", "logins.json"
    ]

    private static let cacheFolderNames: Set<String> = ["Cache", "Code Cache", "GPUCache", "cache2", "startupCache"]

    private static let serviceWorkerFolderNames: Set<String> = ["Service Worker/CacheStorage", "Service Worker/ScriptCache"]

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

    /// What service workers stored is site data: it's listed apart, so it's never selected by default.
    @Test func keepsServiceWorkerFoldersApartFromTheCaches() {
        for browser in BrowserCatalog.browsers {
            for case let .profileSiteData(_, _, folders) in browser.cacheLocations {
                #expect(Set(folders) == Self.serviceWorkerFolderNames, "\(browser.name)")
            }
        }
        let chromium = BrowserCatalog.browsers.filter { browser in
            browser.cacheLocations.contains { !$0.isSelectedByDefault }
        }
        #expect(chromium.map(\.name) == ["Google Chrome", "Microsoft Edge", "Brave", "Arc", "Vivaldi", "Opera"])
    }

    /// App containers are never touched, so the caches Safari keeps in its own are left out.
    @Test func staysOutOfAppContainers() {
        for browser in BrowserCatalog.browsers {
            for location in browser.cacheLocations {
                switch location {
                case .cachesFolder, .cachesNamed:
                    continue
                case .profileFolders(let userData, _, _), .profileSiteData(let userData, _, _):
                    let isOutside = userData.hasPrefix("Caches/") || userData.hasPrefix("Application Support/")
                    #expect(isOutside, "\(browser.name): \(userData)")
                }
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
