import DuplicatesFeature

/// Emits a fixed list of scan events, optionally leaving the stream open.
struct StubDuplicateScanner: DuplicateScanning {
    let events: [DuplicateScanEvent]
    var finishes = true

    func scan() -> AsyncStream<DuplicateScanEvent> {
        AsyncStream { continuation in
            events.forEach { continuation.yield($0) }
            if finishes { continuation.finish() }
        }
    }
}
