/// Finds large files and reports them while it runs.
public protocol LargeFileScanning: Sendable {
    func scan() -> AsyncStream<LargeFileScanEvent>
}
