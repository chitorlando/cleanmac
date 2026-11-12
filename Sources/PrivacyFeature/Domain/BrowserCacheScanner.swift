import CleanMacCore
import Foundation

/// Finds and measures the cache folders of every installed browser in a catalog.
///
/// Browsers that aren't installed, folders that don't exist and folders it can't read,
/// which measure zero, are left out without asking for any permission.
public struct BrowserCacheScanner: BrowserCacheScanning {
    private let browsers: [BrowserDefinition]
    private let resolver: CacheLocationResolver
    private let appLocator: any AppLocating
    private let reader: any DirectoryReading
    private let sizer: any SizeCalculating

    public init(
        browsers: [BrowserDefinition] = BrowserCatalog.browsers,
        library: URL,
        appLocator: any AppLocating,
        reader: any DirectoryReading,
        sizer: any SizeCalculating
    ) {
        self.browsers = browsers
        self.resolver = CacheLocationResolver(library: library, reader: reader)
        self.appLocator = appLocator
        self.reader = reader
        self.sizer = sizer
    }

    @concurrent
    public func scan() async -> [BrowserCaches] {
        browsers.compactMap { browser in
            guard !Task.isCancelled, let appURL = installedApp(of: browser) else { return nil }
            let items = resolver.folders(for: browser.cacheLocations)
                .map { CleanableItem(url: $0, size: sizer.size(of: $0)) }
                .filter { $0.size > 0 }
            return items.isEmpty ? nil : BrowserCaches(browser: browser, appURL: appURL, items: items)
        }
    }

    private func installedApp(of browser: BrowserDefinition) -> URL? {
        guard let url = appLocator.appURL(forBundleID: browser.bundleID), reader.itemExists(at: url) else { return nil }
        return url
    }
}
