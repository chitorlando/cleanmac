import CleanMacCore
import Foundation

/// Visits records until told to stop, then signals that the walk ended.
struct EndlessWalker: FileWalking {
    let finished: AsyncStream<Void>
    private let finishedContinuation: AsyncStream<Void>.Continuation

    init() {
        (finished, finishedContinuation) = AsyncStream.makeStream()
    }

    func walk(_ root: URL, visit: (FileRecord) -> Bool) {
        let record = FileRecord(url: root.appending(path: "file.bin"), size: 1, accessDate: nil, modificationDate: nil)
        while visit(record) {}
        finishedContinuation.yield()
        finishedContinuation.finish()
    }
}
