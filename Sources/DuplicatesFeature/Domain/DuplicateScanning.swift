import CleanMacCore
import Foundation

/// Finds groups of identical files and reports them while it runs.
///
/// Every scan skips some folders with everything inside, such as `~/Library`, and each scan
/// can leave out more: the `excludedFolders` it's given, which the user chooses.
public protocol DuplicateScanning: Sendable {
    /// The scope that covers only the folder at `url`, or `nil` when it can't be scanned on
    /// its own: it is not a folder, or the scan of the home folder leaves it out, also because
    /// it's one of `excludedFolders` or inside one. The home folder itself gives `.home`.
    func scope(limitedTo url: URL, excluding excludedFolders: [URL]) -> ScanScope?

    /// Starts scanning `scope`, without `excludedFolders`, for identical files of
    /// `minimumSize` bytes or more. Ending the iteration of the stream cancels the scan.
    func scan(
        _ scope: ScanScope,
        excluding excludedFolders: [URL],
        minimumSize: Int64
    ) -> AsyncStream<DuplicateScanEvent>
}
