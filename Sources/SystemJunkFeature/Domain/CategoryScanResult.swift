import CleanMacCore

/// Items found for one junk category.
public struct CategoryScanResult: Identifiable, Sendable {
    public let category: JunkCategory
    public let items: [CleanableItem]

    public var id: JunkCategory.ID { category.id }
    public var totalSize: Int64 { items.totalSize }

    public init(category: JunkCategory, items: [CleanableItem]) {
        self.category = category
        self.items = items
    }
}
