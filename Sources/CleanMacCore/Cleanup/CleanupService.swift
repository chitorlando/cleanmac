import Foundation

/// Removes a batch of items once each, continuing past individual failures.
public struct CleanupService: Sendable {
    private let remover: any ItemRemoving
    private let skipsMissingItems: Bool

    /// - Parameter skipsMissingItems: Whether an item that is already gone is left out of the
    ///   report instead of failing. Features can list the same item, such as a browser cache
    ///   that both System Junk and Privacy find in `~/Library/Caches`: once one of them removes
    ///   it, cleaning it from the other must neither fail nor free its space again.
    public init(remover: any ItemRemoving = TrashItemRemover(), skipsMissingItems: Bool = false) {
        self.remover = remover
        self.skipsMissingItems = skipsMissingItems
    }

    @concurrent
    public func clean(_ items: [CleanableItem]) async -> CleanupReport {
        var report = CleanupReport()
        for item in items.uniquedByID() {
            guard !Task.isCancelled else { break }
            do {
                try await remover.remove(item.url)
                report.recordSuccess(item)
            } catch where skipsMissingItems && error.isNoSuchFile {
                continue
            } catch {
                report.recordFailure(item, error: error)
            }
        }
        return report
    }
}
