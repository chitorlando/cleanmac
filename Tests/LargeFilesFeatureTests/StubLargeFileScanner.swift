import LargeFilesFeature

/// Emits a fixed list of scan events, optionally leaving the stream open.
struct StubLargeFileScanner: LargeFileScanning {
    let events: [LargeFileScanEvent]
    var finishes = true
    var criteria = LargeFileCriteria()

    func scan() -> AsyncStream<LargeFileScanEvent> {
        AsyncStream { continuation in
            events.forEach { continuation.yield($0) }
            if finishes { continuation.finish() }
        }
    }
}
