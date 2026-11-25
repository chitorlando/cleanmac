import CleanMacCore
import Foundation

/// Finds large files and reports them while it runs.
public protocol LargeFileScanning: Sendable {
    /// The scope of a scan limited to the folder at `url`, or `nil` when the scan can't look
    /// there: `url` is not a folder, or the scan of the home folder would never enter it.
    func scope(limitedTo url: URL) -> ScanScope?

    /// Looks for the files in `scope` that match `criteria`.
    func scan(_ scope: ScanScope, criteria: LargeFileCriteria) -> AsyncStream<LargeFileScanEvent>
}
