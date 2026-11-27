@testable import CleanMacCore
import Foundation
import Testing

struct CleanupReportSoundEffectTests {
    private struct Failure: Error {}

    private let bin = CleanableItem(url: URL(filePath: "/Users/test/.Trash", directoryHint: .isDirectory), size: 300)
    private let item = CleanableItem(url: URL(filePath: "/Users/test/Library/Caches/one"), size: 10)

    @Test func soundsLikeFinderMovingItemsToTheTrash() {
        var report = CleanupReport()
        report.recordSuccess(item)

        #expect(report.soundEffect == .cleanupFinished)
    }

    @Test func soundsLikeFinderEmptyingTheTrash() {
        var report = CleanupReport()
        report.recordEmptiedTrash([bin])

        #expect(report.soundEffect == .trashEmptied)
    }

    /// Erasing the Trash for good is what the user hears, also when items went to it afterwards.
    @Test func soundsLikeEmptyingTheTrashWhenItAlsoMovedItems() {
        var report = CleanupReport()
        report.recordEmptiedTrash([bin])
        report.recordSuccess(item)

        #expect(report.soundEffect == .trashEmptied)
    }

    /// Some failures don't change the sound of what did go to the Trash.
    @Test func soundsLikeWhatWentWellWhenSomethingFailed() {
        var report = CleanupReport()
        report.recordSuccess(item)
        report.recordFailure(item, error: Failure())

        #expect(report.soundEffect == .cleanupFinished)
    }

    @Test func staysQuietWhenEverythingFailed() {
        var movedNothing = CleanupReport()
        movedNothing.recordFailure(item, error: Failure())
        var emptiedNothing = CleanupReport()
        emptiedNothing.recordTrashNotEmptied([bin], error: Failure())

        #expect(movedNothing.soundEffect == nil)
        #expect(emptiedNothing.soundEffect == nil)
        #expect(CleanupReport().soundEffect == nil)
    }
}
