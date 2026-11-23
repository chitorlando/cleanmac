import Foundation

/// What a scan of the user's files covers: the whole home folder, or a single folder of it.
public enum ScanScope: Hashable, Sendable {
    /// The whole home folder.
    case home
    /// Only this folder, with everything inside it: one that the scan of the home folder
    /// enters. See `ScanScopePolicy`.
    case folder(URL)

    /// The folder the scan is limited to, or `nil` when it covers the whole home folder.
    public var folder: URL? {
        switch self {
        case .home: nil
        case .folder(let folder): folder
        }
    }
}
