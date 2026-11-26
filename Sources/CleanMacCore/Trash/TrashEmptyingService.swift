import Foundation

/// Empties the Trash as part of a cleanup and reports it like any other.
///
/// Unlike every other cleanup, it can't be undone: what the Trash holds is erased for good.
public struct TrashEmptyingService: Sendable {
    private let emptier: any TrashEmptying

    public init(emptier: any TrashEmptying = FinderTrashEmptier()) {
        self.emptier = emptier
    }

    /// Empties the Trash, which takes every bin of the user at once, and reports `bins`, the
    /// ones the user chose to empty, as freed, or as failed when it couldn't be emptied.
    /// Without bins, it empties nothing.
    public func empty(_ bins: [CleanableItem]) async -> CleanupReport {
        var report = CleanupReport()
        guard !bins.isEmpty, !Task.isCancelled else { return report }
        do {
            try await emptier.emptyTrash()
            report.recordEmptiedTrash(bins)
        } catch {
            for bin in bins {
                report.recordFailure(bin, error: error)
            }
        }
        return report
    }
}
