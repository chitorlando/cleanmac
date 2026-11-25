/// One task for any number of callers at once: it starts with the first of them and is
/// cancelled once the last one's task is.
@MainActor
final class SharedTask {
    private let operation: @MainActor () async -> Void
    private var task: Task<Void, Never>?
    private var callers = 0

    /// - Parameter operation: Work that goes on until its task is cancelled.
    init(_ operation: @escaping @MainActor () async -> Void) {
        self.operation = operation
    }

    /// Keeps the shared task going until the calling task is cancelled, starting it if it
    /// isn't going yet. The last caller to leave returns once the shared task has stopped.
    func join() async {
        callers += 1
        if task == nil {
            task = Task { await self.operation() }
        }
        await Self.waitForCancellation()
        callers -= 1
        guard callers == 0, let task else { return }
        self.task = nil
        task.cancel()
        await task.value
    }

    /// Returns once the calling task is cancelled.
    private static func waitForCancellation() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(3_600))
        }
    }
}
