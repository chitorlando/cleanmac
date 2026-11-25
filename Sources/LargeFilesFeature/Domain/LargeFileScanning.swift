import CleanMacCore
import Foundation

/// Finds large files and reports them while it runs.
///
/// Every scan skips some folders with everything inside, such as `~/Library`, and each scan
/// can leave out more: the `excludedFolders` it's given, which the user chooses.
public protocol LargeFileScanning: Sendable {
    /// The scope of a scan limited to the folder at `url`, or `nil` when the scan can't look
    /// there: `url` is not a folder, or the scan of the home folder would never enter it, also
    /// because it's one of `excludedFolders` or inside one.
    func scope(limitedTo url: URL, excluding excludedFolders: [URL]) -> ScanScope?

    /// Looks for the files in `scope` that match `criteria`, leaving out `excludedFolders`.
    func scan(
        _ scope: ScanScope,
        excluding excludedFolders: [URL],
        criteria: LargeFileCriteria
    ) -> AsyncStream<LargeFileScanEvent>
}
