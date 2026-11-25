import Foundation

/// What the user can choose about every scan that looks for files to remove in the home
/// folder, such as the scans of large files and of duplicates.
///
/// The disk map doesn't follow these settings: it shows how the disk is really used.
public enum ScanSettings {
    /// Folders the scans leave out with everything inside, besides `~/Library`, by path.
    ///
    /// Each path spells the folder from the home folder, the way `ScanScopePolicy` spells the
    /// folder of a scope, so the walker and the scope policy of a scan both recognize it.
    public static let excludedFolders = Setting<[String]>(key: "scans.excludedFolders", defaultValue: [])

    /// The folders at `paths`, such as the ones `excludedFolders` keeps.
    public static func folders(at paths: [String]) -> [URL] {
        paths.map { URL(filePath: $0, directoryHint: .isDirectory) }
    }
}
