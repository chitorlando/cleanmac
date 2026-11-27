import CleanMacCore
@testable import CleanMacUI
import Foundation
import Testing

/// The checks hold in any language the tests run in.
struct CleanupReportSummaryTests {
    private struct Failure: Error {}

    /// Removes nothing and succeeds.
    private struct MovingRemover: ItemRemoving {
        func remove(_ url: URL) async throws {}
    }

    /// Fails to move anything.
    private struct FailingRemover: ItemRemoving {
        func remove(_ url: URL) async throws {
            throw Failure()
        }
    }

    /// Fails to empty the Trash.
    private struct FailingEmptier: TrashEmptying {
        func emptyTrash() async throws {
            throw Failure()
        }
    }

    private let bin = CleanableItem(url: URL(filePath: "/Users/test/.Trash", directoryHint: .isDirectory), size: 300)
    private let items = [
        CleanableItem(url: URL(filePath: "/Users/test/Library/Caches/one"), size: 10),
        CleanableItem(url: URL(filePath: "/Users/test/Library/Caches/two"), size: 20)
    ]

    @Test func countsTheItemsMovedToTheTrash() async {
        let report = await CleanupService(remover: MovingRemover()).clean(items)

        #expect(report.summary.contains("2"))
    }

    @Test func saysTheTrashCouldNotBeEmptiedInsteadOfCountingNothing() async {
        let failedEmptying = await TrashEmptyingService(emptier: FailingEmptier()).empty([bin])
        let nothingMoved = await CleanupService(remover: FailingRemover()).clean(items)

        #expect(!failedEmptying.summary.contains("0"))
        #expect(!nothingMoved.summary.contains("0"))
        #expect(failedEmptying.summary != nothingMoved.summary)
    }

    /// What moved to the Trash after it couldn't be emptied is what the user can still reclaim.
    @Test func countsWhatMovedEvenWhenTheTrashCouldNotBeEmptied() async {
        let moved = await CleanupService(remover: MovingRemover()).clean(items)
        var report = await TrashEmptyingService(emptier: FailingEmptier()).empty([bin])

        report.merge(moved)

        #expect(report.summary == moved.summary)
    }
}
