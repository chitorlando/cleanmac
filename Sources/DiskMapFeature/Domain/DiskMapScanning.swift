/// Measures a folder and reports the map of its contents.
public protocol DiskMapScanning: Sendable {
    func scan() -> AsyncStream<DiskMapScanEvent>
}
