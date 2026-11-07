import CleanMacCore
import Foundation

/// Removes nothing and holds every removal until `open()` is called, even if the task is cancelled.
final class GatedRemover: ItemRemoving {
    private let gate = Gate()

    func remove(_ url: URL) async throws {
        await gate.wait()
    }

    /// Waits until a removal is in progress.
    func waitUntilRemoving() async {
        while await !gate.hasWaiters {
            await Task.yield()
        }
    }

    func open() async {
        await gate.open()
    }
}

private actor Gate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    var hasWaiters: Bool { !waiters.isEmpty }

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters = []
    }
}
