/// Every browser whose caches CleanMac cleans. Supporting another one is one more entry.
public enum BrowserCatalog {
    public static let browsers: [BrowserDefinition] = [
        BrowserDefinition(
            name: "Safari",
            bundleID: "com.apple.Safari",
            cacheLocations: [.cachesNamed(bundleID: "com.apple.Safari")]
        ),
        BrowserDefinition(
            name: "Google Chrome",
            bundleID: "com.google.Chrome",
            cacheLocations: CacheLocation.chromium(bundleID: "com.google.Chrome", caches: "Google/Chrome", userData: "Google/Chrome")
        ),
        BrowserDefinition(
            name: "Microsoft Edge",
            bundleID: "com.microsoft.edgemac",
            cacheLocations: CacheLocation.chromium(bundleID: "com.microsoft.edgemac", caches: "Microsoft Edge", userData: "Microsoft Edge")
        ),
        BrowserDefinition(
            name: "Brave",
            bundleID: "com.brave.Browser",
            cacheLocations: CacheLocation.chromium(
                bundleID: "com.brave.Browser",
                caches: "BraveSoftware/Brave-Browser",
                userData: "BraveSoftware/Brave-Browser"
            )
        ),
        BrowserDefinition(
            name: "Arc",
            bundleID: "company.thebrowser.Browser",
            cacheLocations: CacheLocation.chromium(bundleID: "company.thebrowser.Browser", caches: "Arc", userData: "Arc/User Data")
        ),
        BrowserDefinition(
            name: "Vivaldi",
            bundleID: "com.vivaldi.Vivaldi",
            cacheLocations: CacheLocation.chromium(bundleID: "com.vivaldi.Vivaldi", caches: "Vivaldi", userData: "Vivaldi")
        ),
        BrowserDefinition(
            name: "Opera",
            bundleID: "com.operasoftware.Opera",
            cacheLocations: [
                .cachesNamed(bundleID: "com.operasoftware.Opera"),
                .profileFolders(
                    userData: "Application Support/com.operasoftware.Opera",
                    layout: .rootIsProfile,
                    cacheFolders: CacheLocation.chromiumCacheFolders
                )
            ]
        ),
        BrowserDefinition(
            name: "Firefox",
            bundleID: "org.mozilla.firefox",
            cacheLocations: [
                .cachesNamed(bundleID: "org.mozilla.firefox"),
                .profileFolders(userData: "Caches/Firefox/Profiles", layout: .anyFolder, cacheFolders: ["cache2", "startupCache"])
            ]
        )
    ]
}
