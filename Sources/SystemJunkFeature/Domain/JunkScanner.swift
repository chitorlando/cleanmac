import CleanMacCore

/// Finds the removable items that belong to one junk category.
public protocol JunkScanner: Sendable {
    var category: JunkCategory { get }
    func scan() async -> [CleanableItem]
}
