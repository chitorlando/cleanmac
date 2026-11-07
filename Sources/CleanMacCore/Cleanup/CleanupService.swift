import Foundation

/// Removes a batch of items, continuing past individual failures.
public struct CleanupService: Sendable {
    private let remover: any ItemRemoving

    public init(remover: any ItemRemoving = TrashItemRemover()) {
        self.remover = remover
    }

    @concurrent
    public func clean(_ items: [CleanableItem]) async -> CleanupReport {
        var report = CleanupReport()
        for item in items {
            guard !Task.isCancelled else { break }
            do {
                try await remover.remove(item.url)
                report.recordSuccess(item)
            } catch {
                report.recordFailure(item, error: error)
            }
        }
        return report
    }
}
