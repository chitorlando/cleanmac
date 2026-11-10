/// Small items of a folder counted together.
///
/// It remembers the item while there's only one, since a single small item
/// is clearer shown as itself than as “Other”.
struct SmallItemPile {
    private var total = OtherItems()
    private var onlyItem: DiskNode?

    var size: Int64 { total.size }
    var fileCount: Int { total.fileCount }

    /// The item, when it's the only one.
    var loneItem: DiskNode? { onlyItem }

    /// Everything counted together, when there are at least two items.
    var otherItems: OtherItems? { total.itemCount > 1 ? total : nil }

    mutating func add(_ node: DiskNode) {
        onlyItem = total.itemCount == 0 ? node : nil
        total.add(node)
    }
}
