import CleanMacCore

/// Items found for one junk category.
public struct CategoryScanResult: Identifiable, Sendable {
    public let category: JunkCategory
    public let items: [CleanableItem]
    /// What the review shows about some items besides their file, such as the volume a Trash
    /// bin is on.
    public let details: [CleanableItem.ID: JunkItemDetail]
    /// Whether macOS kept the scan out of the category's folders until CleanMac has Full Disk
    /// Access, so what they hold is unknown rather than nothing.
    public let needsFullDiskAccess: Bool

    public var id: JunkCategory.ID { category.id }
    public var totalSize: Int64 { items.totalSize }

    public init(
        category: JunkCategory,
        items: [CleanableItem],
        details: [CleanableItem.ID: JunkItemDetail] = [:],
        needsFullDiskAccess: Bool = false
    ) {
        self.category = category
        self.items = items
        self.details = details
        self.needsFullDiskAccess = needsFullDiskAccess
    }

    /// A category whose folders macOS kept the scan out of, until CleanMac has Full Disk Access.
    public static func unreadable(_ category: JunkCategory) -> CategoryScanResult {
        CategoryScanResult(category: category, items: [], needsFullDiskAccess: true)
    }

    public func detail(of item: CleanableItem) -> JunkItemDetail? {
        details[item.id]
    }
}

/// What an item is, when its file doesn't tell the user.
public enum JunkItemDetail: Hashable, Sendable {
    /// One of the folders that make up the user's Trash.
    case trashBin(TrashBin)
}
