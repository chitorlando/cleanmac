import CleanMacCore
import Foundation

/// Gives fixed readings of the Trash, one per read, and notes whether each was taken on the
/// main thread.
final class FakeTrashReader: TrashUsageReading, @unchecked Sendable {
    private let usages: ReadingQueue<TrashUsage>
    private let lock = NSLock()
    private var readThreads: [Bool] = []

    init(_ usages: [TrashUsage]) {
        self.usages = ReadingQueue(usages)
    }

    /// How many times the Trash was read.
    var reads: Int {
        lock.lock()
        defer { lock.unlock() }
        return readThreads.count
    }

    /// How many of those reads were taken on the main thread.
    var readsOnMainThread: Int {
        lock.lock()
        defer { lock.unlock() }
        return readThreads.filter { $0 }.count
    }

    func read() -> TrashUsage {
        let isMainThread = Thread.isMainThread
        lock.lock()
        readThreads.append(isMainThread)
        lock.unlock()
        return usages.next() ?? .unreadable
    }
}

/// Empties nothing: notes each time it's asked to, and fails when told to.
final class FakeTrashEmptier: TrashEmptying, @unchecked Sendable {
    struct Failure: Error {}

    private let lock = NSLock()
    private let fails: Bool
    private var count = 0

    init(fails: Bool = false) {
        self.fails = fails
    }

    /// How many times it was asked to empty the Trash.
    var calls: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func emptyTrash() async throws {
        noteCall()
        if fails {
            throw Failure()
        }
    }

    private func noteCall() {
        lock.lock()
        defer { lock.unlock() }
        count += 1
    }
}

/// Trash readings the tests share.
enum MenuBarTrashFixtures {
    static let homeBin = URL(filePath: "/Users/test/.Trash", directoryHint: .isDirectory)
    static let full = TrashUsage.readable([
        TrashBinUsage(bin: TrashBin(url: homeBin), size: 3_000),
        TrashBinUsage(bin: TrashBin(url: URL(filePath: "/Volumes/Backup/.Trashes/501"), volumeName: "Backup"), size: 500)
    ])
    static let empty = TrashUsage.readable([])
}
