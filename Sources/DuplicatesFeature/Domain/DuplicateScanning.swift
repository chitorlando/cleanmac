import CleanMacCore
import Foundation

/// Finds groups of identical files and reports them while it runs.
public protocol DuplicateScanning: Sendable {
    /// The scope that covers only the folder at `url`, or `nil` when it can't be scanned on
    /// its own: it is not a folder, or the scan of the home folder leaves it out. The home
    /// folder itself gives `.home`.
    func scope(limitedTo url: URL) -> ScanScope?

    /// Starts scanning `scope` for identical files of `minimumSize` bytes or more. Ending the
    /// iteration of the stream cancels the scan.
    func scan(_ scope: ScanScope, minimumSize: Int64) -> AsyncStream<DuplicateScanEvent>
}
