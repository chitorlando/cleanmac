import Foundation

/// Finds large files and reports them while it runs.
public protocol LargeFileScanning: Sendable {
    /// Which files the scan reports.
    var criteria: LargeFileCriteria { get }

    /// The scope of a scan limited to the folder at `url`, or `nil` when the scan can't look
    /// there: `url` is not a folder, or the scan of the home folder would never enter it.
    func scope(limitedTo url: URL) -> LargeFileScanScope?

    /// Looks for large files in `scope`.
    func scan(_ scope: LargeFileScanScope) -> AsyncStream<LargeFileScanEvent>
}
