import LargeFilesFeature

/// Emits the events a test sends it, when it sends them, so the test can look at the view
/// model in the middle of a scan. Good for a single scan.
final class ManualLargeFileScanner: LargeFileScanning {
    let criteria = LargeFileCriteria()

    private let stream: AsyncStream<LargeFileScanEvent>
    private let continuation: AsyncStream<LargeFileScanEvent>.Continuation

    init() {
        var continuation: AsyncStream<LargeFileScanEvent>.Continuation!
        stream = AsyncStream { continuation = $0 }
        self.continuation = continuation
    }

    func scan() -> AsyncStream<LargeFileScanEvent> { stream }

    func send(_ event: LargeFileScanEvent) {
        continuation.yield(event)
    }

    func finish() {
        continuation.finish()
    }
}
