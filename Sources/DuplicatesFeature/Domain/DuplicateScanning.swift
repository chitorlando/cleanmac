/// Finds groups of identical files and reports them while it runs.
public protocol DuplicateScanning: Sendable {
    func scan() -> AsyncStream<DuplicateScanEvent>
}
