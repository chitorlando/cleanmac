import CleanMacCore
import Foundation
import Synchronization

/// Removes nothing and remembers which URLs it was asked to remove, failing for the ones given.
final class RecordingRemover: ItemRemoving {
    private struct Failure: Error {}

    private let failing: Set<URL>
    private let removedURLs = Mutex<[URL]>([])

    init(failing: Set<URL> = []) {
        self.failing = failing
    }

    var removed: [URL] { removedURLs.withLock { $0 } }

    func remove(_ url: URL) throws {
        removedURLs.withLock { $0.append(url) }
        if failing.contains(url) { throw Failure() }
    }
}
