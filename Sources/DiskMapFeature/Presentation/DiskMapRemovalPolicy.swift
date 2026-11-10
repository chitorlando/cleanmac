import Foundation

/// Decides which items of the disk map can be moved to the Trash.
///
/// The map shows `~/Library` so the user sees where the space goes, but what's inside belongs
/// to apps and to macOS. Only the contents of its caches and logs, which apps rebuild, can go.
/// A few folders hold data whose loss can't be undone, such as keychains, mail or iCloud Drive,
/// and are blocked by name. Apps go through the Uninstaller, which also removes what they
/// leave behind, photo libraries are only shown, since one may be the system library that
/// iCloud Photos syncs, and the standard folders of the home are kept, though not their contents.
public struct DiskMapRemovalPolicy: Sendable {
    static let standardFolders: Set<String> = [
        "Applications", "Desktop", "Documents", "Downloads", "Library", "Movies", "Music", "Pictures", "Public"
    ]
    static let rebuildableLibraryFolders: Set<String> = ["Caches", "Logs"]
    static let protectedLibraryFolders: Set<String> = [
        "Keychains", "Mail", "Messages", "Mobile Documents", "CloudStorage", "Containers", "Group Containers"
    ]

    static let protectedPackageExtensions: Set<String> = ["photoslibrary"]

    private let homeComponents: [String]

    public init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        homeComponents = Self.components(of: home)
    }

    public func advice(for node: DiskNode) -> RemovalAdvice {
        advice(for: node.url, kind: node.kind)
    }

    public func advice(for url: URL, kind: DiskNodeKind) -> RemovalAdvice {
        let components = Self.components(of: url)
        guard components.starts(with: homeComponents) else {
            return packageAdvice(for: url, kind: kind)
        }
        let inHome = Array(components.dropFirst(homeComponents.count))
        guard let first = inHome.first else { return .standardFolder }
        if inHome.count == 1, Self.standardFolders.contains(first) {
            return .standardFolder
        }
        if first == "Library" {
            return libraryAdvice(for: Array(inHome.dropFirst()))
        }
        return packageAdvice(for: url, kind: kind)
    }

    /// `path` is relative to `~/Library` and never empty.
    private func libraryAdvice(for path: [String]) -> RemovalAdvice {
        if Self.protectedLibraryFolders.contains(path[0]) {
            return .protectedData
        }
        if Self.rebuildableLibraryFolders.contains(path[0]), path.count > 1 {
            return .allowed
        }
        return .appData
    }

    /// Apps go to the Uninstaller and photo libraries are kept; anything else can go.
    private func packageAdvice(for url: URL, kind: DiskNodeKind) -> RemovalAdvice {
        guard kind == .package else { return .allowed }
        let pathExtension = url.pathExtension.lowercased()
        if pathExtension == "app" {
            return .useUninstaller
        }
        return Self.protectedPackageExtensions.contains(pathExtension) ? .protectedData : .allowed
    }

    private static func components(of url: URL) -> [String] {
        url.standardizedFileURL.pathComponents.filter { $0 != "/" }
    }
}
