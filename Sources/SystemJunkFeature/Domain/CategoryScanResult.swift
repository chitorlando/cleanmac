import CleanMacCore

/// Items found for one junk category.
public struct CategoryScanResult: Identifiable, Sendable {
    public let category: JunkCategory
    public let items: [CleanableItem]
    /// Whether macOS kept the scan out of the category's folders until CleanMac has Full Disk
    /// Access, so what they hold is unknown rather than nothing.
    public let needsFullDiskAccess: Bool

    public var id: JunkCategory.ID { category.id }
    public var totalSize: Int64 { items.totalSize }

    public init(category: JunkCategory, items: [CleanableItem], needsFullDiskAccess: Bool = false) {
        self.category = category
        self.items = items
        self.needsFullDiskAccess = needsFullDiskAccess
    }

    /// A category whose folders macOS kept the scan out of, until CleanMac has Full Disk Access.
    public static func unreadable(_ category: JunkCategory) -> CategoryScanResult {
        CategoryScanResult(category: category, items: [], needsFullDiskAccess: true)
    }
}
