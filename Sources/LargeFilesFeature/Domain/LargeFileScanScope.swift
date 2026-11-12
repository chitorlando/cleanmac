import Foundation

/// Where a scan looks for large files.
public enum LargeFileScanScope: Hashable, Sendable {
    /// The whole home folder.
    case home
    /// Only this folder, one that the scan of the home folder enters. See `ScanScopePolicy`.
    case folder(URL)

    /// The folder the scan is limited to, or `nil` when it covers the whole home folder.
    public var folder: URL? {
        switch self {
        case .home: nil
        case .folder(let url): url
        }
    }
}
