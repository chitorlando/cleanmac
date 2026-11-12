import Foundation

/// What a duplicate scan covers.
public enum DuplicateScanScope: Hashable, Sendable {
    /// The whole home folder.
    case home
    /// Only one folder of the home folder, with everything inside it.
    case folder(URL)

    /// The folder the scan is limited to, or `nil` when it covers the whole home folder.
    public var folder: URL? {
        switch self {
        case .home: nil
        case .folder(let folder): folder
        }
    }
}
