/// Finds large files and reports them while it runs.
public protocol LargeFileScanning: Sendable {
    /// Which files the scan reports.
    var criteria: LargeFileCriteria { get }

    func scan() -> AsyncStream<LargeFileScanEvent>
}
