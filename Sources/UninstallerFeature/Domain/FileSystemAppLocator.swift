import Foundation

/// Walks folders recursively and collects the ".app" bundles the user can remove.
///
/// Symbolic links (such as `/Applications/Safari.app`, which points into a system
/// cryptex) and items protected by System Integrity Protection are skipped.
public struct FileSystemAppLocator: AppBundleLocating {
    private static let appExtension = "app"

    public init() {}

    public func applications(in folders: [URL]) -> [URL] {
        var seenPaths: Set<String> = []
        var apps: [URL] = []
        for folder in folders where FileManager.default.fileExists(atPath: folder.path) {
            for app in applications(in: folder) where seenPaths.insert(app.standardizedFileURL.path).inserted {
                apps.append(app)
            }
        }
        return apps
    }

    private func applications(in folder: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsPackageDescendants, .skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else { return [] }

        var apps: [URL] = []
        for case let url as URL in enumerator {
            guard let status = FileStatus(url: url), !status.isSymbolicLink else { continue }
            if status.isSystemRestricted {
                enumerator.skipDescendants()
                continue
            }
            if isAppBundle(url) {
                enumerator.skipDescendants()
                apps.append(url)
            }
        }
        return apps
    }

    private func isAppBundle(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == Self.appExtension
            && (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }
}
