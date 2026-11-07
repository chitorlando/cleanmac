import CleanMacCore
import Foundation
import Synchronization

/// Removes nothing and remembers which URLs it was asked to remove.
final class RecordingRemover: ItemRemoving {
    private let removedURLs = Mutex<[URL]>([])

    var removed: [URL] { removedURLs.withLock { $0 } }

    func remove(_ url: URL) throws {
        removedURLs.withLock { $0.append(url) }
    }
}
