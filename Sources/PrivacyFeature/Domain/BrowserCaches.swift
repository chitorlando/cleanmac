import CleanMacCore
import Foundation

/// The cache folders found for one installed browser.
public struct BrowserCaches: Identifiable, Hashable, Sendable {
    public let browser: BrowserDefinition
    /// Where the browser is installed, for its icon.
    public let appURL: URL
    /// Largest first.
    public let items: [CleanableItem]

    public var id: String { browser.id }
    public var name: String { browser.name }
    public var totalSize: Int64 { items.totalSize }

    public init(browser: BrowserDefinition, appURL: URL, items: [CleanableItem]) {
        self.browser = browser
        self.appURL = appURL
        self.items = items.sorted { $0.size > $1.size }
    }
}
