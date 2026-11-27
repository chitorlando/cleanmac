import CleanMacCore
import CleanMacUI
import Foundation
import Testing

struct CleanupReportCelebrationTests {
    private struct Failure: Error {}

    /// Removes nothing and succeeds.
    private struct MovingRemover: ItemRemoving {
        func remove(_ url: URL) async throws {}
    }

    /// Fails to move the items whose name starts with "locked".
    private struct PickyRemover: ItemRemoving {
        func remove(_ url: URL) async throws {
            if url.lastPathComponent.hasPrefix("locked") {
                throw Failure()
            }
        }
    }

    /// Empties the Trash.
    private struct WorkingEmptier: TrashEmptying {
        func emptyTrash() async throws {}
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
    private let locked = CleanableItem(url: URL(filePath: "/Users/test/Library/Caches/locked"), size: 30)

    @Test func movingEverythingIsCelebrated() async {
        let report = await CleanupService(remover: MovingRemover()).clean(items)

        #expect(report.isCompleteSuccess)
    }

    @Test func emptyingTheTrashIsCelebrated() async {
        let report = await TrashEmptyingService(emptier: WorkingEmptier()).empty([bin])

        #expect(report.isCompleteSuccess)
    }

    @Test func leavingAnItemBehindIsNotCelebrated() async {
        let report = await CleanupService(remover: PickyRemover()).clean(items + [locked])

        #expect(report.removedCount == 2)
        #expect(!report.isCompleteSuccess)
    }

    @Test func aTrashThatCouldNotBeEmptiedIsNotCelebrated() async {
        let moved = await CleanupService(remover: MovingRemover()).clean(items)
        var report = await TrashEmptyingService(emptier: FailingEmptier()).empty([bin])

        report.merge(moved)

        #expect(!report.isCompleteSuccess)
    }

    @Test func doingNothingIsNotCelebrated() async {
        let report = await CleanupService(remover: MovingRemover()).clean([])

        #expect(!report.isCompleteSuccess)
    }
}
