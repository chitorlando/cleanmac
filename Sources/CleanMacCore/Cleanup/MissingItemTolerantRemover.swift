import Foundation

/// Removes items with another strategy and takes an item that is already gone as removed.
///
/// Features can list the same item, such as a browser cache that both System Junk and
/// Privacy find in `~/Library/Caches`. Once one of them removes it, cleaning it from the
/// other must not report a failure.
public struct MissingItemTolerantRemover: ItemRemoving {
    private let remover: any ItemRemoving

    public init(_ remover: any ItemRemoving) {
        self.remover = remover
    }

    public func remove(_ url: URL) async throws {
        do {
            try await remover.remove(url)
        } catch where error.isNoSuchFile {
            return
        }
    }
}
