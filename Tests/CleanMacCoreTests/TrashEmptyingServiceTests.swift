import CleanMacCore
import Foundation
import Testing

struct TrashEmptyingServiceTests {
    /// Empties nothing, counts how often it was asked and fails when told to.
    private final class FakeEmptier: TrashEmptying, @unchecked Sendable {
        private let lock = NSLock()
        private var count = 0
        let error: (any Error)?

        init(error: (any Error)? = nil) {
            self.error = error
        }

        var emptyings: Int { lock.withLock { count } }

        func emptyTrash() async throws {
            lock.withLock { count += 1 }
            if let error { throw error }
        }
    }

    /// Records the commands it's asked to run, without running them.
    private actor RecordingRunner: CommandRunning {
        private(set) var invocations: [[String]] = []

        func run(_ executable: URL, arguments: [String]) async throws -> String {
            invocations.append([executable.path] + arguments)
            return ""
        }
    }

    private let homeBin = CleanableItem(url: URL(filePath: "/Users/ana/.Trash", directoryHint: .isDirectory), size: 300)
    private let diskBin = CleanableItem(url: URL(filePath: "/Volumes/Disk/.Trashes/501", directoryHint: .isDirectory), size: 50)

    @Test func emptiesTheTrashOnceForEveryBin() async {
        let emptier = FakeEmptier()

        let report = await TrashEmptyingService(emptier: emptier).empty([homeBin, diskBin])

        #expect(emptier.emptyings == 1)
        #expect(report.emptiedTrash)
        #expect(report.freedBytes == 350)
        #expect(report.removedCount == 0)
        #expect(report.failures.isEmpty)
    }

    @Test func emptiesNothingWithoutBins() async {
        let emptier = FakeEmptier()

        let report = await TrashEmptyingService(emptier: emptier).empty([])

        #expect(emptier.emptyings == 0)
        #expect(report == CleanupReport())
    }

    @Test func reportsEveryBinAsFailedWhenTheTrashCouldNotBeEmptied() async {
        let denied = CommandFailure(status: 1, message: "Not authorized to send Apple events to Finder. (-1743)")

        let report = await TrashEmptyingService(emptier: FakeEmptier(error: denied)).empty([homeBin, diskBin])

        #expect(!report.emptiedTrash)
        #expect(report.freedBytes == 0)
        #expect(report.failures.map(\.item) == [homeBin, diskBin])
        #expect(report.failures.allSatisfy { $0.kind == .finderAutomationDenied })
    }

    @Test func mergingAddsUpBothCleanups() async {
        var report = await TrashEmptyingService(emptier: FakeEmptier()).empty([homeBin])
        let moved = await CleanupService(remover: TrashItemRemoverStub()).clean([diskBin])

        report.merge(moved)

        #expect(report.emptiedTrash)
        #expect(report.freedBytes == 350)
        #expect(report.removedCount == 1)
    }

    /// Finder is asked to empty the Trash, and no file is named in the script.
    @Test func finderIsAskedToEmptyTheTrash() async throws {
        let runner = RecordingRunner()

        try await FinderTrashEmptier(runner: runner).emptyTrash()

        let invocations = await runner.invocations
        #expect(invocations.count == 1)
        let command = try #require(invocations.first)
        #expect(command.first == "/usr/bin/osascript")
        #expect(command.contains("tell application \"Finder\" to empty trash"))
        #expect(command.dropFirst().allSatisfy { !$0.hasPrefix("/") })
    }

    /// Removes nothing.
    private struct TrashItemRemoverStub: ItemRemoving {
        func remove(_ url: URL) async throws {}
    }
}
