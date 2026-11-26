import CleanMacCore
import Foundation

/// The cache folders found for one installed browser.
public struct BrowserCaches: Identifiable, Hashable, Sendable {
    public let browser: BrowserDefinition
    /// Where the browser is installed, for its icon.
    public let appURL: URL
    /// Largest first.
    public let items: [CleanableItem]
    /// The items that hold what websites stored, such as the files of their service workers.
    /// They're listed but never selected unless the user asks.
    public let siteDataIDs: Set<CleanableItem.ID>

    public var id: String { browser.id }
    public var name: String { browser.name }
    public var totalSize: Int64 { items.totalSize }

    /// The items selected after a scan: every cache that isn't site data.
    public var cacheItems: [CleanableItem] { items.filter { !holdsSiteData($0) } }

    /// - Parameters:
    ///   - items: The caches the browser can download or compute again.
    ///   - siteData: The folders that hold what websites stored.
    public init(browser: BrowserDefinition, appURL: URL, items: [CleanableItem], siteData: [CleanableItem] = []) {
        self.browser = browser
        self.appURL = appURL
        self.items = (items + siteData).sorted { $0.size > $1.size }
        self.siteDataIDs = Set(siteData.map(\.id))
    }

    public func holdsSiteData(_ item: CleanableItem) -> Bool {
        siteDataIDs.contains(item.id)
    }
}
