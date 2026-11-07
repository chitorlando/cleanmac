import CleanMacCore
import Dispatch
import Foundation
import Synchronization

/// Removes nothing and blocks every removal until `release()` is called, even if the task is cancelled.
final class BlockingRemover: ItemRemoving {
    private let gate = DispatchSemaphore(value: 0)
    private let isRemoving = Mutex(false)

    func remove(_ url: URL) throws {
        isRemoving.withLock { $0 = true }
        gate.wait()
    }

    /// Waits until a removal is in progress.
    func waitUntilRemoving() async {
        while !isRemoving.withLock({ $0 }) {
            try? await Task.sleep(for: .milliseconds(1))
        }
    }

    func release() {
        gate.signal()
    }
}
