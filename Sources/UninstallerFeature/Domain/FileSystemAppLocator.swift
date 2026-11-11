import Foundation

/// Walks folders recursively and collects the ".app" bundles the user can remove.
///
/// Symbolic links (such as `/Applications/Safari.app`, which points into a system
/// cryptex) and items protected by System Integrity Protection are skipped.
/// URLs are returned standardized so they compare equal to those reported by `NSWorkspace`.
///
/// An app asked for by its path is also left out when it is in the Trash, where the user
/// already threw it away, or inside the bundle of another app, which needs it to work.
public struct FileSystemAppLocator: AppBundleLocating {
    private static let appExtension = "app"
    /// The Trash of the home folder and the one of every other volume.
    private static let trashFolderNames: Set<String> = [".Trash", ".Trashes"]

    public init() {}

    public func applications(in folders: [URL]) -> [URL] {
        var seenPaths: Set<String> = []
        var apps: [URL] = []
        for folder in folders where FileManager.default.fileExists(atPath: folder.path) {
            for app in applications(in: folder).map(\.standardizedFileURL)
            where seenPaths.insert(app.path).inserted {
                apps.append(app)
            }
        }
        return apps
    }

    public func application(at url: URL) -> URL? {
        let app = url.standardizedFileURL
        guard let status = FileStatus(url: url),
              !status.isSymbolicLink,
              !status.isSystemRestricted,
              isAppBundle(url),
              !isInTheTrashOrInsideAnotherApp(app)
        else { return nil }
        return app
    }

    private func isInTheTrashOrInsideAnotherApp(_ app: URL) -> Bool {
        app.pathComponents.dropLast().contains { folder in
            Self.trashFolderNames.contains(folder)
                || (folder as NSString).pathExtension.lowercased() == Self.appExtension
        }
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
