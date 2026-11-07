import Foundation

/// Moves items to the Trash so every cleanup can be undone.
public struct TrashItemRemover: ItemRemoving {
    public init() {}

    @concurrent
    public func remove(_ url: URL) async throws {
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }
}
