import DiskMapFeature

/// Emits a fixed list of scan events, optionally leaving the stream open.
struct StubDiskMapScanner: DiskMapScanning {
    let events: [DiskMapScanEvent]
    var finishes = true

    func scan() -> AsyncStream<DiskMapScanEvent> {
        AsyncStream { continuation in
            events.forEach { continuation.yield($0) }
            if finishes { continuation.finish() }
        }
    }
}
